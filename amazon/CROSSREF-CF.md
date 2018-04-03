Collection of cloudformation templates

# Cross Stack references

Imagine a corporate AWS account where there is a dedicated person who creates all network related resources: 
 - VPC
 - Subnets
 - Security Groups
 - Gateways

Developers can create EC2 Instance in the already existing network.

## Create Network Stack

```
aws cloudformation create-stack \
  --template-body file://private-subnet.json \
  --parameters \
      ParameterKey=Owner,ParameterValue=$USER \
      ParameterKey=KeyName,ParameterValue=seq-master \
      ParameterKey=AvailabilityZone,ParameterValue=eu-central-1a \
  --tags Key=Owner,Value=${USER} \
  --stack-name cbd-subnet-test

natip=$(aws cloudformation describe-stack-resource --stack-name cbd-subnet-test --logical-resource-id MyEIP --query StackResourceDetail.PhysicalResourceId --out text)
```

## Create CBD in private subnet

```
aws cloudformation create-stack \
  --template-body file://cloudbreak-deployement-subnet.json \
  --parameters \
      ParameterKey=KeyName,ParameterValue=seq-master \
  --tags Key=Owner,Value=${USER} \
  --capabilities CAPABILITY_IAM \
  --stack-name cbd-xstack-ref
```

## Delete all resources

```
aws cloudformation delete-stack --stack-name cbd-subnet-test
aws cloudformation delete-stack --stack-name cbd-xstack-ref
```

## Create lambda stack

To be able to test the lambda functio in isolation, there is a simple cf template with a single lambda resource,
and the supporting IAM role.

```
aws cloudformation create-stack --template-body file://lambda.json --capabilities CAPABILITY_IAM --stack-name lambda-test
```

## Check Stack status
```
aws cloudformation list-stack-resources --query "StackResourceSummaries[].[ResourceType,ResourceStatus]" --out text --stack-name lambda-test
```

## Invoke Functions

```
fnName=$(aws lambda list-functions --query 'Functions[?starts_with(FunctionName,`lambda-test-LookupStackOutputs`)].FunctionName' --out text)
aws lambda invoke --function-name $fnName --payload file://payload.json  lamba-resp.json

```


## Check failed events
```
aws cloudformation describe-stack-events --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]' --stack-name lambda-test
```
