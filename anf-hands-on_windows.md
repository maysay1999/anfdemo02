# Azure NetApp Files ハンズオン SMB 編

## 事前準備

* ADDS または AADDS (Windows 2019 など) を準備します。こちらの[自動作成スクリプト](https://github.com/maysay1999/tipstricks/blob/main/anf-demo-creation.md)をご利用下さい

## このハンズオンセッションの目的

* Azureポータルを使って、**[ANF](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/)アカウント**を作成できるようになる
* Azureポータルを使って、**[ANF](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/)容量プール**を作成できるようになる
* Azureポータルを使って、**Active Directory (ADDS / Azure ADDS)** の設定をできるようになる
* Azureポータルを使って、**SMBボリューム**を作成できるようになる
* Azureポータルを使って、**スナップショット**を作成できるようになる
* Azureポータルを使って、**スナップショットポリシー**（スナップショットバックアップスケジュール）を作成できるようになる
* 帯域が足りない場合、3つの方法で帯域を増やすことができることを理解する  
  **ボリュームサイズ**を大きくして帯域を増やす  
  **容量プールサイズ**を大きくして帯域を増やす  
  **サービスレベルを変更**して帯域を増やす  
  **QoS**の使い方をマスターする

## ANF のストレージ階層

![storage hierarchy](https://docs.microsoft.com/ja-jp/azure/media/azure-netapp-files/azure-netapp-files-storage-hierarchy.png)

## ダイアグラム

![diagram](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-diagram.png)

> **Note**:  ダイアグラムのダウンロードは[こちら](https://github.com/maysay1999/anfdemo02/blob/main/pdfs/220316_hands-on_diagram_smb.pdf)から

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

## 4. Peering で Domain Controller がある VNet と繋ぐ

* パラメータ
  * Peering link name: **Anf-to-Ad**
  * Peering link name: **Ad-to-Anf**
  * Virtual network: *{対応先}*

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 5. Windows VM作成

* パラメータ
  * Virtual machine name: **Win10-01**
  * Region: **Japan East**
  * Image: **Windows 10 Pro version 20H2 - Gen 2**
  * VM type: **Standard_D2s_v4**
  * Authentication type: **Password**
  * Username: **anfadmin**
  * Password: ---- (min length is 12)
  * OS disk type: **Premium SSD** (default)
  * VNet: **anfjpe-vnet**
  * Subnet: **vm-sub**
  * Public IP: **None**

> **ノート**:  ラボ環境を作成済みの際はスキップ

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

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 6. Bastionで Windows 10 にログイン

* Bastion で Windows 10 にログイン
  * ユーザー名: `anfadmin@azureisfun.local`
  * パスワード: main.tf につけたパスワード
  * 注意) Bastionでは **{ドメイン名}\\{ユーザ名}** は使用できない。  
    ドメインメンバーとしてログインするときは、**{ユーザ名}@{ドメイン名}**  

  ![bastion1](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-bastion.png)

## 7. Azure NetApp Files アカウント作成

* パラメータ
  * ANF アカウント名: **anfjpe**  
  * ロケーション: **Japan East**  

  ![anf acccount](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-nfs-anfaccount.png)

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

  ![pool](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-nfs-pool2.png)

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

## 9. Active Directory 接続

* パラメータ
  * ドメイン名: **azureisfun.local**
  * プライマリDNS: **192.168.81.4**
  * SNBサーバーprefix: **shared**
  * ユーザー: **anfadmin**
  * パスワード: {depends}

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles account ad add -g anfdemolab-rg \
  --name anfjpe \
  --username anfadmin \
  --password null \
  --smb-server-name shared \
  --dns 192.168.81.4 \
  --domain azureisfun.local
  ```

## 10. ボリューム作成

* パラメータ
  * Volume 名: **smbvol1**
  * クオータ: **1024** GiB  
  * プロトコルタイプ: SMB  

  Note) デプロイに約 4 分

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles volume create \
      --resource-group anfdemolab-rg \
      --location japaneast \
      --account-name anfjpe \
      --pool-name pool1 \
      --name smbvol1 \
      --service-level Standard \
      --vnet anfjpe-vnet \
      --subnet vm-sub \
      --usage-threshold 1024 \
      --file-path smbvol1 \
      --allowed-clients 0.0.0.0/0 \
      --rule-index 1 \
      --protocol-types CIFS \
      --unix-read-write true
  ```

* 豆知識  
  * ボリュームサイズ最大値: 100 TiB  
  * 容量プールあたり作成可能なボリュームの数の最大値: 500  

## 11. ボリュームを Windows10 VM にマップ

* パラメータ
  * **Mount Instruction** の指示通りに設定

* 手順  
  1. This PC Map で右クリック Map Network Device... をクリック  
  2. Zドライブにマップ

* テストファイルを作成  
  Zドライブ上にtext.txtを作成

## 12.　ベンチマークツール CrystalDiskMark インストール

* 手順  
  1. Microsoft Edge を開いて、`https://osdn.net/projects/crystaldiskmark/downloads/75540/CrystalDiskMark8_0_4.zip/`にアクセス  
  2. CrystalDiskMarkをダウンロード  
  3. Zドライブで展開
  4. DiskMark64.exe を Zドライブの直下にコピー

## 13. CrystalDiskMark でボリュームのスループットを確認

* 手順  
  1. DiskMark64.exe を開く
  2. テスト回数: **3**, テストサイズ: **64MiB**, テストドライブ: **Z** に変更
  3. **SEQ1M** Q8T1 のみクリックして計測

## 14. ボリュームサイズを　2TiB　に変更

* 予測値  
  * スループットが 16Mbpsから 32Mbps になる  
  * ダウンタイムが発生しない  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles volume update -g anfdemolab-rg \
     --account-name anfjpe --pool-name pool1 \
     --name smbvol1 --service-level Standard \
      --usage-threshold 2048
  ```

## 15. One-time スナップショット と volume-based 復元

* 手順 GUI にて実行  
  1. test.txt という名のテストファイルを作成  
  2. *snapshot01*  の名でスナップショットを作成  
  3. test.txtを開き内容を書き換える  
  4. *snapshot02*  の名でスナップショットを作成  
  5. test.txtを開き内容を書き換える  
  6. *snapshot03*  の名でスナップショットを作成  
  7. test.txtで右クリック、`Restore previous version` から復元可能  
  8. File Explorer で View をクリックし、Hidden items にティックをいれる。ここからも復元可能

* 豆知識
  * 保存できる snapshot の最大値は 255

## 16. スナップショット: file-based 復元

* 手順 GUI にて実行  
  1. test.txtで右クリック、`Restore previous version` から復元可能  
  2. File Explorer で View をクリックし、Hidden items にティックをいれる。ここからも復元可能

## 17. スナップショット ポリシー

* パラメータ  
  * スナップショットポリシー名:  **policy01**
  * 保存するスナップショットの数: **8**
  * 毎時何分に実行: (好みの時間)

* 豆知識
  * タイムゾーンは UTC で表記されているので、+9 する必要あり

## 18. QoS 種類を自動から手動に変更

* 手順  
  1. 容量プールでQoS 種類を自動から手動に変更
  2. スループットを50M/sec に変更

  スループットを50M/sec に変更
  
  ```bash
  az netappfiles volume update -g anfdemolab-rg \
      --account-name anfjpe --pool-name pool1 \
      --name smbvol1 --service-level standard \
      --throughput-mibps 50
  ```

## 19. 容量プールのサイズを増やし、ボリュームのスループットを増やす

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
      --name smbvol1 --service-level standard \
      --throughput-mibps 80
  ```

## 20. サービスレベルを変更

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
