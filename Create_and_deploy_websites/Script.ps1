#Login to the Azure RM A
Login-AzureRmAccount

#Declare parameter variables
$resGroup ="masterazure-xxx-RG"
$appName="sampleapp-xxx"
$location="South India"
$slotName="Staging"
$svcPlanName="appsvc-plan-xxx"

#Create app service plan
$appSvcPlan = New-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $svcPlanName -Location $location -Tier Standard #-NumberofWorkers 1 -WorkerSize "Small"

#Create new web app
New-AzureRmWebApp -ResourceGroupName $resGroup -Name $appName -Location $location -AppServicePlan $appSvcPlan.Name

#Create a deployment slot for staging
New-AzureRmWebAppSlot -ResourceGroupName $resGroup -Name $appName -Slot $slotName -AppServicePlan $appSvcPlan.Name

#Publish the web site package to staging slot
Publish-AzureWebsiteProject -Name $appName -Slot $slotName -Package "<path of deployment package>\SampleWebsite.zip"


#Swap the Staging slot and production slot
$ParametersObject = @{targetSlot  = "Production"}
Invoke-AzureRmResourceAction -ResourceGroupName $resGroup -ResourceType Microsoft.Web/sites/slots -ResourceName $appName/$slotName -Action slotsswap -Parameters $ParametersObject #-ApiVersion 2015-07-01
