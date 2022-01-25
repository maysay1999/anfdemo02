# Azure NetApp Files ハンズオンセッション: NFS4.1 mount on SUSE Linux

### **前提条件**

- Register provider: `az provider register --namespace Microsoft.NetApp`
- Dynamic tier change: `az feature register --namespace Microsoft.NetApp --name ANFTierChange`
- Unix permission: `az feature register --namespace Microsoft.NetApp --name ANFUnixPermissions`
- Unix chown: `az feature register --namespace Microsoft.NetApp --name ANFChownMode`

[GUI: Register provider](images/register-provider.png)

[View hands-on diagram](https://github.com/maysay1999/anfdemo02/blob/main/211202_hands-on_diagram_linux_nfs_sap_nfs41.pdf)

<div style="text-align: left"><img src="/images/Handson_general_diagram.png" ></div>
<br>

## 1. リソースグループ作成

- Resource Group name: **anfdemo-rg**
- Location: **Japan East**

`az group create -n anfdemo-rg -l japaneast`</br></br>
[GUI: Create Resource Group](images/resource-group.png)

## 2. 仮想ネットワーク anfjpe-vnet　作成

- VNet name: **anfjpe-vnet**
- Location: **Japan East**
- Address Space: **172.20.0.0/16**
- Subnet name: **vm-subnet**
- Subnet: **172.20.0.0/24**

```bash
az network vnet create -g anfdemo-rg -n anfjpe-vnet \
    --address-prefix 172.20.0.0/16 \
    --subnet-name vm-subnet --subnet-prefix 172.20.0.0/24
```

[GUI: Create VNet](images/create-vnet.png)</br>
[GUI: Create VNet and Subnet](images/create-vnet2.png)

## 3.  ANF サブネット作成

- ANF subnet name: **anf-subnet**
- ANF subnet: **172.20.1.0/26**
- ANF delegation: **Microsoft.Netapp/volumes**

```bash
az network vnet subnet create \
    --resource-group anfdemo-rg \
    --vnet-name anfjpe-vnet \
    --name anf-subnet \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.20.1.0/26
```

[GUI: Create VNet](images/create-subnet.png)</br>
[GUI: Create VNet and Subnet](images/create-subnet2.png)

## 4. SUSE linux VM作成

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

## 5. Bastionを構成する (GUI はおすすめ)

- Name: anfjpe-vnet-bastion
- Tier: Standard
- Virtual Network: anfjpe-vnet
- New public IP name : anfjpe-vnet-ip
- Public IP address SKU: Standard
- Procedure: Execute these command lines and create bastion on GUI portal

```bash
az network vnet subnet create \
    --resource-group anfdemo-rg \
    --name AzureBastionSubnet \
    --vnet-name anfjpe-vnet \
    --address-prefixes 172.20.3.0/26

az network public-ip create --resource-group anfdemo-rg \
    --name anfjpe-vnet-ip \
    --sku Standard
```

[GUI: Bastion](images/create-bastion0119.png)

## 6. Bastionで SUSEにログイン

Bastionで SUSEにログイン

- Login as root `sudo su -` or `sudo -i`
- Verify login as root `whoami`

## 7. Azure NetApp Files アカウント作成

- ANF account name: **anfjpe**
- Location: **Japan East**

```bash
az netappfiles account create \
    -g anfdemo-rg \
    --name anfjpe -l japaneast
```

[GUI: NetApp Account](images/create-netapp-account.png)

## 8. 容量プールを作成

- Capacity pool: **pool1**
- Service level: **standard**
- Size: 4TiB
- QoS Type: auto (default)

```bash
az netappfiles pool create \
    --resource-group anfdemo-rg \
    --location japaneast \
    --account-name anfjpe \
    --pool-name pool1 \
    --size 4 \
    --service-level Standard
```

Note)</br>
容量プールの最大サイズ: 500 TiB</br>
ANFアカウントあたり作成可能な容量プールの数の上限値: 25TiB</br>

[GUI: Capacity Pool](images/create-pool.png)

## 9. ボリューム作成

- Volume name: **nfsvol1**
- NFS **4.1**
- Quota: **1024** GiB\
Note) It take around 4 minutes

```bash
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
```

Note)</br>
ボリュームサイズ最大値: 100 TiB</br>
容量プールあたり作成可能なボリュームの数の最大値: 500</br>

[GUI: Volume](images/create-volume.png)
[GUI: Set NFS 4.1](images/create-volume2.png)

## 10. ボリュームを VM にマウント

- Mount path: **/mnt/nfsvol1/**
- Follow **Mount Instruction**\
Note) NFS utilitiesのインストールが不要

1. Install NFS client: not necessary (already installed)
2. Change the path to /mnt: `cd /mnt`
3. Create a new directory to mount ANF volume: `mkdir nfsvol1`
4. Mount: `mount -t nfs -o rw,hard,rsize=1048576,wsize=1048576,sec=sys,vers=4.1,tcp 172.20.1.4:/nfsvol1 nfsvol1`

ボリュームのマウント状態を確認

- `df -h`
- `mount`: for the details

テストファイルを作成

- `cd /mnt/nfsvol1`
- `echo "this is a test file" > test.txt`

## 11.　ベンチマークツール fio インストール

fio - Flexible I/O tester is introduced on [Microsoft website](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-benchmarks#fio) as a tool to get maximum throughput.  

- Install fio: `zypper install -y fio`

## 12. fio でボリュームのスループットをリアルタイムに確認

<p>以下のコマンドを実行. </p>

`fio -rw=randwrite -bs=8k -size=2000m -numjobs=40 -runtime=600 -direct=1 -invalidate=1 -ioengine=libaio -iodepth=32 -iodepth_batch=32 -group_reporting -name=ANFThroughputTest`

## 13. ボリュームサイズを　2TiB　に変更

- Expected value: Thougthput to be changed to 32Mbps from 16Mbps
- See realtime change of throughput

```bash
az netappfiles volume update -g anfdemo-rg \
   --account-name anfjpe --pool-name pool1 \
   --name nfsvol1 --service-level Standard \
    --usage-threshold 2048
```

## 14. One-time スナップショット と volume-based 復元

- Create a test file named test.txt under /mnt/nfsvol1/ `echo "this is the test" > test.txt`
- Create one-time snapshot: *snapshot01*
- Create clone volume from the snapshot
- Revert
- Create one-time snapshot: *snapshot01*
Note) Max number of snapshot per volume is 255

```bash
az netappfiles snapshot create -g anfdemo-rg \
    --account-name anfjpe \
    --pool-name pool1 \
    --volume-name nfsvol1 \
    -l japaneast \
    --name snapshot01
```

## 15. スナップショット: file-based 復元

- `cd /mnt/nfsvol1/`
- `ls -la`
- `cd .snapshot`
- `ls -la`
- `cd snapshot01`
- Restore test.txt as `test2.txt: cp test.txt ../../test2.txt`
- Verify: `cd ../../` and `cat test2.txt`

## 16. スナップショット ポリシー

- Snapshot policy name:  **policy01**
- Number of snapshot to keep: **8**
- Hourly minute: current time

Note) Timezone is UTC.  Japan Standard time is UTC +9

```bash
az netappfiles snapshot policy create -g anfdemo-rg \
    --account-name anfjpe \
    --snapshot-policy-name policy01 \
    -l japaneast \
    --hourly-snapshots 8 \
    --hourly-minute 59 \
    --enabled true
```

## 17. QoS 種類を自動から手動に変更

```bash
az netappfiles pool update -g anfdemo-rg \
    --account-name anfjpe --name pool1 \
    --qos-type Manual
```

And change throughput manually to 50Mbps

```bash
az netappfiles volume update -g anfdemo-rg \
    --account-name anfjpe --pool-name pool1 \
    --name nfsvol1 --service-level standard \
    --throughput-mibps 50
```

## 18. 容量プールのサイズを増やし、ボリュームのスループットを増やす

容量プールのサイズを 6 TiB　に拡張

```bash
az netappfiles pool update -g anfdemo-rg \
    --account-name anfjpe \
    --name pool1 \
    --size 6
```

ボリュームスループットを 80Mbps　に変更

```bash
az netappfiles volume update -g anfdemo-rg \
    --account-name anfjpe --pool-name pool1 \
    --name nfsvol1 --service-level standard \
    --throughput-mibps 80
```

## 19. サービスレベルを変更

- Premiumサービスレベルの4TB容量プール **pool2** を作成
- ボリュームをそプール **pool2** に移動
- pool1を削除

```bash
az netappfiles pool create \
    --resource-group anfdemo-rg \
    --location japaneast \
    --account-name anfjpe \
    --pool-name pool2 \
    --size 4 \
    --qos-type Manual \
    --service-level Premium
```

ボリューム移動完了後、pool1を削除</br>
`az netappfiles pool delete -g anfdemo-rg -a anfjpe -n pool1`

## 20. クロスリージョンレプリケーション

### 操作はGUIで実施する予定

[View Cross Region Replication diagram](https://github.com/maysay1999/anfdemo02/blob/main/220107_crr_diagram.pdf)\
[CRR tier and price](https://azure.microsoft.com/en-us/pricing/details/netapp/)

<div style="text-align: left"><img src="/images/Handson_crr_diagram.png" ></div>
<br>

1. Download japanwest-create.sh  `git clone https://github.com/maysay1999/anfdemo02.git AnfHandson`
2. Change permision to execute the shell `chmod 711 japanwest-create.sh`
3. Excute `./japanwest-create.sh`
The shell will create new Vnet, subnets, netapp account and capacity pool in Japan West region. \
Japan West VNet: **anfjpw-vnet**\
Address space:  **172.21.0.0/16**\
Location: **Japan West**(pair region)\
Subnet #1: **vm-sub**.  172.21.0.0/24\
Subnet #2: **anf-sub**.  172.21.1.0/26\
ANF netapp account: **anfjpw** (location: Japan West)\
Capacity pool name: **pooldr** (4TiB, Standard)

- Replication volume name: **voldr** (througput 16Mbps)
- Replication frequency: **every 1 hour**

## 21. ハンズオンの環境の削除
- ボリュームvoldrの「レプリケーション」メニューにて、「ピアリンクの中断」をクリックし、レプリケーションを停止させます
- ボリュームvoldrの「レプリケーション」メニューにて、「削除」をクリックし、レプリケーション関係を削除
- ボリューム voldr、容量プール pooldr、ANF アカウント anfjpw を削除
- ボリューム nfsvol1、 容量プール pool2、 ANF アカウント anfjpe を削除
- リソースグループ anfdemo-rg にある他リソースを全部削除


Reference
- [Price of Cross Region Replication](https://azure.microsoft.com/en-us/pricing/details/netapp/)</br>
[Price of Cross Region Replication (Japanese)](https://azure.microsoft.com/ja-jp/pricing/details/netapp/)
- [Limitatoin of ANF](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-resource-limits)</br>
[Limitatoin of ANF (Japanese)](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-resource-limits)
- [Delete volume replications or volumes](https://docs.microsoft.com/en-us/azure/azure-netapp-files/cross-region-replication-delete)

---