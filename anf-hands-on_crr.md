# Azure NetApp Files ハンズオン クロスリージョンレプリケーション 編

クロスリージョンレプリケーション は Azure NetApp Files ボリューム (ソース) から別の別の Azure NetApp Files ボリューム (宛先) にデータを非同期的にレプリケートする機能です。ソース ボリュームと宛先ボリュームは別々のリージョンにデプロイする必要があります

## 事前準備

* レプリケート先のリージョンを選択。リージョン ペアは[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/cross-region-replication-introduction#azure-regional-pairs)をご覧ください
* その他は、こちらの[事前準備サイト](https://github.com/maysay1999/tipstricks/blob/main/anf-demo-creation.md)をご参照下さい

## ダイアグラム

![diagram](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-diagram.png)

> **Note**:  ダイアグラムのダウンロードは[こちら](https://github.com/maysay1999/anfdemo02/blob/main/pdfs/220606_hands-on_diagram_crr.pdf)から

## 料金

* [こちら](https://azure.microsoft.com/ja-jp/pricing/details/netapp/)をご参照下さい

* 要点  
  * ネットワークの知識なしで約20分でDRの設定可能  
  * 価格は single と比較して約2倍強
  * VPN などの設定・保守費用は一切不要  

## 1. japanwest-create.sh をダウンロードする

* Cloud Shell の画面でダウンロード

  ```git
  cd ~/
  git clone https://github.com/maysay1999/anfdemo02.git AnfCrr
  ```

## 2. ダウンロードしたシェルを実行する

* Cloud Shell

  ```bash
   ~/AnfCrr/japanwest-create.sh
  ```

* このshellを実行することで、西日本にこちらのリソースが自動作成されます
  * Japneast にソースボリューム: anfjpe/pool1/source-volume  
  * Japnwest の VNet: **anfjpw-vnet**  
  * Japnwest の Address space:  **172.29.80.0/22**  
  * Japnwest の Subnet #1: **vm-sub**.  172.29.81.0/24  
  * Japnwest の Subnet #2: **anf-sub**.  172.29.80.0/26  
  * Japnwest の ANF netapp account: **anfjpw**  
  * Japnwest の Capacity pool name: **pooldr** (QoS: Manual)  

## 3. レプリケーション ボリュームを作成

* 通常のボリュームではなく、**レプリケーション ボリューム**を作成する

* パラメータ
  * Replication volume name: **destination-volume**  
  * Throughput: **16Mbps**(QoSをmanualで設定しているため、設定する必要あり)  
  * Replication frequency: **daily**  
  * Source volume ID: `az netappfiles volume show -g anfdemolab-rg --account-name anfjpe --pool-name pool1 --name source-volume  --query id -o tsv`  

* 手順  
  1. Capital Pool (pooldr) --> Volumes --> **Add data replication**を選択  
     ![Add data replication](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-replication_volume.png)  
  2. Create a new protection volume --> Basics  
     ![protection volume Basics](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-replication_volume2.png)  
  3. Create a new protection volume --> Protocol  
     ![protection volume Protocol](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-replication_volume3.png)  
  4. Create a new protection volume --> Replication
    ![protection volume Replication](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-replication_volume4.png)  

> **ノート**:  ソースボリュームIDは Pool (pool1) --> volume (source-volume) --> properties から取得  

   ![resource of source volume](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-volumeid_src.png)  
  
  あるいはこのコマンド  

  ```bash
  az netappfiles volume show -g anfdemolab-rg \
  --account-name anfjpe --pool-name pool1 \
  --name source-volume  --query id -o tsv
  ```

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az netappfiles volume create --resource-group anfdemolab-rg \
  --account-name anfjpw \
  --file-path destination-volume \
  --pool-name pooldr \
  --name destination-volume \
  --location japanwest \
  --service-level Standard \
  --usage-threshold 100 \
  --vnet anfjpw-vnet \
  --subnet anf-sub \
  --protocol-types NFSv3 \
  --endpoint-type "dst" \
  --remote-volume-resource-id $(az netappfiles volume show -g anfdemolab-rg --account-name anfjpe --pool-name pool1 --name source-volume  --query id -o tsv) \
  --replication-schedule "daily" \
  --volume-type "DataProtection"
  ```

## 4. ディスティネーションボリューム (destination-volume) のリソースID を ソースボリューム (source-volume)に貼り付ける

* 手順  
  1. ディスティネーションボリューム (destination-volume) のリソースID をコピー  
     ボリューム --> source-volume --> プロパティ --> リソースID
     ![resource of destination volume](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-volumeid_dst.png)  
      あるいはこのコマンド

  ```bash
  az netappfiles volume show -g anfdemolab-rg \
  --account-name anfjpw --pool-name pooldr \
  --name destination-volume  --query id -o tsv
  ```

  2. コピーを取った1の値を、Pool (pool1) --> volume (source-volume) --> Replication に貼る  
    あるいはこのコマンド

  ```bash
  az netappfiles volume replication approve --account-name anfjpe \
  --name source-volume \
  --pool-name pool1 \
  --remote-volume-resource-id $(az netappfiles volume show -g anfdemolab-rg --account-name anfjpw --pool-name pooldr --name destination-volume  --query id -o tsv) \
  --resource-group anfdemolab-rg
  ```

## 5. Mirror state が "Mirrored" になれば完成

  ![Mirrored](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-mirrored.png)  

## 6. Replication の中断

* "Break peering" をクリック

  ![Break peering](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-suspend.png)  

> **コマンド**:  AZ CLI で Replication の中断を実行した場合

  ```bash
  az netappfiles volume replication suspend \
  -g anfdemolab-rg \
  --account-name anfjpw \
  --pool-name pooldr \
  --name destination-volume
  ```

## Reference

* [クロスリージョンレプリケーションの価格](https://azure.microsoft.com/ja-jp/pricing/details/netapp/)
* [ANFの制限事項](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-resource-limits)

## 推奨コンテンツ

* [リージョン間レプリケーションを使用するための要件と考慮事項](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/cross-region-replication-requirements-considerations)

## 次のステップ

* [Azure NetApp Files ハンズオン Backup 編](https://github.com/maysay1999/tipstricks/blob/main/anf-backup.md)

* [Azure NetApp Files ハンズオン Azure Kubenertes Service 編](https://github.com/maysay1999/anfdemo01/blob/main/README.md)

* [Azure NetApp Files ハンズオン dual-ptotocol 編](https://github.com/maysay1999/tipstricks/blob/main/anf-dual-protocol.md)