var AWS = require('aws-sdk');
AWS.config.region = 'eu-west-1';


var iam = new AWS.IAM();
 /*
var params = {
};
iam.listUsers(params, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else     console.log(data);           // successful response
});
*/

var cloudformation = new AWS.CloudFormation();

var params = {
    /*
  NextToken: 'STRING_VALUE',

    'CREATE_IN_PROGRESS | CREATE_FAILED | CREATE_COMPLETE | ROLLBACK_IN_PROGRESS | ROLLBACK_FAILED | ROLLBACK_COMPLETE | DELETE_IN_PROGRESS | DELETE_FAILED | DELETE_COMPLETE | UPDATE_IN_PROGRESS | UPDATE_COMPLETE_CLEANUP_IN_PROGRESS | UPDATE_COMPLETE | UPDATE_ROLLBACK_IN_PROGRESS | UPDATE_ROLLBACK_FAILED | UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS | UPDATE_ROLLBACK_COMPLETE',
  */
  StackStatusFilter: [
    'CREATE_COMPLETE',
  ]
};

/*
cloudformation.listStacks(params, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else     console.log(data);           // successful response
});
*/

stackName = 'cbd-subnet-test'
stackName='arn:aws:cloudformation:eu-west-1:755047402263:stack/cbd-subnet-test/a9cc16b0-10f7-11e6-a87a-50fae9b818d2'

var responseData = {};

var params = {
  StackName: stackName
};
cloudformation.describeStackResources(params, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else {
    //console.log(data);           // successful response
    data.StackResources.forEach(function(res) {
        console.log("res: %j %j", res.LogicalResourceId, res.PhysicalResourceId)
        responseData[res.LogicalResourceId] = res.PhysicalResourceId
    })
    console.log("resp: %j", responseData)
  }
})




cloudformation.describeStacks({StackName: stackName}, function(err, data) {
    if (err) {
        responseData = {Error: 'DescribeStacks call failed'};
        console.log(responseData.Error + ':\\n', err);
    }
    else {
        //console.log("data: %j", data)
        //console.log("data.Stacks[0]: %j",data.Stacks[0])
        stackId = data.Stacks[0].StackId


        /*
        data.Stacks[0].Outputs.forEach(function(output) {
            responseData[output.OutputKey] = output.OutputValue;
        });
        */
    }
})

