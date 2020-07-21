#!/bin/bash
source $(dirname "$0")/vault_info.sh
if df -h | grep -q CryptoVault
then
	echo "Vault is open"
else
	echo "Vault is closed"
fi
