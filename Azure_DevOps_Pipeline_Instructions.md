
# Azure DevOps Shiny CI/CD Pipeline


This page documents our learnings while setting up CI/CD Pipelines
in Azure DevOps for an R Shiny application.

The actual testing part was very minimal, with the focus on getting an end to 
end pipeline working to deploy the app with different outcomes dependent on
the test result. 

## Pre-Requisites

This assumes you already have a Golem based shiny app that is ready to deploy,
with two docker files. See the section on "From golem to deploy" for details.
You could probably adapt it to work within non-Golem apps too. 

You will need an Azure subscription that you can create the various resources
in and an Azure DevOps account where you can set up the CI/CD pipeline in the 
relevant project.

The first step is to create the required Azure resources once to start with, 
and then set up the pipeline to automatically update the app using the 
`azure-pipeline.yml` file. 

Permissions will likely be an issue at some point. To create the service 
connections needed for the pipeline you need to have Owner 
permissions over your subscription, or someone else can create one for you
and provide you the details. 


## Setting up the Resources First


You will need a Resource Group, an Azure Container Registry, an App Service 
Plan, and a Web App. These need to exist before you set up the pipeline.

I could imagine in future you could also include this in a pipeline, but for
now this is out of scope. 

### Create the Resources 

You can create the required resources using the 
[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).

First log in. This will bring up your browser to log in.

`az login`

Then create your resource group if you don't already have one. Use "uksouth" 
for the location if unsure.

`az group create --name {resource-group-name} -l {desired-server-location}`

Next create the container registry, using the resource group you just created.
For a demo, use `--sku Basic` for a cost efficient registry. This is still
the most expensive resource. 

`az acr create -n {container-registry-name} -g {resource-group-name} --sku {desired-price-plan}`

Authenticate to the registry you created. 

`az acr login -n {container-registry-name}`

### Push the app Docker Images

The next step is to build and push your built app's Docker Image. See below
how to build the image and test it locally. Once you are happy, you need 
to re-tag it to point to our container registry and not DockerHub on push. 
Don't forget to update the app Dockerfile to pull from our Azure Container
Registry and not locally. 

Make sure you have docker running and can access this from the command line.
Try running `docker version` to check. 

`docker tag {local-image:version} {container-registry-name}.azurecr.io/{local-image:version}`

Then push the container. Go check the registry via the Azure Portal to check
it is there. 

`docker push {container-registry-name}.azurecr.io/{local-image:version}`

### Create the Web App

Create an App Service Plan within the resource group, this specifies the 
resources required to run your app and determines the price plan. If you deploy 
multiple apps, they can use the same price plan if desired. 
If unsure, use the basic plan `--sku B1`.

`az appservice plan create -g {resource-group-name} -n {appservice-plan-name} --sku {desired-price-plan} --is-linux`

Then create the actual Webapp Service within the resource group. This specifies 
the assets which will form the app. The `-i` argument specifies the image. 
Read more [here](https://learn.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest#az-webapp-create).

`az webapp create -g {resource-group-name} -p {appservice-plan-name} -n {webapp-name} -i {container-registry-name}.azurecr.io/{local-image:version}`

Navigate to the Webapp Service through the Azure portal, and find your app. 
Open your app via the "Browse" button.
Note, it might take up to 30 mins to start up as the system initializes. 



You can also create these from the Azure Portal. 


## Creating the pipeline in Azure Devops

The pipeline is defined in the `azure-pipelines.yml` file. Azure DevOps uses
this file to create and run pre-defined jobs based on the configuration 
specified. 

You will need to create two service connections to allow the pipeline to
authenticate against your Azure Container Register and your Web App service. 
Then you need to take our existing yaml file and edit the variables at the 
top to match your app and service connection details. 
Azure DevOps should then have what it needs to build your pipeline. 

### Creating Service Connections

You will need to create two service connections: one for your container 
registry, and the other for the Web App.

If you were starting from scratch you could use the Azure DevOps pipeline
interface to help you select tasks to build the yaml file. If you do this
these will likely be created for you. You would have done something like
this: 

* pipelines > New pipeline > Azure Repos Git > <your repo> > Docker build and push
* Select your subscription, container registry, image name, and docker file
* This configures the pipeline and generates a yaml file with the docker task

If you do not have owner privileges on your subscription you will need to get 
someone who does to create one and share their details with you to set it up 
more manually. 

To create your own service connections do the following. You will need to
do this twice, once to create the 

* Go into Project settings > pipelines > Service connections
* Add a New service connection (top right)
* Search and select "Azure Resource Manager"
    * Select "Service Principal (automatic)" authentication type
        * Note, choose "Service Principal (manual)" if using a shared subscription
    * Select "subscription" scope level
    * Select your subscription and resource group
    * Add a service connection name, e.g. "<appName>-service-connection"
    * Add a description if desired
    * Select "Grant access permission to all pipelines"
    * Click save
* Add a New service connection and search and select "Docker Registry"
    * Select "Azure Container Registry"
    * Select "Service Principal" authentication type
    * Select your subscription and container registry
    * Add a service connection name, e.g. "<appName>-registry-connection"
    * Add a description if desired
    * Select "Grant access permission to all pipelines"
    * Click save 
    * Note the service connection ID in the URL when you click on it


### Edit Variables 

* dockerRegistryServiceConnection - service connection ID (from the URL)
* imageRepositoryBase - name of your base image in container registry
* imageRepository - name of your app image in container registry
* containerRegistry - login server of container registry e.g. '<registry name>.azurecr.io
* dockerfilePathBase - path to base Dockerfile
* dockerfilePath - path to app dockerfile
* tag - unique autogenerated build tag '$(Build.BuildId)'
* azureSubscription - unhelpfully named, the service connection name
* appName - name of Azure Web App you create
* dirName - project root directory, used in the Docker file `COPY`

Note the `azureSubscription` is particularly unhelpfully named. 
There is a variable input to the "AzureWebAppContainer" task called 
"azureSubscription" but you actually provide the name of the Azure Resource 
Manager service connection e.g. "<appName>-service-connection".
I decided to stay consistent with their variable 
name which might not have been the right choice. 

### Triggering the Pipeline with a Pull Request

To trigger the pipeline when a pull request is created you need to set a branch
validation policy in your Azure DevOps project. You can find this in 
Project settings > Repositories > <your repo> > Policies > Branch Policies > 
<main branch> > Build Validation, and then add a build policy. 


### Understanding the pipeline yaml

The pipeline is defined in the `azure-pipelines.yml` file. Azure DevOps uses
this file to create and run pre-defined jobs based on the configuration 
specified. All you should need to do is take our existing yaml file and edit it
with your app details and Azure DevOps will build the pipeline, however
it is helpful to have a better understanding of it as it can be quite
overwhelming at first.

The first section in our yaml file defines when to run the stages. 
Here it is set to trigger on changes to the main branch. 
You can also set it to run on a schedule or on pull requests (although you
need to edit the branch policies to get this to work).

We then define variables that we then reference later in the script
for convenience. A better and more secure way to manage this would be to set
these as variables in a variable group within the Azure DevOps pipeline 
library.

The pipeline is broken down into stages which then is composed of jobs
which itself is composed of various steps.
Each stage has a stage name, a display name, an optional condition, 
and then a set of defined jobs. 
The jobs then have their own name and display name, optional condition,
the virtual machine image to run the job on, and then the different 
steps. Each step has a task which you select from the 
available Azure DevOps task, a display name, and then a command along 
with inputs.

In our first stage, we use a `Docker@2` task with the command "buildAndPush",
and inputs to define the docker file, image repository, container 
registry, and image tags. You are unlikely to write one of these yourself 
from scratch but you might need to edit different stages to match your project.

The `script` task is a convenient wrapper that allows you to run short scripts
as part of your pipeline. For example, it is used here to run our unit tests, 
update variables, and re-tag our docker images.


### Getting and Setting pipeline Variables

Pipelines can use conditions to control if steps or stages are run. 
Here I toggle a `testsPassed` variable to change to flow of the 
pipeline to do different things depending on if the tests passed or not. 

This issues is you cannot just set a variable in one step and reference in the 
next step, or stage. You have to explicitly specify
a variable is an output to be used elsewhere, and then reference the variable
using the step name. 

So in my pipeline, I use the following to set a variable in a script step.
Note I use the `isOutput=true` flag. I then give this step a name
"UpdatePassedFlagTask" so I can reference it later.

`echo '##vso[task.setvariable variable=testsPassed;isOutput=true]true'`

In a later step in the same job and stage I reference is as
`variables['UpdatePassedFlagTask.testsPassed']` in a condition, using
the step name prefix. 

In the next stage I reference this variable again, but use the following.
There are a few things to note here. First I need the specify both
the stage `BuildAndTest` and the job `BuildAndTestJob` as well as the 
step name `UpdatePassedFlagTask` and then the variable name 
`testsPassed`. I am also referencing `dependecies` as the build and
test stage is a dependency of this one. 

`dependencies.BuildAndTest.outputs['BuildAndTestJob.UpdatePassedFlagTask.testsPassed']`.


## From Golem to Deploy 

In a previous document we describe using Golem to create the docker files and 
build the package tarball in the deploy folder. Here we went with a slightly
different approach. We will no longer build the tarball and instead copy the 
app code directly. We have therefore edited our docker files accordingly.
We also moved our docker files to the project root and are using the 
`renv.lock` file we used during development, still at our project root.

The two image approach has many advantages, but it does take a little more set
up compared to just one image. We first build and push the base image to the
container registry, and then reference this base image in the second app image. 

See our docker files for reference. 

### Build and Test your Docker Images Locally

You will want to build these images and test them locally. 
To do this this do the following:

First check your dockerfile and make sure you have Docker installed
and running and can be accessed from your command line. 
Try running `docker version` to check. Navigate to your project directory. 

First build your base docker image, updating the tags as required.

`docker build -f Dockerfile_base --progress=plain -t {project_name}_base:0.1 .`

Then build your app image, making sure it references the correct image you
just build. You will need to edit this to point to the local one, not the 
one in the container registry. 
Alternatively you could push the base image to your Azure Container Registry
first and reference that. 

`docker build -f Dockerfile --progress=plain -t {project_name}:0.1 .`

Run the image in a container, specifying the port mapping defined in the 
Dockerfile. Here we map localhost port 80 to container port 80.

`docker run -d -p 80:80 --name {project_name} {project_name}:0.1`

Navigate to 127.0.0.1:80 or localhost:80 to ensure the container is functioning 
properly and the app appears as expected.

Once you have it all working, push it to your Azure Container Registry.




## Resources:

* [Azure Pipelines documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops)
* [AzureWebAppContainer@1 reference](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-web-app-container-v1?view=azure-pipelines)
* [Docker@2 reference](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/docker-v2?view=azure-pipelines&tabs=yaml)
* [Microsoft Learn Deploying Docker containers with Azure Pipelines](https://learn.microsoft.com/en-us/training/modules/deploy-docker/)
* [Engineering Playbook reference](https://microsoft.github.io/code-with-engineering-playbook/automated-testing/tech-specific-samples/azdo-container-dev-test-release/)
* [Deploy Containers to Azure Web Apps](https://learn.microsoft.com/en-us/azure/devops/pipelines/apps/cd/deploy-docker-webapp?view=azure-devops&tabs=java%2Cyaml)
* [Understand variable syntax](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#understand-variable-syntax)
* [Defining variables](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch)
* [Setting variables](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-variables-scripts?view=azure-devops&tabs=bash)
* [Stages, dependencies, and conditions](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml). 
* [Recommendations for tagging and versioning container images](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-image-tag-version)
