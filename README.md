## CI CD for Containers using Azure Kubernetes Services with Application Insights

Proof of Concept for the solution design provided by Microsoft in their Azure Solution Architecture examples.  
   
 - Intent is to integrate services with basic configurations to make the solution work end to end.  
 - Not designed for Security, Performance, Availability and Resilience best practices.
 - Wherever possible, external references are provided which helps in configuration.

**Base Solution Architecture** - Provided by Microsoft - https://azure.microsoft.com/en-in/solutions/architecture/cicd-for-containers/

![Image of Solution from Microsoft](https://github.com/Sanoobk/CICDContainers-Demo02/blob/master/Images/SolutionDesign.PNG)

**Below is a rough aggregation of components, configurations and tools required for completing the solution.**

![Components and Configuraiton list](https://github.com/Sanoobk/CI-CD-Containers-Azure-Kubernetes-Service/blob/master/Images/Components.PNG)


## Stage 1: Create and Configure Azure Services

**1. Create Azure Resource Group, Azure Container Registry and Azure Kubernetes Service instance**

`az group create -n CICDDemoRG -l westeurope`

`az acr create -g CICDDemoRG -n DemoACR777 --sku Basic`

**2. Create AKS and Provide the Service Principal access to ACR to pull images to AKS.** 

Its good to read below article before deciding to create the AKS. Make a decision to use Custom Service Principal or the AKS generated Service Principal to give access to ACR later. For development tenants with Tenant access, you could use 2.a

https://docs.microsoft.com/en-gb/azure/container-registry/container-registry-auth-aks?toc=%2fazure%2faks%2ftoc.json#grant-aks-access-to-acr

**2.a If Custom Service Principal is not needed, run the below command or skip to 2.b**
`az aks create -g CICDDemoRG -n CICDAKS --node-count 1 --generate-ssh-keys --enable-addons monitoring `
	
**2.b If a custom service principal is needed, then the below steps can be used to create the Service Principal and then use the same to create AKS and then provide access to ACR to pull images.**

`az ad sp create-for-rbac --skip-assignment`

`az aks create -g CICDDemoRG -n CICDAKS --service-principal xxxxxxxxxx --client-secret xxxxxx --node-count 1 --enable-addons monitoring --generate-ssh-keys`

**2.c Provide access for AKS Service Principal to ACR using scripts from the below link based on how the the Service Principal was created from 2.a or 2.b**
https://docs.microsoft.com/en-gb/azure/container-registry/container-registry-auth-aks?toc=%2fazure%2faks%2ftoc.json#grant-aks-access-to-acr	

**3. Install Kubectl (CLI tool for Kubernetes) if not already.**
For cloud shell the az aks install-cli not needed as Kubectl tool is already installed.
`az aks install-cli`

`az aks get-credentials -g CICDDemoRG -n CICDAKS`

Test if Kubectl has permissions to the AKS Cluster

`Kubectl get nodes`

## Stage 2: Create Web Application

**1. Create a new ASP.NET Core MVC Web Application with Docker integration for Linux**
Created a basic ASP.NET MVC .NET Core Web Application with 'Enable Docker Support' integration for Linux. Enable local Git integration.

![Image for the Docker Support Setting](https://github.com/Sanoobk/CICDContainers-Demo02/blob/master/Images/DockerIntegration.PNG)

**Issue**: https://github.com/aspnet/aspnet-docker/issues/401
Move the DockerFile created by VS2017 (Community Edition) one folder above to avoid issues during building and deployment. 

**2. Use the link below for the latest dotnet core and asp.net core runtime docker images from Microsoft Container Registry**** 
Preferred to use the Microsoft Registry images which are up to date than the Docker Hub public images.

https://docs.microsoft.com/en-us/dotnet/architecture/microservices/net-core-net-framework-containers/official-net-docker-images

**3. Create a GitHub remote repository and integrate the local repository**
GitHub is used as the code repository over Azure Repos as shown earlier in the design for convenience.

## Stage 3: Azure DevOps Pipelines

**1. Create an Azure DevOps build pipeline.** Ensure to have a project created in the dev.azure.com. Do not need Azure Repos as we are using GitHub as our remote Repo. Only Azure Pipelines are used for this solution.
Follow the [video link](https://azure.microsoft.com/nl-nl/resources/videos/build-2019-yaml-release-pipelines-in-azure-devops/) for details on creating the Build Pipeline for Pushing the ASP.NET web application docker image to ACR and then Deploying to AKS.

**2. Configure PipeLine** On a high level, its as simple as creating the pipeline from the UI, connect to the GitHub repo and Authorize, select the 'Deploy to Azure Kubernetes Service' configuration and then provide the basic information on the screen about the AKS Cluster and ACR created in Stage 1.

![Image for Task to depoy to AKS](https://github.com/Sanoobk/CICDContainers-Demo02/blob/master/Images/DeploytoAKS.PNG)

**3. Pull the yml files to the local repo** - Once configured, three *.yml files will be created by the pipeline and added to the Remote GitHub repo. (azure-pipeline.yml, manifests/service.yml and manifests/deployment.yml). These files help to build the DockerFile, push the image to ACR and deploy the container to AKS cluster. Its a good shortcut to generate yaml/yml files for other automation requirements.

*Build agent servers are not needed. For this Pipeline we can use the Microsoft Hosted build server (free) for this demo. (Linux Ubuntu OS)*

## Stage 4: Telemetry

**Step 1: Configure Application Insights for the Web Application**
[A very good article](https://www.c-sharpcorner.com/article/configure-application-insight-for-net-core-2-0/) to configure the Application Insights for the ASP.NET MVC Web Application. Simple steps with minimal coding. Telemetry capturing for advanced scenarios like Application Insights Funnels, Retention etc are not covered.

**Step 2.a: Create Work Item (Bug) in Azure Boards**

To create actual Work Item, follow instructions from [link](https://azure.microsoft.com/nl-nl/blog/application-insights-work-item-integration-with-visual-studio-team-services/) 
Bugs can be created. Automatic work item creation is not yet available. 

**Step 2.b: Automatic Work Item Creation using Logic Apps**

**Step 2.b.1: Create Logic App**
Use Logic Apps to create a new Azure DevOps Boards Work Item (Issue) when an AKS Active Node Count metric is greater than 3.

Links below can help with designing the simple Logic App.

**Trigger**: HTTP Trigger **Action**: Azure DevOps Create Work Item

[Link](https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/work%20items/create?view=azure-devops-rest-5.1#examples) to get sample HTTP Post payload information for the Logic App.

**Step 2.b.2: Create New Alert Rule**
Create a New alert rule under Metrics for the AKS and connect to the Logic App created in 2.b.1 during the configuration.

## Solution Implementation is complete.

## References

 - [Solution Design Concept](https://azure.microsoft.com/en-in/solutions/architecture/cicd-for-containers/)
 - [Grant Access for AKS to pull images from    ACR](https://docs.microsoft.com/en-gb/azure/container-registry/container-registry-auth-aks?toc=/azure/aks/toc.json#grant-aks-access-to-acr)
 - [Official Dotnet Docker Images from    Microsoft](https://docs.microsoft.com/en-us/dotnet/architecture/microservices/net-core-net-framework-containers/official-net-docker-images)
 - [Building YAML Pipelines in Azure    DevOps](https://azure.microsoft.com/nl-nl/resources/videos/build-2019-yaml-release-pipelines-in-azure-devops/)
 - [Configure Application Insights for ASP.NET Core MVC Web    Application](https://www.c-sharpcorner.com/article/configure-application-insight-for-net-core-2-0/)
 - [Creating Azure DevOps Boards Work Item from Application    Insights](https://azure.microsoft.com/nl-nl/blog/application-insights-work-item-integration-with-visual-studio-team-services/)
 - [Sample Azure DevOps Boards Work Item payload for Logic App HTTP    Request    Trigger](https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/work%20items/create?view=azure-devops-rest-5.1#examples)

## Credits
-   [Jagadesh Julapalli](https://www.c-sharpcorner.com/members/jagadesh-julapalli2) for Application Insights and ASP.NET MVC configuration.
-   Mike Gresley (Microsoft) - for Work Item integration and creation from Application Insights.
- Sasha Rosenbaum - Building YAML Pipelines in Azure DevOps
- [lloydsmithjr03](https://github.com/lloydsmithjr03/aks_test/commits?author=lloydsmithjr03) for the commit ac91ee82251e3c7427556ef0bd699b39508a35c4

License
----

MIT

