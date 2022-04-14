#!/bin/bash

# Variables
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'

# VARIABLES TO CHANGE
SUBSCRIPTION=0a52391c-0d81-434e-90b4-d04f5c670e8a   # Set your Azure Subscription
ENVIRONMENT=dev                                     # choice of dev|prod
LOCATION=northeurope
NAME_SUFFIX=001
RG_NAME=rg-apim-PoC-dev-001
VNET_NAME=vnet-apim-poc-dev-001


# Code - do not change anything here on deployment
# 1. Set the right subscription
printf "$blue" "*** Setting the subsription to $SUBSCRIPTION ***"
az account set --subscription "$SUBSCRIPTION"

# 2. Create main Resource group if not exists
az group create --name $RG_NAME --location $LOCATION
printf "$green" "*** Resource Group $RG_NAME created (or Existed) ***"

# 3. start the BICEP deployment
printf "$blue" "starting network BICEP deployment for ENV: $ENVIRONMENT"
az deployment group create \
    -f ./deploySubnets.bicep \
    -g $RG_NAME

printf "$green" "*** Deployment finished for ENV: $ENVIRONMENT.  ***"
printf "$green" "***************************************************"


# outputs=$(az deployment group show --name deploySubnets -g $RG_NAME --query properties.outputs)

az deployment group show --name deploySubnets -g $RG_NAME --query properties.outputs