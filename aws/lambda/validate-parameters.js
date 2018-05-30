send = function(event, context, status, reason) {
    var body = JSON.stringify({
        Status: status,
        Reason: reason + " CloudWatch Log: " + context.logStreamName,
        PhysicalResourceId: context.logStreamName,
        StackId: event.StackId,
        RequestId: event.RequestId,
        LogicalResourceId: event.LogicalResourceId
    });
 
    var https = require("https");
    var url = require("url");
    var parsedUrl = url.parse(event.ResponseURL);
    var httpParams = {
        hostname: parsedUrl.hostname,
        port: 443,
        path: parsedUrl.path,
        method: "PUT",
        headers: {
            "content-type": "",
            "content-length": body.length
        }
    };
 
    var request = https.request(httpParams, function(response) {
        console.log("Response status code: " + response.statusCode);
        console.log("Response status message: " + response.statusMessage);
        context.done();
    });
 
    request.on("error", function(error) {
        context.done();
    });
 
    request.write(body);
    request.end();
};

describeSubnet = function(ec2, vpcId, subnetId) {
    return new Promise(function(resolve, reject) {
        ec2.describeSubnets({Filters:[{Name:'subnet-id', Values:[subnetId]}]}, function(err, data) {
            if (err) {
                reject("describeSubnets call failed: " + err);
            } else {
                if (data.Subnets.length > 0) {
                    if (data.Subnets[0].VpcId == vpcId) {
                        console.log("Subnet is within the VPC");
                        resolve();
                    } else {
                        reject("The selected subnet belongs to a different VPC.");
                    }
                } else {
                    reject("There is no subnet with id: " + subnetId);
                }
            }
        });
    });
};

describeVPCAttribute = function(ec2, vpcId) {
    return new Promise(function(resolve, reject) {
        ec2.describeVpcAttribute({Attribute:"enableDnsSupport", VpcId: vpcId}, function(err, data) {
            if (err) {
                reject("describeVpcAttribute call failed: " + err);
            } else if (data.EnableDnsSupport.Value) {
                console.log("DNS resolution is enabled in the VPC");
                resolve();
            } else {
                reject("DNS resolution must be enabled in the VPC");
            }
        });
    });
};

exports.handler = function(event, context, callback) {
    console.log('REQUEST RECEIVED:\\n', JSON.stringify(event));
    if (event.RequestType == 'Create') {
        if (event.ResourceProperties.VPC == null || event.ResourceProperties.SUBNET == null){
            send(event, context, "SUCCESS");
            return;
        }
        var vpcId = event.ResourceProperties.VPC;
        var subnetId = event.ResourceProperties.SUBNET;
        if (!vpcId && !subnetId) {
            send(event, context, "FAILED", "Both VPC and Subnet ID must be specified!");
            return;
        }
        var aws = require('aws-sdk');
        var ec2 = new aws.EC2();
        describeSubnet(ec2, vpcId, subnetId)
            .then(function() {
                return describeVPCAttribute(ec2, vpcId)
            })
            .then(function() {
                send(event, context, "SUCCESS");
                callback(null, "VPC and subnet has been validated.");
            })
            .catch(function(err) {
                send(event, context, "FAILED", err);
                callback(err);
            });
            return;
    } else {
        send(event, context, "SUCCESS");
        return;
    }
};