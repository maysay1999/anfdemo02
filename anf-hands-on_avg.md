# Azure NetApp Files ハンズオン Applicatioin Volume Group 編 for SAP HANA

## ダイアグラム

![diagram](https://github.com/maysay1999/anfdemo02/blob/main/images//anf-nfs-diagram.png)

> **Note**:  ダイアグラムのダウンロードは[こちら](https://github.com/maysay1999/anfdemo02/blob/main/pdfs/220319_hands-on_diagram_nfs.pdf)から

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

## 2. Shell を実行して、PPG(proximity placement group), Availability Set を作成

* shell をダウンロード

  ```git
  cd ~/
  git clone https://github.com/maysay1999/anfdemo02.git AnfCrr
  ```

* パスワードをいれる

  ```git
  cd AnfCrr
  code avsetppg-create.sh
  ```

* 実行

  ```git
  ./avsetppg-create.sh
  ```

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

