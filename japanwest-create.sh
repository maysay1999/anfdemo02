#!/bin/bash

az network vnet create -g anfdemolab-rg -n anfjpw-vnet \
    --address-prefix 172.29.80.0/22 \
    --subnet-name vm-sub \
    -l japanwest \
    --subnet-prefix 172.29.81.0/24

az network vnet subnet create \
    --resource-group anfdemolab-rg \
    --vnet-name anfjpw-vnet \
    --name anf-sub \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.29.80.0/26

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


