This repo contains Cloudbreak related AWS Cloudformation templates.

## Cloudbreak template for version: 2.7.0-dev.166

<a href="https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/new?templateURL=https://s3.amazonaws.com/cbd-quickstart/cbd-quickstart-2.7.0-dev.166.template"> ![deploy cloudbreak](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png) </a>


## Creating and uploading versioned templates

This project has a very simple versioning scheme, the version number directly refers to the cloudbreak-deployer (cbd) version.
For example if the CFN template has the version number `2.7.0-rc.2` then the generated template will provision the cbd version `2.7.0-rc.2`. Only the `VERSION` env variable needs to be specified to be able to run the available commands.

To generate the templates:
```
make build
```

The upload command will regenerate the template and also upload it to an S3 bucket. The `AWS_ACCESS_KEY_ID` and the `AWS_SECRET_ACCESS_KEY` environment variables must be specified. The `UPLOAD_BUCKET` which value is `cbd-quickstart` by default could be overridden.

To upload the generated templates to S3:
```
make upload
```

## Create Stack from CLI

To create a stack that deploys Cloudbreak:

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

The EC2 instance running Cloudbreak has a different AMI for each region. In Cloudformation we have defined `AWSRegionAMI` map.
Our scripts are built on the top of the first generation of the Amazon linuxes, if you would like to update base AMIs to use the latest Amazon linuxes, you only need to run the following command. The command will update the `aws-mapping.yml` file and the next template generation will use the desired AMI mappings.


```
make generate-latest-ami-mappings
```

