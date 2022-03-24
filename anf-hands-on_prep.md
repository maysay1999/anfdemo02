# Azure NetApp Files を使う前にやるべきこと

## 事前準備

## 1. [Cloud Shell](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview) を開き、下記のコマンドを実行（必須)

  ```bash
  az provider register --namespace Microsoft.NetApp
  ```

  > **何のため?**:  [NetApp リソース プロバイダーを登録する](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-register)コマンド

## 2. [Cloud Shell](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview) で ANF アカウントを作成してみる このコマンドを実行

  ```bash
  az group create -n test-rg -l japaneast
  az netappfiles account create -g test-rg -n anftest -l japaneast
  ```
  
  > **何のため?**:  ANFはすべての環境で動作するわけではないから　上記のコマンドでエラーがあれば、[Service Request](https://docs.microsoft.com/ja-jp/azure/azure-portal/supportability/how-to-create-azure-support-request) を起こす

* 問題がなければこちらのコマンドで削除

```bash
  az netappfiles account delete -g test-rg -n anftest
  az group delete -n test-rg
  ```

## 3. プレビューだが使いたい機能を使えるようにする

* おすすめはこちら Cloud Shellにコピーする

```bash
  az feature register --namespace Microsoft.NetApp --name ANFSharedAD
  az feature register --namespace Microsoft.NetApp --name ANFTierChange
  az feature register --namespace Microsoft.NetApp --name ANFUnixPermissions
  az feature register --namespace Microsoft.NetApp --name ANFChownMode
  ```

* [SMB CA](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/enable-continuous-availability-existing-smb) と [ANF Backup](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/backup-introduction) も有効にすることを推奨 こちらで登録する
  * SMB CA: [ここをクリック](https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR2Qj2eZL0mZPv1iKUrDGvc9UQUFTUjExUDA5VU5KMUY1RllSVjNEOUVTWCQlQCN0PWcu)
  * ANF Backup: : [ここをクリック](https://forms.office.com/pages/responsepage.aspx?id=v4j5cvGGr0GRqy180BHbR2Qj2eZL0mZPv1iKUrDGvc9UMkI3NUIxVkVEVkdJMko3WllQMVRNMTdEWSQlQCN0PWcu)

* プレビューの概要が知りたい場合は、このコマンドで推し量ることができる

  ```bash
  az feature list --namespace Microsoft.NetApp -o table
  ```

* 機能を外したい場合は、`az feature register` を `az feature unregister` に変えるだけ  
  例) ANFSharedAD を無効にしたい場合  

  ```bash
  az feature unregister --namespace Microsoft.NetApp --name ANFSharedAD
  ```
