# Azure NetApp Files ラボ環境 を削除する

## 手順

## 1. レプリケーションを中断させる

* Azure Portal

DR宛先ボリューム --> レプリケーション --> 「ピアリンクの中断」 をクリック

> **CLI**:  AZ CLI で実行

  ```bash
  az netappfiles volume replication suspend \
  -g anfdemolab-rg \
  --account-name anfjpw \
  --pool-name pooldr \
  --name voldr
  ```

## 2. レプリケーション関係を削除

* Azure Portal

DR宛先ボリューム --> レプリケーション --> 「削除」 をクリック

> **CLI**:  AZ CLI で実行

  ```bash
  az netappfiles volume replication remove \
  -g anfdemolab-rg \
  --account-name anfjpw \
  --pool-name pooldr \
  --name voldr
  ```

## 3. リソースグループ anfdemolab-rg を削除

* Azure Portal

Resource Group --> anfdemolab-rg --> 削除

> **CLI**:  AZ CLI で実行

  ```bash
  az group delete -n anfdemolab-rg
  ```

> **ノート**  5分程度かかります

## 4. Cloud Shell のディレクトリを削除

> **CLI**:  AZ CLI で実行

  ```bash
  rm -rf  ~/AnfLaboCreate/ ~/AnfCrr/
  ```
