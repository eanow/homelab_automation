#!/bin/bash
source $(dirname "$0")/vault_info.sh
#create keyfile
echo $1 > $KEYFILE
#open luks
cryptsetup luksOpen $CRYPTO_IMG $LUKS_DEVICE --key-file $KEYFILE
#mount vault
mount /dev/mapper/$LUKS_DEVICE $VAULT_FOLDER
#remove keyfile
rm $KEYFILE
#report
if df -h | grep -q CryptoVault
then
	echo "Vault is open"
else
        echo "Something went wrong"
fi
