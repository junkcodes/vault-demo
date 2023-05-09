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

# Writing database config to vault database secret engine
echo -e "Writing database config to vault database secret engine\n\n"

vault write database/config/exampledb-pg \
plugin_name=postgresql-database-plugin \
allowed_roles="exampledb-pg" \
connection_url="postgresql://{{username}}:{{password}}@postgres.intern-deploy-testing:5432/exampledb?sslmode=disable" \
username=exampledb \
password=exampledb

# Saving Postgres sql statements for creation statements
echo -e "\nSaving Postgres sql statements for creation statements\n\n"

cat <<EOF > $(dirname -- "$0";)/vault-postgres-creation.sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "{{name}}";
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public to "{{name}}";
EOF
echo -e "Saved"


# Writing vault role with creation statements
echo -e "\nWriting vault role with creation statements\n\n"

vault write database/roles/exampledb-pg \
db_name=exampledb-pg \
creation_statements=@$(dirname -- "$0";)/vault-postgres-creation.sql \
default_ttl="5m" \
max_ttl="24h"

