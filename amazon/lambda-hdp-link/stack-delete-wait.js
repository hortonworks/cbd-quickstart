isCloudbreakTag = function(cloudbreakId) {
    return function(tag) {
        return tag.Key === 'CloudbreakId' && tag.Value === cloudbreakId;
    };
};

isHDPCluster = function(cloudbreakId) {
    return function(stack) {
        return stack.Tags.filter(isCloudbreakTag(cloudbreakId)).length > 0;
    };
};

wait = function() {
    return new Promise(function(resolve, reject) {
        setTimeout(function() {
            resolve();
        }, 3000);
    });
};

deleteStacks = function(stacks) {
    return new Promise(function(resolve, reject) {
        Promise.all(stacks.map(deleteStack)).then(function() {
            console.log("Called delete on all stacks.");
            resolve();
        }).catch(function(err) {
            console.log("Failed to call delete on one or more stacks.");
            reject(err);
        });
    });
};

deleteStack = function(stack) {
    return new Promise(function(resolve, reject) {
        var aws = require('aws-sdk');
        var cfn = new aws.CloudFormation();
        cfn.deleteStack({
            StackName: stack.StackName
        }, function(err, data) {
            if (err) {
                console.log("Delete failed for stack: [Id: " + stack.StackId + "], Error:");
                console.log(err);
                reject(err.code + ": " + err.message);
            } else {
                console.log("Delete called on stack: [Id: " + stack.StackId + "]");
                resolve();
            }
        });
    });
};

describeStacks = function(stacks) {
    return new Promise(function(resolve, reject) {
        wait().then(function() {
            Promise.all(stacks.map(describeStack)).then(function() {
                console.log("All stacks were deleted.");
                resolve();
            }).catch(function(err) {
                console.log("Delete is not yet completed for one or more stacks.");
                reject(err);
            });
        });
    });
};

describeStack = function(stack) {
    return new Promise(function(resolve, reject) {
        var aws = require('aws-sdk');
        var cfn = new aws.CloudFormation();
        cfn.describeStacks({
            StackName: stack.StackId
        }, function(err, data) {
            if (err) {
                console.log("Describe failed for stack: [Id: " + stack.StackId + "], Error:");
                console.log(err);
                reject(err.code + ": " + err.message);
            } else {
                console.log("Described stack: [Id: " + data.Stacks[0].StackId +", Status: " + data.Stacks[0].StackStatus + "]");
                if (data.Stacks[0].StackStatus === 'DELETE_COMPLETE') {
                    resolve();
                } else if (data.Stacks[0].StackStatus === 'DELETE_IN_PROGRESS') {
                    reject();
                }
                reject("Stack was not deleted: [Id: " + data.Stacks[0].StackId +", Status: " + data.Stacks[0].StackStatus + "]");
            }
        });
    });
};

pollUntilDeleted = function(stacks) {
    return describeStacks(stacks).then(function() {
        return "deleted";
    }).catch(function(err) {
        if (err) {
            console.log(err);
            return err;
        } else {
            return pollUntilDeleted(stacks);
        }
    });
};

exports.handler = function(event, context) {
    console.log('REQUEST RECEIVED:\\n', JSON.stringify(event));
    var cloudbreakId = event.ResourceProperties.CloudbreakID;
    var response = require('cfn-response');
    var responseData = {};
    if (cloudbreakId) {
        if (event.RequestType == 'Delete') {
            var aws = require('aws-sdk');
            var cfn = new aws.CloudFormation();
            cfn.describeStacks({}, function(err, data) {
                if (err) {
                    responseData = {
                        Error: 'DescribeStacks call failed'
                    };
                    console.log(responseData.Error + ':\\n', err);
                    response.send(event, context, response.FAILED, responseData);
                } else {
                    var stacks = data.Stacks.filter(isHDPCluster(cloudbreakId));
                    console.log("Found " + stacks.length + " stacks.");
                    deleteStacks(stacks)
                        .then(function() {
                            return pollUntilDeleted(stacks);
                        })
                        .then(function(result) {
                            console.log("result:", result);
                            if (result === "deleted") {
                                response.send(event, context, response.SUCCESS, responseData);
                            } else {
                                responseData = {
                                    Error: result
                                };
                                response.send(event, context, response.FAILED, responseData);
                            }
                        })
                        .catch(function(err) {
                            console.log(err);
                            responseData = {
                                Error: 'Failed to delete linked HDP stack: ' + err
                            };
                            response.send(event, context, response.FAILED, responseData);  
                        });
                }
            });
            return;
        }
        if (event.RequestType == 'Create') {
            response.send(event, context, response.SUCCESS, responseData);
        }
    } else {
        responseData = {
            Error: 'Cluster name not specified'
        };
        console.log(responseData.Error);
        response.send(event, context, response.FAILED, responseData);
    }
};