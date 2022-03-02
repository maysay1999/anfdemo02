# Azure NetApp Files ハンズオン クロスリージョンレプリケーション 編

クロスリージョンレプリケーション は Azure NetApp Files ボリューム (ソース) から別の別の Azure NetApp Files ボリューム (宛先) にデータを非同期的にレプリケートする機能です。ソース ボリュームと宛先ボリュームは別々のリージョンにデプロイする必要があります

## 事前準備

* レプリケート先のリージョンを選択。[リージョン ペア](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/cross-region-replication-introduction#azure-regional-pairs)はこちらをご覧ください
* Azure NetApp Files ボリューム (ソース) はが既に作成されている必要があります

## ダイアグラム

![View Cross Region Replication diagram](https://github.com/maysay1999/anfdemo02/blob/main/images/220107_crr_diagram.jpg)

[CRR tier and price](https://azure.microsoft.com/en-us/pricing/details/netapp/)

![CRR jpeg]()

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