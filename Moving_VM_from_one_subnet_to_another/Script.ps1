
#Login to Azure RM account
Login-AzureRmAccount

#Set the default subscription if you have more than one subscription
Set-AzureRmContext -SubscriptionName <subscription-name>

#Declare the parameters
$location="South India"
$resourceGroup="<resource-group-name>"
$storageAccountName="<storage-account-name>"
$subnet1Name="<subnet1-name>"
$subnet2Name="<subnet2-name>"
$vnetName="<vnet-name>"
$vmPIPName="<public-IP-name>"
$vmNicNme="<NIC-name>"
$vmName="<VM-name>"

#Create new Resource group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location 

#Chceck the storage account name is uniuqe or not
$available=Get-AzureRmStorageAccountNameAvailability -Name $storageAccountName
if (!$available )
{
    $storageAccountName=$storageAccountName +"01"
}

#Create new storage account
New-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup -Location $location -SkuName Standard_LRS -Kind Storage

#Create VNET with two subnets in the newly created resource group
$firstSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix 10.0.1.0/24
$secondSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.2.0/24
New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $firstSubnet,$secondSubnet

#Create public IP and NIC on first subnet
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
$publicIp=New-AzureRmPublicIpAddress -Name $vmPIPName -ResourceGroupName $resourceGroup -Location $location -IpAddressVersion IPv4 -AllocationMethod Dynamic 
$nic=New-AzureRmNetworkInterface -Name $vmNicNme -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

#Create new VM
$credential=Get-Credential -Message "Enter username and password for the VM administrator"

$blobPath = "vhds/myOsDisk1.vhd"
$storageAccount=Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + $blobPath

$vm=New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_A2"
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName "VMPC" -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -Id $nic.Id -VM $vm
$vm=Set-AzureRmVMOSDisk -Name "VMOSDisk" -VhdUri $osDiskUri -CreateOption FromImage -VM $vm
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm

###################################################################################################

#Move the VM to second subnet
$vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName

# VM created in Availability Set
$VirtualMachine.AvailabilitySetReference

# Obtain NIC, subnet and VNET references
$nic = Get-AzureRmNetworkInterface -Name $vmNicNme -ResourceGroupName $resourceGroup
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName  -ResourceGroupName $resourceGroup
$secondSubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet2Name

#set the NIC Subnet as second subnet
$nic.IpConfigurations[0].Subnet.Id = $secondSubnet.Id
Set-AzureRmNetworkInterface -NetworkInterface $nic
