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
* ANFでボリューム作成後は仮想サーバにマウントし、fioにて性能を確認します。さらに、業務利用でより高いスループットが必要となったことを想定し、ボリュームサイズを変更します  

## ANF のストレージ階層

![storage hierarchy](https://docs.microsoft.com/ja-jp/azure/media/azure-netapp-files/azure-netapp-files-storage-hierarchy.png)

## ANF のユースケース

[ANF のユースケース](https://cloud.netapp.com/hubfs/Solution-Templates/ANF_Solution%20Brief_v3_Final.pdf)は[こちら](https://cloud.netapp.com/hubfs/Solution-Templates/ANF_Solution%20Brief_v3_Final.pdf)からダウングレードできます(英語版)

主な用途は  

* **SAP**  設定方法等詳細は[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-solution-architectures#sap-hana)
* **HPC**  設定方法等詳細は[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-solution-architectures#hpc-solutions)
* **VDI**  設定方法等詳細は[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-solution-architectures#virtual-desktop-infrastructure-solutions)
* **Azure VMware Solutions**  設定方法等詳細は[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-solution-architectures#azure-vmware-solutions)
* **Oracle**  設定方法等詳細は[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-solution-architectures#oracle)
* **kubernetes(DevOps)**  設定方法等詳細は[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-solution-architectures#azure-platform-services-solutions)
* **File share**  設定方法等詳細は[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-solution-architectures#file-sharing-and-global-file-caching)

## ダイアグラム

![diagram](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-diagram.png)

> **Note**:  ダイアグラムのダウンロードは[こちら](https://github.com/maysay1999/anfdemo02/blob/main/pdfs/220316_hands-on_diagram_smb.pdf)から

## ANF の用語

* [NetApp アカウント](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-understand-storage-hierarchy#azure_netapp_files_account): 構成容量プールの管理グループ  
* [容量プール](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-understand-storage-hierarchy#capacity_pools): NetApp アカウントの配下にあるボリュームの管理グループ  
* [ボリューム](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-understand-storage-hierarchy#volumes): NFS (NFSv3 または NFSv4.1)、SMB3、またはデュアル プロトコル (NFSv3 と SMB、または NFSv4.1 と SMB)を対応  
* [QoS](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-understand-storage-hierarchy#qos_types): QoS の種類は容量プールの属性です。 Azure NetApp Files では、"自動 (既定)" と "手動" の 2 種類の QoS 容量プールが提供されます  

## ここからハンズオンセッションを始めます。CLIの記載もありますが、GUIでの作業を推奨します 既に[ラボ環境](https://github.com/maysay1999/tipstricks/blob/main/anf-demo-creation.md)を作成済みの方は、[手順5](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_windows.md#5-bastion%E3%81%A7-windows-10-%E3%81%AB%E3%83%AD%E3%82%B0%E3%82%A4%E3%83%B3)から始めてください

[CLI(Azure Cloud Shell)](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview)の使い方は[こちら](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview)をご参照下さい

## 1. リソースグループ作成

* パラメータ
  * リソースグループ名: **anfdemolab-rg**
  * ロケーション: **Japan East**

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az group create -n anfdemolab-rg -l japaneast
  ```

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 2. 仮想ネットワーク anfjpe-vnet　作成

* パラメータ
  * 仮想ネットワーク名: **anfjpe-vnet**  
  * ロケーション: **Japan East**  
  * アドレス空間: **172.28.80.0/22**  
  * サブネット名: **vm-sub**  
  * サブネットのCIDR: **172.28.81.0/24**  

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az network vnet create -g anfdemolab-rg -n anfjpe-vnet \
      --address-prefix 172.28.80.0/22 \
      --subnet-name vm-sub --subnet-prefix 172.28.81.0/24
  ```

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 3. Peering で Domain Controller がある VNet と繋ぐ

* パラメータ
  * Peering link name: **Anf-to-Ad**
  * Peering link name: **Ad-to-Anf**
  * Virtual network: *{対応先}*

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 4. Windows VM作成

* パラメータ
  * VM名: **Win10-01**
  * ロケーション: **Japan East**
  * イメージ: **Windows 10 Pro version 20H2 - Gen 2**
  * VMタイプ: **Standard_D2s_v4**
  * 認証タイプ: **Password**
  * ユーザー名: **anfadmin**
  * パスワード: ---- (12文字以上英数字)
  * OSディスクタイプ: **Premium SSD** (default)
  * 仮想ネットワーク: **anfjpe-vnet**
  * サブネット: **vm-sub**
  * パブリックIP: **None**

> **ノート**:  ラボ環境を作成済みの際はスキップ

## 4. Bastionを構成する (GUI作業)

ブラウザー上のAzure portal を使用して仮想マシンに接続するために、Azure Bastionをデプロイします  

* パラメータ
  * 名前: anfjpe-vnet-bastion
  * ティア: Standard
  * 仮想ネットワーク: anfjpe-vnet
  * 新しいパブリックIP名 : anfjpe-vnet-ip
  * パブリックIPのSKU: Standard

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

## 5. Bastionで Windows 10 にログイン

* Bastion で Windows 10 にログイン
  * ユーザー名: `anfadmin@azureisfun.local`
  * パスワード: main.tf につけたパスワード
  * 注意) Bastionでは **{ドメイン名}\\{ユーザ名}** は使用できない。  
    ドメインメンバーとしてログインするときは、**{ユーザ名}@{ドメイン名}**  

  ![bastion1](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-bastion.png)

> **ノート**:  ネットワークに関するポップアップがあれば、「はい」をクリックする  
  ![Windows popup](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-network.png)  

## 6.  ANF サブネット作成

* ANF サブネットは /26, /28, /24 を推奨 (通常時は /26を推奨)

* パラメータ
  * ANFサブネット名: **anf-sub**  
  * ANFサブネット: **172.28.80.0/26**  
  * ANF委任先: **Microsoft.Netapp/volumes**  

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

## 7. Azure NetApp Files アカウント作成

* Azure ポータルで "netapp" で検索すると、Azure NetApp Files のアイコンが現れます  
  ![anf icon](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-account.png)

* 次に NetAppアカウントを作成します  下記パラメータを記入し、「作成」をクリックします

  * パラメータ
    * ANF アカウント名: **anfjpe**  
    * ロケーション: **Japan East**  
    * リソースグループ: **anfdemolab-rg**

  ![anf acccount](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-nfs-anfaccount.png)

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles account create \
      -g anfdemolab-rg \
      --name anfjpe -l japaneast
  ```

## 8. 容量プールを作成

* 「プールの追加」をクリックして容量プールを新規作成

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

* 「アクティブディレクトリ接続」から参加をクリックし、参加させる

  * パラメータ  
    * プライマリDNS: **192.168.81.4**  
    * ドメイン名: **azureisfun.local**  
    * SNBサーバーprefix: **shared** (shared-XXXX の名前で SMBボリュームが作成される)  
    * ユーザー: **anfadmin**  
    * パスワード: 設定したパスワード  

  ![adds](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-ad.png)

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

> **ノート**:  今回はADDSを使う。仮に、**Azure ADDS** を使う場合は、**organizational unit** path を `OU=AADDC Computers` と設定

  ![aadds](https://github.com/MicrosoftDocs/azure-docs/raw/main/articles/media/azure-netapp-files/azure-netapp-files-org-unit-path.png)

## 10. ボリューム作成

* パラメータ
  * Volume 名: **smbvol1**
  * クオータ: **1024** GiB  
  * プロトコルタイプ: SMB  

  Note) デプロイに約 4 分

  ![volume](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-volume.png)

  ![volume2](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-volume2.png)

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
  * 作成されたボリュームの**マウントに関する指示** 上にマウント用のパスが記載される

  ![volume2](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-mount.png)

* 手順  
  1. This PC Map で右クリック Map Network Device... をクリック  
  2. Zドライブにマップ  
  3. Zドライブ上にtext.txtを作成

  ![z drive](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-zdrive.png)

## 12.　ベンチマークツール CrystalDiskMark インストール

* 手順  
  1. Microsoft Edge を開いて、`https://osdn.net/projects/crystaldiskmark/downloads/75540/CrystalDiskMark8_0_4.zip/`にアクセス  
  2. CrystalDiskMarkをダウンロード  
  3. Zドライブで展開

  ![z drive2](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-zdrive2.png)

## 13. CrystalDiskMark でボリュームのスループットを確認

* 手順  
  1. DiskMark64.exe を開く
  2. テスト回数: **3**, テストサイズ: **64MiB**, テストドライブ: **Z** に変更
  3. **SEQ1M** Q8T1 のみクリックして計測

  ![CrystalDiskMark](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-crystal.png)

## 14. ボリュームサイズを　2TiB　に変更

* 予測値  
  * スループットが 16Mbpsから 32Mbps になる  
  * ダウンタイムが発生しない  

* 手順  
  1. Volume --> Overview
  2. Quota (GiB):  2048 に変更

  ![Resize Volume](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-resizevolume.png)

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
     ![snapshot](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-snapshot.png)  
     ![snapshot 2](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-snapshot2.png)  
  7. snapshot 上で右クリックで、復元可能  
     ![restoration](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-restore.png)  

* 豆知識
  * 保存できる snapshot の最大値は 255

## 16. スナップショット: file-based 復元

* 手順 GUI にて実行  
  1. test.txtで右クリック、`Restore previous version` から復元可能  
     ![snapshot 3](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-snapshot3.png)  
  2. File Explorer で View をクリックし、Hidden items にティックをいれる。ここからも復元可能
     ![snapshot 4](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-snapshot4.png)  

## 17. スナップショット ポリシー

* パラメータ  
  * スナップショットポリシー名:  **policy02**
  * 保存するスナップショットの数: **8**
  * 毎時何分に実行: (好みの時間)

* 手順 GUI にて実行  
  1. NetApp Account --> Snapshot policies で Snapshot policy を作成
     ![snapshot policy creation](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-snapshotpolicy.png)  
  2. 1で作成した Snapshot policy を特定の volume にアサイン
     ![snapshot policy assignment](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-snapshotpolicy2.png)  

* 豆知識
  * タイムゾーンは UTC で表記されているので、+9 する必要あり

## 18. QoS 種類を自動から手動に変更

* 手順  
  1. 容量プールでQoS 種類を自動から手動に変更
     ![Change QoS](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-qos.png)  
  2. ボリュームのスループットを手動で 50M/sec に変更  
     ![Manually change throughput](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-throughput50.png)  

  スループットを50M/sec に変更
  
> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles volume update -g anfdemolab-rg \
      --account-name anfjpe --pool-name pool1 \
      --name smbvol1 --service-level standard \
      --throughput-mibps 50
  ```

## 19. 容量プールのサイズを増やし、ボリュームのスループットをさらに増やす

* 手順  
  1. 容量プールのサイズを 6 TiB　に拡張  
     ![Resize pool](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-resizepool.png)  
  2. スループットを80M/sec に変更  
     ![Manually change throughput](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-throughput80.png)  

> **コマンド**:  AZ CLI で実行した場合

  容量プールを 6TB に変更  

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

* 豆知識  
  * この作業をスケジュールで自動化することも可能

## 20. サービスレベルを変更し、ボリュームのスループットをまたさらに増やす

* 手順  
  1. Premiumサービスレベルの4TB容量プール **pool2** を作成  
     ![Create pool2](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-servicelevel.png)  
  2. ボリュームを容量プール **pool2** に移動  
     ![Move volume to pool2](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-smb-servicelevel2.png)  
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

## 次のステップ

* [Azure NetApp Files ハンズオン NFS 編 スタンダード](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_ubuntu.md)

* [Azure NetApp Files ハンズオン DR 編](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_crr.md)

## 推奨コンテンツ

[Azure NetApp Files のドキュメント](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/)サイト
