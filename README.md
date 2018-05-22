This project is dedicated to provide template based solutions for creating Cloudbreak deployments on different cloud providers:
# Supported providers

## [AWS](aws/README.md)

## [Azure](azure/README.md)

## [GCP](gcp/README.md)

# Template generation

## Prerequisites
  - Git
  - Curl
  - Tar
  - Docker
  - The node package manager (NPM)
  - [Google cloud SDK](https://cloud.google.com/sdk/downloads)

## Commands

### Install dependencies
Run the following command to download the required dependencies.
> This command is not mandatory, because the command that are require dependencies will run this make target before start to run.

```
make deps
```

### Generate templates
Run the following command to generate templates for all available cloud providers. The `VERSION` env variable needs to be exported or specified to run this command.
> The generation can be run only for one provider: `make generate-azure`, `make generate-aws` and `make generate-gcp`
> According to the AWS documentation the Cloudformation Stack template URL must point to a template with a maximum size of 460,800 bytes that is stored in an S3 bucket that you have read permissions to... So the AWS template generation mechanism tries to upload the generated template to an existing S3 bucket and the `AWS_ACCESS_KEY_ID` and the `AWS_SECRET_ACCESS_KEY` env variables must be specified. The `UPLOAD_BUCKET` which value is `cbd-quickstart` by default could be overridden.

```
export VERSION=2.7.0-dev.127
export AWS_ACCESS_KEY_ID=XXXX.....
export AWS_SECRET_ACCESS_KEY=XZZZD.....

make generate-all
```
or
```
AWS_SECRET_ACCESS_KEY=XZZZD..... AWS_ACCESS_KEY_ID=XXXX..... VERSION=2.7.0-dev.127 make generate-all
```

### Commit and push the result of the template generation to github
The `VERSION` env variable is also mandatory for this command. It only creates a commit on the checkouted branch with all of the modified files, tags it with the configured value of `VERSION` and pushes local modifications to the remote branch.

```
export VERSION=2.7.0-dev.127
make push-updated-templates
```
or
```
VERSION=2.7.0-dev.127 make push-updated-templates
```
