# Azure NetApp Files ハンズオン NFS 編 スタンダード

## 1. リソースグループ作成

* パラメータ
  * Resource Group name: **anfdemolab-rg**
  * Location: **Japan East**

  ```bash
  az group create -n anfdemolab-rg -l japaneast
  ```

## 2. 仮想ネットワーク anfjpe-vnet　作成

* パラメータ
  * VNet name: **anfjpe-vnet**  
  * Location: **Japan East**  
  * Address Space: **172.28.80.0/22**  
  * Subnet name: **vm-subnet**  
  * Subnet: **172.28.81.0/24**  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az network vnet create -g anfdemo-rg -n anfjpe-vnet \
      --address-prefix 172.28.80.0/22 \
      --subnet-name vm-subnet --subnet-prefix 172.28.81.0/24
  ```

## 3.  ANF サブネット作成

* パラメータ
  * ANF subnet name: **anf-subnet**  
  * ANF subnet: **172.28.80.0/26**  
  * ANF delegation: **Microsoft.Netapp/volumes**  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az network vnet subnet create \
      --resource-group anfdemo-rg \
      --vnet-name anfjpe-vnet \
      --name anf-subnet \
      --delegations "Microsoft.NetApp/volumes" \
      --address-prefixes 172.28.80.0/26
  ```

## 4. Ubuntu VM作成

* パラメータ
  * Virtual machine name: **ubuntu01**
  * Region: **Japan East**
  * Image: **Ububtu Server 20.04 LTS - Gen 2**
  * VM type: **Standard_D2s_v4**
  * Authentication type: **Password**
  * Username: **anfadmin**
  * Password: ---- (min length is 12)
  * OS disk type: **Premium SSD** (default)
  * VNet: **anfjpe-vnet**
  * Subnet: **client-sub**
  * Public IP: **None**

## 5. Bastionを構成する (GUI作業)

* パラメータ
  * Name: anfjpe-vnet-bastion
  * Tier: Standard
  * Virtual Network: anfjpe-vnet
  * New public IP name : anfjpe-vnet-ip
  * Public IP address SKU: Standard
  * Procedure: Execute these command lines and create bastion on GUI portal

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az network vnet subnet create \
      --resource-group anfdemo-rg \
      --name AzureBastionSubnet \
      --vnet-name anfjpe-vnet \
      --address-prefixes 172.28.82.0/26

  az network public-ip create --resource-group anfdemo-rg \
      --name anfjpe-vnet-ip \
      --sku Standard
  ```

## 6. Bastionで Ubuntu にログイン

Bastion で Ubuntu にログイン

* Root にてログイン
  * sudo su - または sudo -i を使う

  ```bash
   sudo -i
  ```

## 7. Azure NetApp Files アカウント作成

* パラメータ
  * ANF アカウント名: **anfjpe**  
  * ロケーション: **Japan East**  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles account create \
      -g anfdemo-rg \
      --name anfjpe -l japaneast
  ```

## 8. 容量プールを作成

* パラメータ
  * 容量プール: **pool1**
  * サービスレベル: **標準**
  * サイズ: 4TiB
  * QoS タイプ: auto (default)

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles pool create \
      --resource-group anfdemo-rg \
      --location japaneast \
      --account-name anfjpe \
      --pool-name pool1 \
      --size 4 \
      --service-level Standard
  ```

* Note  
  * 容量プールの最大サイズ: 500 TiB  
  * ANFアカウントあたり作成可能な容量プールの数の上限値: 25TiB  

## 9. ボリューム作成

* パラメータ
  * Volume name: **nfsvol1**
  * NFS **3**
  * Quota: **1024** GiB\

  Note) デプロイに約 4 分

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles volume create \
      --resource-group anfdemo-rg \
      --location japaneast \
      --account-name anfjpe \
      --pool-name pool1 \
      --name nfsvol1 \
      --service-level Standard \
      --vnet anfjpe-vnet \
      --subnet client-sub \
      --usage-threshold 1024 \
      --file-path nfsvol1 \
      --allowed-clients 0.0.0.0/0 \
      --rule-index 1 \
      --protocol-types NFSv3 \
      --unix-read-write true
  ```

* Note  
  * ボリュームサイズ最大値: 100 TiB  
  * 容量プールあたり作成可能なボリュームの数の最大値: 500  

## 10. ボリュームを VM にマウント

* パラメータ
  * Mount path: **/mnt/nfsvol1/**
  * Follow **Mount Instruction**

* 手順  
  1. Install NFS client
  2. Change the path to /mnt: `cd /mnt`
  3. Create a new directory to mount ANF volume: `mkdir nfsvol1`
  4. Mount: `mount -t nfs -o rw,hard,rsize=1048576,wsize=1048576,sec=sys,vers=4.1,tcp 172.20.1.4:/nfsvol1 nfsvol1`

* ボリュームのマウント状態を確認  
  `df -h` or `mount`

  ```bash
  df -h
  ```

* テストファイルを作成  

  ```bash
  cd /mnt/nfsvol1
  echo "this is a test file" > test.txt
  ```

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

### 操作はGUIで実施

[View Cross Region Replication diagram](https://github.com/maysay1999/anfdemo02/blob/main/220107_crr_diagram.pdf)\
[CRR tier and price](https://azure.microsoft.com/en-us/pricing/details/netapp/)

![CRR jpeg](https://github.com/maysay1999/anfdemo02/blob/main/images/220107_crr_diagram.jpg)

1. Download japanwest-create.sh  `git clone https://github.com/maysay1999/anfdemo02.git AnfHandson`
2. Excute `./japanwest-create.sh`
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


## Reference
- [Price of Cross Region Replication](https://azure.microsoft.com/en-us/pricing/details/netapp/)</br>
[Price of Cross Region Replication (Japanese)](https://azure.microsoft.com/ja-jp/pricing/details/netapp/)
- [Limitatoin of ANF](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-resource-limits)</br>
[Limitatoin of ANF (Japanese)](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-resource-limits)
- [Delete volume replications or volumes](https://docs.microsoft.com/en-us/azure/azure-netapp-files/cross-region-replication-delete)

---