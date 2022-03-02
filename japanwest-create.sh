#!/bin/bash

az network vnet create -g anfdemolab-rg -n anfjpw-vnet \
    --address-prefix 172.21.0.0/16 \
    --subnet-name vm-subnet \
    -l japanwest \
    --subnet-prefix 172.21.0.0/24

az network vnet subnet create \
    --resource-group anfdemolab-rg \
    --vnet-name anfjpw-vnet \
    --name anf-subnet \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.21.1.0/26

az netappfiles account create \
    -g anfdemolab-rg \
    --name anfjpw -l japanwest

az netappfiles pool create \
    --resource-group anfdemolab-rg \
    --location japanwest \
    --account-name anfjpw \
    --pool-name pooldr \
    --size 4 \
    --service-level Standard


