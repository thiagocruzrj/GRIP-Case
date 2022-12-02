# GRIP Case Assignment 
Migrating a monolithic application into cloud-native application, explaining step by step.

## Part1 - Cloud Setup
* The .pptx and .pdf files are located in the "GRIP-Case/Part1-Cloud Setup" folder

## Tools used on Part2-Infrastructure
Azure DevOps Pipelines
* A pipeline was created with all the environments needed for an API to be pushed to production. 
* The azure-pipelines.yml file receives a template distributed to each environment, and each environment has its keyword.

## Helm
The package manager for Kubernetes. Used here to install ingress, cert-manager, and some tools like SSL-redirect.
* Ingress - to map traffic to different backends based on rules you define via the Kubernetes
* cert-manager - provides Helm charts as a first-class installation method on Kubernetes and manages non-namespaced resources in your cluster.

## Terraform
Used to create an AKS cluster with the best practices like:
* Using the remote state, the Terraform will write the state data to remote storage, which all members can have access. With this approach, we can use the state lock (used to not corrupt the state file when two developers are trying to execute some terraform configuration simultaneously) 
* Retrieving keys from ACR using the resource kubernetes_secret.

## Log Analytics to observability on AKS
To collect the essential logs from our cluster.

## Powershell
To automatize the startup of creation of all the most critical resources on Azure Cloud like:
* Resource group
* Storage account
* Container to store the .tfsate files (Terraform state)
* Give the service principal access rule needed to assign roles in Terraform
* Connect the Azure DevOps API to create the connection to our Azure Subscription
