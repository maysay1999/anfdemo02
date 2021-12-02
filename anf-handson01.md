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

## 3. Create ANF subnet 172.20.1.0/26 delegated to ANF
<pre>
az network vnet subnet create \
    --resource-group anfdemo-rg \
    --vnet-name anfjpe-vnet \
    --name anf-sub \
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

## 6. Create volume
- Volume name: nfsvol1
- NFS 4.1
Note) It take around 4 minutes

## 7. Create SUSE linux 15 VM
### **Considering to set ARM template**
- VM type: Standard B2S
- Authentication type: password
- Username: anfadmin
- Password: 
- OS disk type: Standard HDD
- VNet: anfjpe-vnet 
- Subnet: vm-sub
- Public IP: None (security reason)

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

## 9. Mount ANF as NFS 4.1
- Mount path: /mnt/nfsvol1/
- Follow **Mount Instruction**
Note) Not necesssry to install NFS utilities

## 10. Install fio
`zypper install fio`

## 11. Run fio command to measure realtime throughput
`fio -rw=randwrite -bs=8k -size=2000m -numjobs=40 -runtime=180 -direct=1 -invalidate=1 -ioengine=libaio -iodepth=32 -iodepth_batch=32 -group_reporting -name=FioDiskThroughputTest`

## 12. Change size of volume to 2048
- Expected value: Thougthput to be changed to 32Mbps from 16Mbps

## 13. One-time Snapshot and volume-based restration
- Create a test file named test.txt under /mnt/nfsvol1/ `echo "this is the test" > text.txt`
- Create one-time snapshot: *snapshot01*
- Create clone volume from the snapshot
- Revert
- Create one-time snapshot: *snapshot01*

## 14. Snapshot: file-based restoration
- `cd /mnt/nfsvol1/`
- `ls -la`
- `cd .snapshot`
- `ls -la`
- `cd snapshot01`
- Restore text.txt as `text2.txt: cp text.txt ../../text2.txt`
- Verify: `cd ../../` and `cat text2.txt`

## 15. Snapshot policy

## 16. Manual QoS

## 17. Extend pool size to increase throughput further

## 18. Change Service Level to increase throughput furthermore

## 19. Cross Region Replication

---
