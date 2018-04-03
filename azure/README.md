This repo helps to automate the deployment of Cloudbreak Deployer. On other cloud providers you can create “public images”, while on Azure
its a different process. You have to create a publicly available virtual disk image (vhdi), which has to be downloaded and imported
into a storage account. Our experience shows that it takes about 30-60 minutes until you can log into the VM.

For Azure we have an alternative approach:
- start from official CentOS, so no image copy is needed
- use [Docker VM Extension](https://github.com/Azure/azure-docker-extension) to install Docker
- use [CustomScript Extension](https://github.com/Azure/azure-linux-extensions/tree/master/CustomScript) to install Cloudbreak Deployer (cbd)

## Deploy master via Azure web UI

Click here: <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhortonworks%2Fazure-cbd-quickstart%2Fmaster%2FmainTemplate.json">  ![deploy on azure](http://azuredeploy.net/deploybutton.png) </a>

## Deploy 2.5.0 via Azure web UI

Click here: <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhortonworks%2Fazure-cbd-quickstart%2F2.5.0%2FmainTemplate.json">  ![deploy on azure](http://azuredeploy.net/deploybutton.png) </a>
