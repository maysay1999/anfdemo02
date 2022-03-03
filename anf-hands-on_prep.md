# 0Azure NetApp Files を使うになる前にやるべきこと

## 事前準備

1. [Cloud Shell](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview) を開き、下記のコマンドを実行（必須)

  ```bash
  az provider register --namespace Microsoft.NetApp
  ```

  > **何のため?**:  [NetApp リソース プロバイダーを登録する](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-register)コマンド

2. [Cloud Shell](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview) で ANF アカウントを作成してみる このコマンドを実行

  ```bash
  az group create -n anfdemo-rg -l japaneast
  az netappfiles account create -g anfdemo-rg -n anftest -l japaneast
  ```
  > **何のため?**:  ANFはすべての環境で動作するわけではないから　上記のコマンドでエラーがあれば、[Service Request を起こす](https://docs.microsoft.com/ja-jp/azure/azure-portal/supportability/how-to-create-azure-support-request)