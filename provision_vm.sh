#!/bin/bash

# Variabler
resource_group="MyResourceGroup"
location="northeurope"
vm_name="MyWebServer"
vm_size="Standard_B1s"
admin_user="azureuser"
vnet_name="MyVNet"
subnet_name="MySubnet"
nsg_name="MyWebNSG"
public_ip_name="MyPublicIP"

# 1️⃣ Skapa resursgrupp
az group create --location $location --name $resource_group

# 2️⃣ Skapa virtuellt nätverk och subnet
az network vnet create --resource-group $resource_group --name $vnet_name --address-prefix 10.0.0.0/16 --subnet-name $subnet_name --subnet-prefix 10.0.1.0/24

# 3️⃣ Skapa en publik IP-adress
az network public-ip create --resource-group $resource_group --name $public_ip_name --sku Basic

# 4️⃣ Skapa en Network Security Group (NSG) och tillåt endast HTTP, HTTPS och SSH
az network nsg create --resource-group $resource_group --name $nsg_name
az network nsg rule create --resource-group $resource_group --nsg-name $nsg_name --name AllowWebTraffic --priority 100 --direction Inbound --protocol Tcp --destination-port-ranges 80 443
az network nsg rule create --resource-group $resource_group --nsg-name $nsg_name --name AllowSSH --priority 110 --direction Inbound --protocol Tcp --destination-port-ranges 22

# 5️⃣ Skapa en Ubuntu Virtual Machine med publik IP
az vm create --resource-group $resource_group --name $vm_name --image Ubuntu2204 --size $vm_size --admin-username $admin_user --generate-ssh-keys --public-ip-address $public_ip_name --vnet-name $vnet_name --subnet $subnet_name --nsg $nsg_name

# 6️⃣ Hämta den publika IP-adressen
vm_ip=$(az vm show --resource-group $resource_group --name $vm_name -d --query publicIps -o tsv)
echo "VM är skapad! Publik IP: $vm_ip"

# 7️⃣ Installera .NET och NGINX på VM
ssh -o StrictHostKeyChecking=no $admin_user@$vm_ip << 'EOF'
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y dotnet-sdk-8.0 nginx

    # Konfigurera NGINX som Reverse Proxy
    echo 'server {
        listen 80;
        location / {
            proxy_pass http://localhost:5000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }' | sudo tee /etc/nginx/sites-available/default

    sudo systemctl restart nginx
EOF

# 8️⃣ Publicera och köra .NET-applikationen på servern
echo "🔄 Laddar upp din .NET-applikation till servern..."
scp -r ./MyWebApp $admin_user@$vm_ip:/var/www/mywebapp

ssh $admin_user@$vm_ip << 'EOF'
    cd /var/www/mywebapp
    dotnet MyWebApp.dll &
    echo "✅ Din .NET-applikation är nu live på http://$vm_ip"
EOF

echo "✅ Klar! Öppna din webbläsare och besök: http://$vm_ip"
