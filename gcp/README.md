This repo helps to automate the deployment of Cloudbreak Deployer.
We use [Google deployment manager](https://cloud.google.com/deployment-manager/docs/configuration/templates/create-basic-template) to create a vm with the necessary resources that starts a Cloudbreak deployment by the startup script.
The only dependency that needs to be installed on your machine is the [Google cloud SDK](https://cloud.google.com/sdk/downloads). The SDK contains the [gcloud CLI tool](https://cloud.google.com/sdk/gcloud/) which is the main pillar of our deployer examples.
The virtual machines always started from the latest Centos 7 image that is available under the centos-cloud image repository.

## Deploy 2.7.0-dev.170 via gcloud command line interface by using template config
#### Please review and customize the following fields of vm_template_config.yaml file first

```yaml
    region: us-central1
    zone: us-central1-a
    instance_type: n1-standard-4
    ssh_pub_key: ....
    os_user: cloudbreak
    user_email: admin@example.com
    user_password: cloudbreak
```

#### Run the following command to create a new deployment

```
gcloud deployment-manager deployments create cbd-deployment --config=vm_template_config.yaml
```

## Delete the previously created deployment via gcloud command line interface

```
gcloud deployment-manager deployments delete cbd-deployment -q
```

## Deploy 2.7.0-dev.170 via gcloud command line interface by using template config
With the `gcloud` command-line tool, you can pass in the template file directly and provide the values for your template properties explicitly on the command-line. But in this case you should specify all of the properties that is required by our [template schema.](vm-template.jinja.schema) We have generated a default one, but please review and customize the previously mentioned key-value pairs, especially the `ssh_pub_key` one:

```
gcloud deployment-manager deployments create cbd-deployment \
    --template=vm-template.jinja \
    --properties region:us-central1,zone:us-central1-a,instance_type:n1-standard-4,os_user:cloudbreak,user_email:admin@example.com,user_password:'cloudbreak',cbd_version:2.7.0-dev.170,startup-script:'https://raw.githubusercontent.com/hortonworks/cbd-quickstart/2.7.0-dev.170/install-and-start-cbd.sh',ssh_pub_key:'....'
```
