# Azure NetApp Files Hands-on Session: NFS4.1 mount on SUSE Linux

### **Prerequisites**
- Register provider: `az provider register --namespace Microsoft.NetApp`
- Dynamic tier change: `az feature register --namespace Microsoft.NetApp --name ANFTierChange`
- Unix permission: `az feature register --namespace Microsoft.NetApp --name ANFUnixPermissions`
- Unix chown: `az feature register --namespace Microsoft.NetApp --name ANFChownMode`

## 1. Create Resouce Group named *anfdemo01-rg* located *Japan East*
`az group create -n anfdemo-rg -l japaneast`

## 2. Create VNet anfjpe-vnet
- VNet name: anfjpe-vnet
- Location: Japan East
- Address Space: 172.20.0.0/16
- Subnet name: vm-subnet
- Subnet: 172.20.0.0/24
<pre>
az network vnet create -g anfdemo-rg -n anfjpe-vnet \
    --address-prefix 172.20.0.0/16 \
    --subnet-name vm-subnet --subnet-prefix 172.20.0.0/24
</pre>

## 3. Create ANF subnet 172.20.1.0/26 delegated to ANF
- ANF subnet name: anf-subnet
- ANF subnet: 172.20.1.0/26
<pre>
az network vnet subnet create \
    --resource-group anfdemo-rg \
    --vnet-name anfjpe-vnet \
    --name anf-subnet \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.20.1.0/26
</pre>

## 4. Create NetApp account *anfjpe* located *Japan East*
<pre>
az netappfiles account create \
    -g anfdemo-rg \
    --name anfjpe -l japaneast
</pre>

## 5. Create Capacity Pool
- Capacity pool: pool1
- Service level: standard
- Size: 4TiB
- QoS Type: auto (default)
<pre>
az netappfiles pool create \
    --resource-group anfdemo-rg \
    --location japaneast \
    --account-name anfjpe \
    --pool-name pool1 \
    --size 4 \
    --service-level Standard
</pre>
Note)</br>
Maximum size of a single capacity pool: 500 TiB</br>
Maximum number of capacity pools per NetApp account: 25</br>

## 6. Create volume
- Volume name: nfsvol1
- NFS 4.1
Note) It take around 4 minutes
<pre>
az netappfiles volume create \
    --resource-group anfdemo-rg \
    --location japaneast \
    --account-name anfjpe \
    --pool-name mypool1 \
    --name nfsvol1 \
    --service-level Standard \
    --vnet anfjpe-vnet \
    --subnet anf-sub \
    --usage-threshold 1024 \
    --file-path nfsvol1 \
    --protocol-types "NFSv4.1
</pre>
Note)</br>
Maximum size of a single volume: 100 TiB</br>
Maximum number of volumes per capacity pool: 500</br>

## 7. Create SUSE linux 15 VM
- VM type: **Standard B2S**
- Image: **SUSE linux 15**
- Authentication type: **password**
- Username: **anfadmin**
- Password: ----
- OS disk type: **Standard HDD**
- VNet: **anfjpe-vnet**
- Subnet: **vm-sub**
- Public IP: **None** (security reason)

## 8. Configure Bastion
<pre>
RG=anfdemo-rg
VNET=anfjpe-vnet

az network vnet subnet create \
    --resource-group $RG \
    --name AzureBastionSubnet \
    --vnet-name $VNET \
    --address-prefixes 172.20.3.0/28

az network public-ip create --resource-group $RG \
    --name bastionpublic-ip \
    --sku Standard 

az network bastion create -g $RG \
    --name MyBastionHost \
    --public-ip-address bastionpublic-ip \
    --vnet-name $VNET
</pre>

## 9. Login on SUSE via Bastion
- Login as root `sudo su -` or `sudo -i`
- Verify login as root `whoami`

## 10. Mount ANF as NFS 4.1
- Mount path: /mnt/nfsvol1/
- Follow **Mount Instruction**
Note) Not necesssry to install NFS utilities

## 11. Install fio
`zypper install fio`

## 12. Run fio command to measure realtime throughput
`fio -rw=randwrite -bs=8k -size=2000m -numjobs=40 -runtime=180 -direct=1 -invalidate=1 -ioengine=libaio -iodepth=32 -iodepth_batch=32 -group_reporting -name=FioDiskThroughputTest`

## 13. Change size of volume to 2TiB
- Expected value: Thougthput to be changed to 32Mbps from 16Mbps
- See realtime change of throughput

## 14. One-time Snapshot and volume-based restration
- Create a test file named test.txt under /mnt/nfsvol1/ `echo "this is the test" > text.txt`
- Create one-time snapshot: *snapshot01*
- Create clone volume from the snapshot
- Revert
- Create one-time snapshot: *snapshot01*
Note) Max number of snapshot per volume is 255

## 15. Snapshot: file-based restoration
- `cd /mnt/nfsvol1/`
- `ls -la`
- `cd .snapshot`
- `ls -la`
- `cd snapshot01`
- Restore text.txt as `text2.txt: cp text.txt ../../text2.txt`
- Verify: `cd ../../` and `cat text2.txt`

## 16. Snapshot policy
Note) Timezone is UTC.  Japan Standard time is UTC +9 
<pre>
az netappfiles snapshot policy create -g anfdemo-rg \
    --account-name anfjpe \
    --snapshot-policy-name policy01 \
    -l japaneast \
    --hourly-snapshots 8 \
    --hourly-minute 59 \
    --enabled true
</pre>

## 17. Change QoS type to Manual from Auto
<pre>
az netappfiles pool update -g anfdemo-rg \
    --account-name anfjpe --name pool1 \
    --qos-type Manual
</pre>

And change throughput manually to 50Mbps
<pre>
az netappfiles volume update -g anfdemo-rg \
    --account-name anfjpe --pool-name pool1 \
    --name nfsvol1 --service-level standard \
    --throughput-mibps 50
</pre>

## 18. Extend pool size to increase throughput further
Extend pool size to 8 TiB
<pre>
az netappfiles pool update -g anfdemo-rg \
    --account-name anfjpe \
    --name pool1 \
    --size 8
</pre>
And change throughput manually to 80Mbps
<pre>
az netappfiles volume update -g anfdemo-rg \
    --account-name anfjpe --pool-name pool1 \
    --name nfsvol1 --service-level standard \
    --throughput-mibps 80
</pre>

## 19. Change Service Level to increase throughput furthermore
- Create 4TiB one more pool **pool2** as Premium Service Level
- Move the current volumes to **pool2**
- Remove pool1
<pre>
az netappfiles pool create \
    --resource-group anfdemo-rg \
    --location japaneast \
    --account-name anfjpe \
    --pool-name pool2 \
    --size 4 \
    --qos-type Manual \
    --service-level Premium
</pre>
And after moving all volumes to pool2, delete pool1</br>
`az netappfiles pool delete -g anfdemo-rg -a anfjpe -n pool1`

## 19. Cross Region Replication
### CRR process to be done in the GUI
- Briefing on Cross Region Replicaiton (DR)
- Create a new VNet, **anfjpw-vnet**  
- Address space is **172.21.0.0/16**
- Location: **Japan West** (pair region). 
- Create a new subnet, **vm-sub**.  172.21.0.0/24
- Create a new subnet, **anf-sub**.  172.21.1.0/26
- ANF netapp account: **anfjpw** (location: Japan West)
- Capacity pool name: **pooldr** (4TiB, Standard)
- Replication volume name: **voldr** (througput 16Mbps)
- Replication frequency: **once a day**

Reference
- [Price of Cross Region Replication](https://azure.microsoft.com/en-us/pricing/details/netapp/)</br>
[Japanese](https://azure.microsoft.com/ja-jp/pricing/details/netapp/)
- [Limitatoin of ANF](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-resource-limits)</br>
[Japanese](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-resource-limits)

---
