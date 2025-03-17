#!/bin/bash

# Variabler
resource_group="NewRG"
location="northeurope"
vm_name="MyWebServer"
vm_size="Standard_B1s"
admin_user="azureuser"
subnet_name="MySubnet"
vnet_name="MyVNet"
nsg_name="MyWebNSG"
bastion_name="MyBastion"
bastion_ip="MyBastionIP"

# Skapa resursgrupp
az group create --location $location --name $resource_group

# Skapa ett virtuellt nätverk och subnet
az network vnet create --resource-group $resource_group --name $vnet_name \
    --address-prefix 10.0.0.0/16 --subnet-name $subnet_name --subnet-prefix 10.0.0.0/24

# Skapa en Network Security Group (NSG) och tillåt endast HTTP och HTTPS
az network nsg create --resource-group $resource_group --name $nsg_name
az network nsg rule create --resource-group $resource_group --nsg-name $nsg_name \
    --name AllowWebTraffic --priority 100 --direction Inbound --protocol Tcp \
    --destination-port-ranges 80 443

# Skapa en Ubuntu Virtual Machine (utan publik IP)
az vm create --resource-group $resource_group --name $vm_name \
    --image Ubuntu2204 --size $vm_size --admin-username $admin_user \
    --generate-ssh-keys --custom-data @cloud-init_dotnet.yaml \
    --vnet-name $vnet_name --subnet $subnet_name \
    --nsg $nsg_name --public-ip-address ""

# Skapa en Bastion Host
az network public-ip create --resource-group $resource_group --name $bastion_ip --sku Standard
az network bastion create --resource-group $resource_group --name $bastion_name \
    --public-ip-address $bastion_ip --vnet-name $vnet_name --location $location

# Kontrollera att VM är skapad innan vi öppnar portar
if [ $? -eq 0 ]; then
    echo "VM skapad, anslut via Azure Bastion."
else
    echo "Fel vid skapandet av VM."
    exit 1
fi
