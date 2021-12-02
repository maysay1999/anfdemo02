# Azure NetApp Files Hands-on Session: NFS4.1 mount on SUSE Linux

### **Prerequisites**
- Register provider: `az provider register --namespace Microsoft.NetApp`
- Dynamic tier change: `az feature register --namespace Microsoft.NetApp --name ANFTierChange`
- Unix permission: `az feature register --namespace Microsoft.NetApp --name ANFUnixPermissions`
- Unix chown: `az feature register --namespace Microsoft.NetApp --name ANFChownMode`

## 1. Create Resouce Group named *anfdemo01-rg* located *Japan East*
`az group create -n anfdemo-rg -l japaneast`

## 2. Create VNet *anfjpe-vnet*
<pre>
az network vnet create -g anfdemo-rg -n anfjpe-vnet \
    --address-prefix 172.20.0.0/16 \
    --subnet-name vm-subnet --subnet-prefix 172.20.0.0/24
</pre>

## 2. Create ANF subnet
<pre>
az network vnet subnet create \
    --resource-group anfdemo-rg \
    --vnet-name anfjpe-vnet \
    --name anf-sub \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.20.1.0/26
</pre>

