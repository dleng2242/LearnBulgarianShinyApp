# Deploying the Containerized App to Azure Cloud

This file contains instructions on how to deploy the application image to the 
Azure Cloud so the app may be accessed via the web from any device. 


1. Open your favourite terminal and make sure the 
[**Azure CLI is installed**](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Run the following commands in your terminal in turn.

Login to Azure.A window will open in your default browser to authenticate 
your connection.
> `az login`

Create a resource group.
> `az group create --name {resource-group-name} -l {desired-server-location}`

e.g. 
> `az group create -n learnBG -l uksouth`

Create an Azure Container Registry within the resource group, this is analogous 
to DockerHub and serves as a location to store images.
> `az acr create -n {container-registry-name} -g {resource-group-name} --sku {desired-price-plan}`

e.g. 
> `az acr create -n learnbgregistry -g learnBG --sku Basic`

Authenticate to Azure Container Registry.
> `az acr login -n {container-registry-name}`

e.g.
> `az acr login -n learnbgregistry`

Create a local alias of the application image with the fully qualified path to 
your Azure Container Registry. This tells docker to use the azure container 
registry as the remote repository instead of DockerHub on push.
> `docker tag {local-image:version} {container-registry-name}.azurecr.io/{local-image:version}`

e.g. 
> `docker tag learnbulgarianshinyapp:0.1 learnbgregistry.azurecr.io/learnbulgarianshinyapp:0.1`


Push local alias to Azure Container Registry. 
You should now be able to see the image in the Azure Container 
Registry through the portal or via the CLI.
> `docker push {container-registry-name}.azurecr.io/{local-image:version}`

e.g. (this took ~5 mins for me)
> `docker push learnbgregistry.azurecr.io/learnbulgarianshinyapp:0.1`

Create an App Service Plan within the resource group, this specifies the 
resources required to run your app and determines the price plan. If you deploy
multiple apps, they can use the same price plan if desired.
> `az appservice plan create -g {resource-group-name} -n {appservice-plan-name} --sku {desired-price-plan} --is-linux`

e.g.
> `az appservice plan create -g learnBG -n learnbgappservice --sku B1 --is-linux`

Create a Webapp Service within the resource group, this specifies the assets 
which will form the app. The -i argument specifies the image. Read more [here](https://learn.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest#az-webapp-create). 
> `az webapp create -g {resource-group-name} -p {appservice-plan-name} -n {webapp-name} -i {container-registry-name}.azurecr.io/{local-image:version}`

e.g.
> `az webapp create -g learnBG -p learnbgappservice -n LearnBulgarianShinyApp -i learnbgregistry.azurecr.io/learnbulgarianshinyapp:0.1`


3. Navigate to the Webapp Service through the Azure portal, and find your app.
Open your app via the `Browse` button. 


### Possible Issues

As Shiny apps typically consume several gigabytes of memory, this deployment 
method is prone to cold start delays which cause the web address to timeout 
at first. Allow at least 30 minutes for the systems to initialize after 
deployment.

During deployment it is helpful to see the logs. To do this first navigate to 
your App Service. Then open App Service logs and enable application logging,
then go to Log stream to view live console output of the app. 
More info [here](https://learn.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs).

I had an issue with the App Service not able to authenticate with my container
registry  `DockerApiException: ...  unauthorized: authentication required`. 
I had to enable admin access in the container registry (Access keys > Admin 
user), and then check the `DOCKER_REGISTRY_SERVER_USERNAME`, 
`DOCKER_REGISTRY_SERVER_PASSWORD` and `DOCKER_REGISTRY_SERVER_URL` in the App 
service configuration matches that in the container registry Access keys. 
I then enabled a system assigned identity in my app (Identity > System assigned).
I then restarted the app and then it all worked! More info [here](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-troubleshoot-login). 

Another DS had an issue where their subscription was not registered to use namespace “Microsoft.Web”. This needed an admin to manually register subscription with a resource provider. More info [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider?tabs=azure-cli). 

