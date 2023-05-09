#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 --root-token hvs.IFBdcPOBMV3YvzxavGacBtzk"
    exit 1
fi

if [ "$1" != "--root-token" ]; then
  echo "Usage: $0 --root-token hvs.IFBdcPOBMV3YvzxavGacBtzk"
    exit 1
fi

export VAULT_ADDR="http://test-vault.com/"
export VAULT_TOKEN=$2

vault operator unseal 
echo -e "\n"
vault operator unseal 
echo -e "\n"
vault operator unseal

