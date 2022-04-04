#!/bin/bash

# create a destination account and pool
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

# create a source volume
az netappfiles volume create \
    --resource-group anfdemolab-rg \
    --location japaneast \
    --account-name anfjpe \
    --pool-name pool1 \
    --name source-volume \
    --service-level Standard \
    --vnet anfjpe-vnet \
    --subnet anf-sub \
    --allowed-clients 0.0.0.0/0 \
    --rule-index 1 \
    --usage-threshold 100 \
    --file-path sourcevolumepath \
    --protocol-types NFSv3



