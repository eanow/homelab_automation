#!/bin/bash
source $(dirname "$0")/vault_info.sh
#unmount vault
umount $VAULT_FOLDER
#close luks container
cryptsetup luksClose $LUKS_DEVICE
#remove keyfile
rm -f $KEYFILE
if df -h | grep -q CryptoVault
then
        echo "Something failed"
else
        echo "Vault is closed"
fi
