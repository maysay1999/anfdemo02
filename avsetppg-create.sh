#!/bin/bash

az network vnet create -g anfdemolab-rg -n anfjpe-vnet \
    --address-prefix 172.28.80.0/22 \
    --subnet-name vm-sub --subnet-prefix 172.28.81.0/24

### Bastion
az network vnet subnet create \
    --resource-group anfdemolab-rg \
    --name AzureBastionSubnet \
    --vnet-name anfjpe-vnet \
    --address-prefixes 172.28.82.0/26

az network public-ip create --resource-group anfdemolab-rg \
    --name anfjpe-vnet-ip \
    --sku Standard

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

for i in `seq 1 2`; do
az vm create -g  anfdemolab-rg \
  --name ubuntu$i \
  --availability-set AVSet-JapanEast \
  --size Standard_D4as_v4  \
  --vnet-name anfjpe-vnet \
  --subnet vm-sub \
  --image UbuntuLTS \
  --public-ip-address "" \
  --admin-username anfadmin \
  --admin-password ""
done
