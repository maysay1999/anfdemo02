# Azure NetApp Files ハンズオン NFS 編 スタンダード

## 事前準備

* [こちら](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_prep.md)が事前に必要な作業となります
* こちらの[事前準備サイト](https://github.com/maysay1999/tipstricks/blob/main/anf-demo-creation.md)をご参照に自動ラボ作成スクリプトを実行下さい

## ダイアグラム

![diagram](https://github.com/maysay1999/anfdemo02/blob/main/images//anf-nfs-diagram.png)

> **Note**:  ダイアグラムのダウンロードは[こちら](https://github.com/maysay1999/anfdemo02/blob/main/pdfs/220319_hands-on_diagram_nfs.pdf)から

## 1. リソースグループ作成

* パラメータ
  * Resource Group name: **anfdemolab-rg**
  * Location: **Japan East**

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az group create -n anfdemolab-rg -l japaneast
  ```

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 2. 仮想ネットワーク anfjpe-vnet　作成

* パラメータ
  * VNet name: **anfjpe-vnet**  
  * Location: **Japan East**  
  * Address Space: **172.28.80.0/22**  
  * Subnet name: **vm-sub**  
  * Subnet: **172.28.81.0/24**  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az network vnet create -g anfdemolab-rg -n anfjpe-vnet \
      --address-prefix 172.28.80.0/22 \
      --subnet-name vm-sub --subnet-prefix 172.28.81.0/24
  ```

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 3.  ANF サブネット作成

* パラメータ
  * ANF subnet name: **anf-sub**  
  * ANF subnet: **172.28.80.0/26**  
  * ANF delegation: **Microsoft.Netapp/volumes**  

  ![subnet](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-nfs-subnet.png)

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az network vnet subnet create \
      --resource-group anfdemolab-rg \
      --vnet-name anfjpe-vnet \
      --name anf-sub \
      --delegations "Microsoft.NetApp/volumes" \
      --address-prefixes 172.28.80.0/26
  ```

> **ノート**:  ANF用のサブネットは /26 を推奨 (/28, /26, /24 が推奨値)

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
  * Subnet: **vm-sub**
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
      --resource-group anfdemolab-rg \
      --name AzureBastionSubnet \
      --vnet-name anfjpe-vnet \
      --address-prefixes 172.28.82.0/26

  az network public-ip create --resource-group anfdemolab-rg \
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
      -g anfdemolab-rg \
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
      --resource-group anfdemolab-rg \
      --location japaneast \
      --account-name anfjpe \
      --pool-name pool1 \
      --size 4 \
      --service-level Standard
  ```

* 豆知識  
  * 容量プールの最大サイズ: 500 TiB  
  * ANFアカウントあたり作成可能な容量プールの数の上限値: 25個  

## 9. ボリューム作成

* パラメータ
  * Volume 名: **nfsvol1**
  * NFS バージョン **3**
  * クオータ: **1024** GiB

  Note) デプロイに約 4 分

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles volume create \
      --resource-group anfdemolab-rg \
      --location japaneast \
      --account-name anfjpe \
      --pool-name pool1 \
      --name nfsvol1 \
      --service-level Standard \
      --vnet anfjpe-vnet \
      --subnet vm-sub \
      --usage-threshold 1024 \
      --file-path nfsvol1 \
      --allowed-clients 0.0.0.0/0 \
      --rule-index 1 \
      --protocol-types NFSv3 \
      --unix-read-write true
  ```

* 豆知識  
  * ボリュームサイズ最大値: 100 TiB  
  * 容量プールあたり作成可能なボリュームの数の最大値: 500  

## 10. ボリュームを VM にマウント

* パラメータ
  * マウントパス: **/mnt/nfsvol1/**
  * **Mount Instruction** の指示通りに設定

* 手順  
  1. NFS client をインストール  
  2. ディレクトリを変更`cd /mnt`  
  3. 新しくディレクトリを作成 `mkdir nfsvol1`  
  4. マウントする: `mount -t nfs -o rw,hard,rsize=1048576,wsize=1048576,sec=sys,vers=4.1,tcp 172.20.1.4:/nfsvol1 nfsvol1`

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

* fio - Flexible I/O テスター は [Microsoft website](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-benchmarks#fio) サイトでも紹介されているベンチマークツールです

* fio をインストールする
  
  ```bash
  apt update
  apt install -y fio
  ```

## 12. fio でボリュームのスループットをリアルタイムに確認

* 以下のコマンドを実行

  ```bash
  fio -rw=randwrite -bs=8k -size=2000m -numjobs=40 -runtime=600 -direct=1 -invalidate=1 -ioengine=libaio -iodepth=32 -iodepth_batch=32 -group_reporting -name=ANFThroughputTest
  ```

## 13. ボリュームサイズを　2TiB　に変更

* 予測値  
  * スループットが 16Mbpsから 32Mbps になる  
  * ダウンタイムが発生しない  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles volume update -g anfdemolab-rg \
     --account-name anfjpe --pool-name pool1 \
     --name nfsvol1 --service-level Standard \
      --usage-threshold 2048
  ```

## 14. One-time スナップショット と volume-based 復元

* GUI にて実行  
  1. test.txt という名のテストファイルを作成  
  2. *snapshot01*  の名でスナップショットを作成
  3. スナップショットからクローンを作成
  4. 復元してみる (optional)

  ```bash
    cd /mnt/nfsvol1/ 
    echo "this is the test" > test.txt"
  ```

* 豆知識
  * 保存できる snapshot の最大値は 255

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles snapshot create -g anfdemolab-rg \
      --account-name anfjpe \
      --pool-name pool1 \
      --volume-name nfsvol1 \
      -l japaneast \
      --name snapshot01
  ```

## 15. スナップショット: file-based 復元

* 手順  
  1. `cd /mnt/nfsvol1/`
  2. `ls -la`
  3. `cd .snapshot`
  4. `ls -la`
  5. `cd snapshot01`
  6. ファイル test.txt をリストアしてみる  `test2.txt: cp test.txt ../../test2.txt`

## 16. スナップショット ポリシー

* パラメータ  
  * スナップショットポリシー名:  **policy01**
  * 保存するスナップショットの数: **8**
  * 毎時何分に実行: (好みの時間)

* 豆知識
  * タイムゾーンは UTC で表記されているので、+9 する必要あり

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles snapshot policy create -g anfdemolab-rg \
      --account-name anfjpe \
      --snapshot-policy-name policy01 \
      -l japaneast \
      --hourly-snapshots 8 \
      --hourly-minute 59 \
      --enabled true
  ```

## 17. QoS 種類を自動から手動に変更

* 手順  
  1. 容量プールでQoS 種類を自動から手動に変更
  2. スループットを50M/sec に変更

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles pool update -g anfdemolab-rg \
      --account-name anfjpe --name pool1 \
      --qos-type Manual
  ```

  スループットを50M/sec に変更
  
  ```bash
  az netappfiles volume update -g anfdemolab-rg \
      --account-name anfjpe --pool-name pool1 \
      --name nfsvol1 --service-level standard \
      --throughput-mibps 50
  ```

## 18. 容量プールのサイズを増やし、ボリュームのスループットを増やす

* 手順  
  1. 容量プールのサイズを 6 TiB　に拡張  
  2. スループットを50M/sec に変更  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles pool update -g anfdemolab-rg \
      --account-name anfjpe \
      --name pool1 \
      --size 6
  ```

  ボリュームスループットを 80M/sec　に変更  

  ```bash
    az netappfiles volume update -g anfdemolab-rg \
      --account-name anfjpe --pool-name pool1 \
      --name nfsvol1 --service-level standard \
      --throughput-mibps 80
  ```

## 19. サービスレベルを変更

* 手順  
  1. Premiumサービスレベルの4TB容量プール **pool2** を作成  
  2. ボリュームをそプール **pool2** に移動  
  3. pool1を削除  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles pool create \
      --resource-group anfdemolab-rg \
      --location japaneast \
      --account-name anfjpe \
      --pool-name pool2 \
      --size 4 \
      --qos-type Manual \
      --service-level Premium
  ```

  ボリューム移動完了後、pool1を削除  

  ```bash
  az netappfiles pool delete -g anfdemolab-rg -a anfjpe -n pool1
  ```
  