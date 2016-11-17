
#Login to Azure RM account
Login-AzureRmAccount

#Set your azure subscription if you have multiple subscriptions in your account
Set-AzureRmContext -SubscriptionName "<subscription name>"

#Create a VNET with two subnets using Deployment template
New-AzureRmResourceGroupDeployment -ResourceGroupName "<resource-group-name>" -TemplateFile ".\azuredeploy.json" -TemplateParameterFile ".\azuredeploy.parameters.json"