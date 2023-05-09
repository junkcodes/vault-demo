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

# Saving policy rules for credentials
echo -e "Saving policy rules for credentials\n\n"

cat <<EOF > $(dirname -- "$0";)/exampledb-pg-role-policy.hcl
path "database/creds/exampledb-pg" {
  capabilities = [ "read" ]
}
EOF
echo -e "Saved"

# Writing to vault policy with policy rules.
echo -e "\nWriting to vault policy with policy rules\n\n"

vault policy write exampledb-pg-policy $(dirname -- "$0";)/exampledb-pg-role-policy.hcl


# Generating & Saving Token for the vault policy
echo -e "\nGenerating & Saving Token for the vault policy\n\n"

vault token create -policy="exampledb-pg-policy" >> $(dirname -- "$0";)/exampledb-pg-policy-token.txt
echo -e "\n\n" >> $(dirname -- "$0";)/exampledb-pg-policy-token.txt
echo -e "Saved"
