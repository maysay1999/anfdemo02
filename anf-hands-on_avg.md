# Azure NetApp Files ハンズオン Applicatioin Volume Group 編 for SAP HANA

## ダイアグラム

![AVG diagram](https://github.com/maysay1999/anfdemo02/blob/main/images/anf-avg_diagram.png)

## 事前準備

[こちらのサイト](https://forms.office.com/pages/responsepage.aspx?id=v4j5cvGGr0GRqy180BHbR2Qj2eZL0mZPv1iKUrDGvc9UQzBDRUREOTc4MDdWREZaRzhOQzZGNTdFQiQlQCN0PWcu)から waitlist に登録

## 1. リソースグループ作成

* パラメータ
  * Resource Group name: **anfdemolab-rg**
  * Location: **Japan East**

> **コマンド**:  AZ CLI で実行した場合

  ```bash
  az group create -n anfdemolab-rg -l japaneast
  ```

## 2. Shell を実行して、PPG(proximity placement group), Availability Set, SLES を作成

* shell をダウンロード

  ```git
  cd ~/
  git clone https://github.com/maysay1999/anfdemo02.git AnfCrr
  ```

* パスワードをいれる

  ```git
  cd AnfCrr
  vim avsetppg-create.sh
  ```

* 実行

  ```git
  ./avsetppg-create.sh
  ```

* 豆知識
  * ANF は Mシリーズ と物理的に近いため、Mシリーズを選ぶと更にlatencyを短くできる  
  [M シリーズ](https://docs.microsoft.com/ja-jp/azure/virtual-machines/m-series)  
  [参考サイト](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-considerations.md)

## 3. ANF subnet アカウント 容量プールを作成

* ANF subnet パラメータ  
  * ANF subnet name: anf-sub  
  * ANF subnet: 172.28.80.0/26  
  * ANF delegation: Microsoft.Netapp/volumes  

* ANFアカウント パラメータ  
  * NetApp Account: **anfjpe**  
  * Location: **Japan East**  

* 容量プール パラメータ  
  * Capacity pool name: **cp-hana**  
  * Service level: **Ultra**  
  * Size: **10** TiB  
  * QoS size: **Manual**  

## 4. Application Volume Groups

  1. Add Group
     * Deployment type: SAP-HANA  

  2. Create a volume group  
     * SAP ID: TST  
     * SAP node memory (GB): 128  
     * Capacity overhead %: 10  

  3. Create a volume group (continue)  
     * Proximity placement group: ppg-japaneast  
     * Virtual network: anfjpe-vnet  
     * Subnet: anf-sub  

## 5. 完成したらこちらに登録

  [SAP HANA VM Pinning Requirements Form](https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbRxjSlHBUxkJBjmARn57skvdUQlJaV0ZBOE1PUkhOVk40WjZZQVJXRzI2RC4u)  

## 推奨コンテンツ

[Understand Azure NetApp Files application volume group for SAP HANA](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-introduction.md)  
[Requirements and considerations for application volume group for SAP HANA](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-introduction.md)  
[Add volumes for an SAP HANA system as a secondary database in HSR](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-add-volume-secondary.md)  
[Add volumes for an SAP HANA system as a DR system using cross-region replication](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-disaster-recovery.md)  
[Deploy the first SAP HANA host using application volume group for SAP HANA](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-deploy-first-host.md)  
[Add hosts to a multiple-host SAP HANA system using application volume group for SAP HANA](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-add-hosts.md)  
[Manage volumes in an application volume group](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-manage-volumes.md)  
[Delete an application volume group](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-netapp-files/application-volume-group-delete.md)  
