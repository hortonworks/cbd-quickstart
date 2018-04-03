## Testing a new blueprint with HDC using Cloudbreak-Shell

1. Create an HDC deployment with any of the templates
2. SSH to cloud controller instance: `ssh cloudbreak@<public-ip>`
3. Enter the Cloudbreak deployment directory: `cd /var/lib/cloudbreak-deployment/`
4. Start Cloudbreak-Shell: `cbd util cloudbreak-shell`
5. Run the following commands to add a new blueprint from a URL and to create a Cloudbreak cluster using the new blueprint (comments inline):

```bash
# add the new/modified blueprint from a URL - the blueprint must be in the same format as on the sample URL
blueprint create --name druid-mod --url https://gist.githubusercontent.com/martonsereg/6a7b144db6d9f352989e875cb8225296/raw/98dddc33737e2204e95cdfbda1ca104dbf7e996c/druid-modified.bp

# select the default AWS credential that was created automatically during the cloud-controller provisioning
credential select --name aws-access

# select the newly added blueprint by name
blueprint select --name druid-mod

# create a "template" that configures the instance type and attached volumes - create multiple templates if you need different configuration for different hostgroups
template create --AWS --name temp-test --instanceType m3.xlarge --volumeType gp2 --volumeSize 50 --volumeCount 1

# configure master, worker and compute hostgroups and attach previously created templates (ambariServer must be set to true and nodecount must be 1 for master)
# security group name can be 'default-aws-all-services-port' if you want to have open ports for HDP services
instancegroup configure --instanceGroup master --ambariServer true --nodecount 1 --templateName temp-test --securityGroupName default-aws-only-ssh-and-ssl
instancegroup configure --instanceGroup worker  --ambariServer false --nodecount 2 --templateName temp-test --securityGroupName default-aws-only-ssh-and-ssl
instancegroup configure --instanceGroup compute   --ambariServer false --nodecount 2 --templateName temp-test --securityGroupName default-aws-only-ssh-and-ssl

# select the default network setup that was created automatically during the cloud-controller provisioning 
network select --name  aws-network

# create the cluster infrastructure (use ambariVersion 2.4 and hdpVersion 2.5 for an HDP 2.5 cluster)
stack create --AWS --name test1 --region eu-central-1 --ambariVersion 2.5 --hdpVersion 2.6

# configure the Ambari cluster's username and password
cluster create --userName admin --password admin
```

- If all the above commands were successful, the cluster will be visible on the UI and cluster provisioning should start.
- If the cluster install is successful it can also be upscaled/downscaled/terminated from the UI.


### Notes:
- If the blueprint's format is invalid the `blueprint create` command won't be successul
- If there is a topology error or some misconfiguration in the blueprint it will only be visible during HDP cluster install when Ambari is already available
- Cloudbreak Shell offers autocompletion for a lot of commands (e.g.: to help with the switches of a command hit `--` and `tab`)
- It also have a special command, `hint` that can be used to help with the next command