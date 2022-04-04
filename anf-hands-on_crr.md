# Azure NetApp Files ハンズオン クロスリージョンレプリケーション 編

クロスリージョンレプリケーション は Azure NetApp Files ボリューム (ソース) から別の別の Azure NetApp Files ボリューム (宛先) にデータを非同期的にレプリケートする機能です。ソース ボリュームと宛先ボリュームは別々のリージョンにデプロイする必要があります

## 事前準備

* レプリケート先のリージョンを選択。リージョン ペアは[こちら](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/cross-region-replication-introduction#azure-regional-pairs)をご覧ください
* その他は、こちらの[事前準備サイト](https://github.com/maysay1999/tipstricks/blob/main/anf-demo-creation.md)をご参照下さい

## ダイアグラム

![diagram](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-crr-diagram.png)

> **Note**:  ダイアグラムのダウンロードは[こちら](https://github.com/maysay1999/anfdemo02/blob/main/pdfs/220302_hands-on_diagram_crr.pdf)から

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

* こちらが自動作成されます
  * Japneast にソースボリューム: anfjpe/pool1/source-volume  
  * Japnwest の Vnet: **anfjpw-vnet**  
  * Japnwest の Address space:  **172.29.80.0/22**  
  * Japnwest の Subnet #1: **vm-sub**.  172.29.81.0/24  
  * Japnwest の Subnet #2: **anf-sub**.  172.29.80.0/26  
  * Japnwest の ANF netapp account: **anfjpw**  
  * Japnwest の Capacity pool name: **pooldr** (QoS: Manual)  

## 3. レプリケーション ボリュームを作成

* パラメータ
  * Replication volume name: **destination-volume**  
  * Througput: **16Mbps**  
  * Replication frequency: **hourly**  
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
  --replication-schedule "hourly" \
  --volume-type "DataProtection"
  ```

4. Azure NetApp Files ボリューム (ソース)のリソースID を Azure NetApp Files ボリューム (コピー先)に貼り付ける

5. Azure NetApp Files ボリューム (コピー先)のリソースID を Azure NetApp Files ボリューム (ソース)に貼り付ける

## ハンズオンの環境の削除手順  

1. ボリュームvoldrの「レプリケーション」メニューにて、「ピアリンクの中断」をクリックし、レプリケーションを停止させます  
2. ボリュームvoldrの「レプリケーション」メニューにて、「削除」をクリックし、レプリケーション関係を削除  
3. ボリューム voldr、容量プール pooldr、ANF アカウント anfjpw を削除  
4. ボリューム nfsvol1、 容量プール pool2、 ANF アカウント anfjpe を削除  
5. リソースグループ anfdemolab-rg にある他リソースを全部削除

## Reference

* [Price of Cross Region Replication](https://azure.microsoft.com/en-us/pricing/details/netapp/)
[Price of Cross Region Replication (Japanese)](https://azure.microsoft.com/ja-jp/pricing/details/netapp/)
* [Limitatoin of ANF](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-resource-limits)
[Limitatoin of ANF (Japanese)](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-resource-limits)
* [Delete volume replications or volumes](https://docs.microsoft.com/en-us/azure/azure-netapp-files/cross-region-replication-delete)

推奨コンテンツ
* [リージョン間レプリケーションを使用するための要件と考慮事項](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/cross-region-replication-requirements-considerations)
