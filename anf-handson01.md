# Azure NetApp Files Hands-on Session: NFS4.1 mount on SUSE Linux

### **Prerequisites**
- Register provider: `az provider register --namespace Microsoft.NetApp`
- Dynamic tier change: `az feature register --namespace Microsoft.NetApp --name ANFTierChange`
- Unix permission: `az feature register --namespace Microsoft.NetApp --name ANFUnixPermissions`
- Unix chown: `az feature register --namespace Microsoft.NetApp --name ANFChownMode`

[GUI: Register provider](images/register-provider.png)

[View hands-on diagram](https://github.com/maysay1999/anfdemo02/blob/main/211202_hands-on_diagram_linux_nfs_sap_nfs41.pdf)

## 1. Create Resouce Group
- Resource Group name: **anfdemo-rg**
- Location: **Japan East**

`az group create -n anfdemo-rg -l japaneast`</br></br>
[GUI: Create Resource Group](images/resource-group.png)

## 2. Create VNet anfjpe-vnet
- VNet name: **anfjpe-vnet**
- Location: **Japan East**
- Address Space: **172.20.0.0/16**
- Subnet name: **vm-subnet**
- Subnet: **172.20.0.0/24**
<pre>
az network vnet create -g anfdemo-rg -n anfjpe-vnet \
    --address-prefix 172.20.0.0/16 \
    --subnet-name vm-subnet --subnet-prefix 172.20.0.0/24
</pre>
[GUI: Create VNet](images/create-vnet.png)</br>
[GUI: Create VNet and Subnet](images/create-vnet2.png)

## 3. Create ANF subnet
- ANF subnet name: **anf-subnet**
- ANF subnet: **172.20.1.0/26**
- ANF delegation: **Microsoft.Netapp/volumes**
<pre>
az network vnet subnet create \
    --resource-group anfdemo-rg \
    --vnet-name anfjpe-vnet \
    --name anf-subnet \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.20.1.0/26
</pre>
[GUI: Create VNet](images/create-subnet.png)</br>
[GUI: Create VNet and Subnet](images/create-subnet2.png)

## 4. Create Bastion (CLI is recommended)
- Name: anfjpe-vnet-bastion
- Tier: Standard
- Virtual Network: anfjpe-vnet
- New public IP name : anfjpe-vnet-ip
- Public IP address SKU: Standard
- Procedure: Execute these command lines and create bastion on GUI portal

<pre>
az network vnet subnet create \
    --resource-group anfdemo-rg \
    --name AzureBastionSubnet \
    --vnet-name anfjpe-vnet \
    --address-prefixes 172.20.3.0/26

az network public-ip create --resource-group anfdemo-rg \
    --name anfjpe-vnet-ip \
    --sku Standard 
</pre>

[GUI: Bastion](images/create-bastion.png)

## 5. Create SUSE linux VM
- Virtual machine name: **suse01**
- Region: **Japan East**
- Image: **SUSE Enterprise linux for SAP 15 SP3 + 24x7 Support Gen 2**
- VM type: **Standard_D2s_v4**
- Authentication type: **Password**
- Username: **anfadmin**
- Password: ---- (min length is 12)
- OS disk type: **Premium SSD**
- VNet: **anfjpe-vnet**
- Subnet: **vm-subnet**
- Public IP: **None** 

[GUI: How to choose the correct image](images/suse-marketplace.png)\
[GUI: SUSE VM setups](images/suse-create-vm01.png)

## 6. Create NetApp account
- ANF account name: **anfjpe**
- Location: **Japan East**
<pre>
az netappfiles account create \
    -g anfdemo-rg \
    --name anfjpe -l japaneast
</pre>

[GUI: NetApp Account](images/create-netapp-account.png)

## 7. Create Capacity Pool
- Capacity pool: **pool1**
- Service level: **standard**
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

[GUI: Capacity Pool](images/create-pool.png)

## 8. Create volume
- Volume name: **nfsvol1**
- NFS **4.1**
- Quota: **1024** GiB\
Note) It take around 4 minutes
<pre>
az netappfiles volume create \
    --resource-group anfdemo-rg \
    --location japaneast \
    --account-name anfjpe \
    --pool-name pool1 \
    --name nfsvol1 \
    --service-level Standard \
    --vnet anfjpe-vnet \
    --subnet anf-subnet \
    --usage-threshold 1024 \
    --file-path nfsvol1 \
    --allowed-clients 0.0.0.0/0 \
    --rule-index 1 \
    --protocol-types NFSv4.1 \
    --unix-read-write true
</pre>
Note)</br>
Maximum size of a single volume: 100 TiB</br>
Maximum number of volumes per capacity pool: 500</br>

[GUI: Volume](images/create-volume.png)
[GUI: Set NFS 4.1](images/create-volume2.png)

## 9. Login on SUSE via Bastion
Create Bastion on GUI
- Bastion name: **anfjpe-vnet-bastion**
- Bastion tier: **Standard**
- Virtual Network: **anfjpe-vnet**
- Bastion public IP name : **anfjpe-vnet-ip**

[GUI: Bastion setup](images/bastion.png)

Login on SUSE via Bastion
- Login as root `sudo su -` or `sudo -i`
- Verify login as root `whoami`

## 10. Mount ANF as NFS 4.1
- Mount path: **/mnt/nfsvol1/**
- Follow **Mount Instruction**\
Note) Not necesssry to install NFS utilities

1. Install NFS client: not necessary (already installed)
2. Change the path to /mnt: `cd /mnt`
3. Create a new directory to mount ANF volume: `mkdir nfsvol1`
4. Mount: `mount -t nfs -o rw,hard,rsize=1048576,wsize=1048576,sec=sys,vers=4.1,tcp 172.20.1.4:/nfsvol1 nfsvol1`

Verificate mounting ANF volunme
- `df -h` 
- `mount`: for the details

Change to ANF mounted directory and create test file
- `cd /mnt/nfsvol1`
- `echo "this is a test file" > test.txt`

## 11. Install fio
fio - Flexible I/O tester is introduced on [Microsoft website](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-benchmarks#fio) as a tool to get maximum throughput.  

- Install fio: `zypper install -y fio`

## 12. Run fio command to measure realtime throughput
`fio -rw=randwrite -bs=8k -size=2000m -numjobs=40 -runtime=600 -direct=1 -invalidate=1 -ioengine=libaio -iodepth=32 -iodepth_batch=32 -group_reporting -name=FioDiskThroughputTest`

## 13. Change size of volume to 2TiB
- Expected value: Thougthput to be changed to 32Mbps from 16Mbps
- See realtime change of throughput

<pre>
az netappfiles volume update -g anfdemo-rg \
   --account-name anfjpe --pool-name pool1 \
   --name nfsvol1 --service-level Standard \
    --usage-threshold 2048
</pre>

## 14. One-time Snapshot and volume-based restration
- Create a test file named test.txt under /mnt/nfsvol1/ `echo "this is the test" > test.txt`
- Create one-time snapshot: *snapshot01*
- Create clone volume from the snapshot
- Revert
- Create one-time snapshot: *snapshot01*
Note) Max number of snapshot per volume is 255

<pre>
az netappfiles snapshot create -g anfdemo-rg \
    --account-name anfjpe \
    --pool-name pool1 \
    --volume-name nfsvol1 \
    -l japaneast \
    --name snapshot01
</pre>

## 15. Snapshot: file-based restoration
- `cd /mnt/nfsvol1/`
- `ls -la`
- `cd .snapshot`
- `ls -la`
- `cd snapshot01`
- Restore test.txt as `test2.txt: cp test.txt ../../test2.txt`
- Verify: `cd ../../` and `cat test2.txt`

## 16. Snapshot policy
Note) Timezone is UTC.  Japan Standard time is UTC +9 
<pre>
az netappfiles snapshot policy create -g anfdemo-rg \
    --account-name anfjpe \
    --snapshot-policy-name hourly-pol01 \
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
Extend pool size to 6 TiB
<pre>
az netappfiles pool update -g anfdemo-rg \
    --account-name anfjpe \
    --name pool1 \
    --size 6
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

## 21. Cross Region Replication
### CRR process to be done in the GUI
`git clone https://github.com/maysay1999/anfdemo02.git AnfHandson`
- `chmod 711 japanwest-create.sh`  Execute japanwest-create.sh
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
[Price of Cross Region Replication (Japanese)](https://azure.microsoft.com/ja-jp/pricing/details/netapp/)
- [Limitatoin of ANF](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-resource-limits)</br>
[Limitatoin of ANF (Japanese)](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-resource-limits)

---
