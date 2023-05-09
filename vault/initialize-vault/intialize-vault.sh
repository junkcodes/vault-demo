#!/bin/bash

export VAULT_ADDR="http://test-vault.com/"

output=$(vault operator init)
echo "${output}"
echo "${output}" >> $(dirname -- "$0";)/vault_keys.txt
echo -e "\n\n" >> $(dirname -- "$0";)/vault_keys.txt
