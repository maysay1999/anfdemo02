#!/bin/bash

az network vnet create -g anfdemolab-rg -n anfjpe-vnet \
    --address-prefix 172.28.80.0/22 \
    --subnet-name vm-sub --subnet-prefix 172.28.81.0/24

az network vnet subnet create \
    --resource-group anfdemolab-rg \
    --vnet-name anfjpe-vnet \
    --name anf-sub \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.28.80.0/26

### Bastion
az network vnet subnet create \
    -g anfdemolab-rg \
    -n AzureBastionSubnet \
    --vnet-name anfjpe-vnet \
    --address-prefixes 172.28.82.0/26

az network public-ip create --resource-group anfdemolab-rg \
    --name anfjpe-vnet-ip \
    --sku Standard

az network bastion create --name AnfBastion \
  --public-ip-address anfjpe-vnet-ip \
  -g anfdemolab-rg --vnet-name anfjpe-vnet \
  -l japaneast

#PPG
az ppg create -n ppg-japaneast \
  -g anfdemolab-rg \
  -l japaneast \
  --type Standard

## AVSet
az vm availability-set create -g anfdemolab-rg \
  --name AVSet-JapanEast \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 2 \
  --ppg ppg-japaneast

## SLES VM
az vm create -g  anfdemolab-rg \
  --name SLES1 \
  --ppg ppg-japaneast \
  --size Standard_D4as_v4  \
  --vnet-name anfjpe-vnet \
  --subnet vm-sub \
  --image SLES \
  --public-ip-address "" \
  --admin-username anfadmin \
  --admin-password ""



  