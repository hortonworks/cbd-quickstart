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
  - The node package manager (NPM)
  - [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
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
> The AWS based template generation requires a fully configured AWS cli which has permission to upload the generated template into the bucket with name `UPLOAD_BUCKET` (The default value is `cbd-quickstart` by default).

```
export VERSION=2.7.0-dev.127
make generate-all
```
or
```
VERSION=2.7.0-dev.127 make generate-all
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
