# Azure NetApp Files ハンズオン プログラム

> こちらの手順を一通り終えれば、問題なく Azure NetApp Files を使いこなせるようになります

## [Azure NetApp Files ラボ環境作成と事前準備](https://github.com/maysay1999/tipstricks/blob/main/anf-demo-creation.md)

まずは laboratory の環境を作成します。コピペでの作業と20分弱の待ち時間です

## [Azure NetApp Files を使う前にやるべきこと](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_prep.md)

ANFを使うことができる環境であるのか確認したり、プレビューの機能をアクティベーションします

## [Azure NetApp Files ハンズオン NFS 編 スタンダード](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_ubuntu.md)

ANF で作成した NFS volume を Ubuntu にマウントします

## [Azure NetApp Files ハンズオン NFS 編 SAP向け](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_sles_rhel.md)

ANF で作成した NFS volume を SLES / RHEL にマウントします

## [Azure NetApp Files ハンズオン SMB 編](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_windows.md)

ANF で作成した NFS volume を Windows 10 にマウントします

## [Azure NetApp Files ハンズオン dual-ptotocol 編](https://github.com/maysay1999/tipstricks/blob/main/anf-dual-protocol.md)

ANF で作成した NFS volume を Ubuntu と Windows 10 の両方からアクセスできるようにします

## [Azure NetApp Files ハンズオン DR 編](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_crr.md)

ANF で作成した NFS volume を リモートサイト に replicate します

## [Azure NetApp Files ハンズオン Backup 編](https://github.com/maysay1999/tipstricks/blob/main/anf-backup.md)

ANF Backup の使用方法を解説します

## [Azure NetApp Files ハンズオン Azure Kubenertes Service 編](https://github.com/maysay1999/anfdemo01/blob/main/README.md)

ANF をコンテナの永続ボリュームとして使います

## [Azure NetApp Files ハンズオン Applicatioin Volume Group 編 for SAP HANA](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_avg.md)

SAP HANA を設定するにあたり、SAP HANA <--> ANF 間のlatency を最短化します

## Azure NetApp Files ハンズオン Standard Network編 (undercooked)

ANF Standard Network を使って複数の peering を経由した ANF volume を マウントします

## Azure NetApp Files ハンズオン RBAC編 (undercooked)

ANFアドミンユーザー、ANFリードオンリーユーザーをジョブ別で作成する方法を解説します

## [Azure NetApp Files ラボ環境 を削除する](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_termination.md)

事前準備で削除したラボ環境を削除する手順です
