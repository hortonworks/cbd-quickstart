This repo contains Cloudbreak related AWS Cloudformation templates.
# Release candidates 1.16.0 (GA)

## Basic template (latest GA staging release candidate - 1.16.0)

<a href="https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/new?templateURL=https://s3.amazonaws.com/hdc-cfn/hdcloud-basic-GA-staging-1.16.0.template"> ![deploy cloudbreak](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png) </a>

## Advanced template with configurable VPC and RDS (latest GA staging release candidate - 1.16.0)

<a href="https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/new?templateURL=https://s3.amazonaws.com/hdc-cfn/hdcloud-advanced-GA-staging-1.16.0.template"> ![deploy cloudbreak](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png) </a>

## Basic template (latest GA final release candidate - 1.16.0)

<a href="https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/new?templateURL=https://s3.amazonaws.com/hdc-cfn/hdcloud-basic-GA-final-1.16.0.template"> ![deploy cloudbreak](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png) </a>



## Creating and uploading versioned templates

This project has a very simple versioning scheme, the version number directly refers to the cloudbreak-deployer (cbd) version.
For example if the CFN template has the version number 1.3.0-rc.2 then the generated template will provision the cbd version 1.3.0-rc.2.

To generate the templates:
```
make build
```

The 'build' target will check if there is a git tag on the current HEAD commit.
If yes the template will have that git tag as version and the template will be genereted in the build directory.
For example if the last commit is tagged with 1.3.0-rc.2, then 'build' will generate the templates 'build/cbd-quick-1.3.0-rc.2.template' and 'build/cbd-advanced-1.3.0-rc.2.template' and the corresponding user-data scripts and lambda functions.
If there is no tag on the HEAD commit, the version will be 'snapshot' on master and '<branch-name>-snapshot' on other branches.

To upload the generated templates to S3:
```
make upload
```

## Create Stack from CLI

To create "advanced" stack that deploys Cloudbreak:

```
key_name=<your_key_name>
stack_name=<your_stack_name>
email=yourname@yourcomp.com
AWS_DEFAULT_REGION=us-east-1

aws cloudformation create-stack \
 --capabilities CAPABILITY_IAM \
 --parameters \
 	ParameterKey=KeyName,ParameterValue="${key_name}" \
 	ParameterKey=AdminPassword,ParameterValue=BadPass#1 \
 	ParameterKey=RemoteLocation,ParameterValue=$(curl -s v4.icanhazip.com)/32 \
    ParameterKey=EmailAddress,ParameterValue="${email}" \
 --stack-name "${stack_name}" \
 --tags \
 	Key=Owner,Value=${USER} \
 	Key=Name,Value="${stack_name}" \
 --disable-rollback \
 --template-body file://build/cbd-advanced-snapshot.template
```

To create quick start which includes the HDP cluster:

```
key_name=<your_key_name>
stack_name=<your_stack_name>
remote_location="$(curl -s v4.icanhazip.com)/32"  ## this will fetch your current IP,
                  ## replace with a different range if needed

AWS_DEFAULT_REGION=us-east-1


aws cloudformation create-stack \
  --capabilities CAPABILITY_IAM \
  --parameters ParameterKey=KeyName,ParameterValue=${key_name} \
    ParameterKey=AdminPassword,ParameterValue=BadPass#1 \
    ParameterKey=RemoteLocation,ParameterValue="${remote_location}" \
    ParameterKey=StackVersion,ParameterValue='HDP 2.4 + Hadoop 2.7.2' \
    ParameterKey=WorkloadType,ParameterValue=EDW \
    ParameterKey=ClusterSize,ParameterValue=2 \
    ParameterKey=InstanceType,ParameterValue=m3.xlarge \
  --stack-name "${stack_name}" \
  --tags \
 	Key=Owner,Value=${USER} \
 	Key=Name,Value="${stack_name}" \
  --disable-rollback \
  --template-body file://build/cbd-quick-snapshot.template
```

To get the status, outputs and other details:

```
aws cloudformation describe-stacks --stack-name "${stack_name}"
```


## Changing base AMI

The EC2 instance running cloudbreak has a different AMI for each region. In Cloudformation we have defined `AWSRegionAMI` map.
If we release a new Cloudbreak (new cbd version), this map has to be updated with new ids: ami-xxxxxx.

There are 2 helper make commands to make it easier:

List atlas version numbers with image names:
```
$ make list-cbd-img-versions

18 cloudbreak-deployer-122-2016-05-04
17 cloudbreak-deployer-122-2016-05-04
16 cloudbreak-deployer-121-2016-05-03
...
```

Generate `AWSRegionAMI` json sniplet for a specific version:
```
$ CBD_IMG_VERSION=17 make generate-ami-mappings
```


## AWS permissions

To be able to use these templates, the user must have these AWS permissions:

### Advanced template

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeStackResource",
                "cloudformation:DescribeStacks",
                "cloudformation:GetTemplate",
                "cloudformation:GetTemplateSummary",
                "cloudformation:ListStacks",
                "cloudformation:ListStackResources",
                "iam:AddRoleToInstanceProfile",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:DeleteRole",
                "iam:DeletePolicy",
                "iam:GetInstanceProfile",
                "iam:GetRole",
                "iam:PassRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "ec2:AttachInternetGateway",
                "ec2:AssociateRouteTable",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateRoute",
                "ec2:CreateInstance",
                "ec2:CreateRouteTable",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSubnet",
                "ec2:CreateVpc",
                "ec2:CreateInternetGateway",
                "ec2:CreateTags",
                "ec2:DeleteSubnet",
                "ec2:DeleteVpc",
                "ec2:DeleteInternetGateway",
                "ec2:DetachInternetGateway",
                "ec2:DeleteRoute",
                "ec2:DeleteRouteTable",
                "ec2:DeleteSecurityGroup",
                "ec2:TerminateInstances",
                "ec2:DisassociateRouteTable",
                "ec2:ModifySubnetAttribute",
                "ec2:ModifyVpcAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstances",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcAttribute",
                "ec2:DescribeVpcs",
                "ec2:RunInstances",
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:GetFunctionConfiguration",
                "lambda:InvokeFunction",
            ],
            "Resource": "*"
        }
    ]
}
```

