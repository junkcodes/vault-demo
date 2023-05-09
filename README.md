# Vault HA : Dynamic Database Secrets with Policy Binding and Token Auth
Vault can generate secrets on-demand for some systems. For example, when an app needs to access a remote Database, it asks Vault for Database credentials. Vault will generate the credentials granting permissions to access the particuler Database in a particuler role on proper authentication. In addition, Vault will automatically revoke this credential after the time-to-live (TTL) expires. 
Here, for demonstration, the complete task is divided into following steps,
* Vault HA Deployment on K8S 
* Expose Vault with Ingress 
* Initialize / Unseal Vault
* Enable Database Secret Engine & Configure for Dynamic Credentials
* Create Policy & Token for Dynamic Credentials
* Access Database Credentials via API

## Vault Deployment on K8S:
Vault HA uses consul as Storage Backend. So, before deploying vault, Consul needs to be up and running on the kubernetes cluster. Follow the given link for deploying Consul on kubernetes, [Install Consul on Kubernetes with Helm](https://developer.hashicorp.com/consul/docs/k8s/installation/install).  
Additionally, Helm can be leveraged to configure and deploy Vault alongside Consul. To accomplish this, configure kubectl to point to the cluster where Vault will be deployed. Then, use the following command to deploy Vault using Helm and pass the necessary configuration values to the chart referred as [vault/deploy-k8s/values.yaml](vault/deploy-k8s/values.yaml),
```sh
$ helm install vault hashicorp/vault --values vault/vault-k8s/values.yml -n vault --create-namespace
NAME: vault
LAST DEPLOYED: Sun May  7 17:29:45 2023
NAMESPACE: vault
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault
```
Here, 
* [vault/vault-k8s/values.yml](vault/vault-k8s/values.yml) is used to pass configuration values to the hashicorp/vault chart as following <br>
```
server:
  affinity: ""
  ha:
    enabled: true
    replicas: 3
    config: |
      ui = true
      disable_mlock = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }

      backend "consul" {
        path = "vault/"
        address = "consul-server.consul:8500"
      }

```
> for "address = consul-server.consul:8500", consul-server is the service name of consul & consul is the namespace name, and the format is "sercvice-name.namespace-name:8500"

## Expose Vault with Ingress
To expose vault, Ingress needed to be installed and configured in Kubernetes.   
For Ingress installtion follow, [Ingress Installation with Helm](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/).

Run the following command to expose vault,
```sh
$ kubectl apply -f vault/vault-k8s/ingress.yml -n vault
ingress.networking.k8s.io/hello-kubernetes-ingress created
```
Here, the [vault/vault-k8s/ingress.yaml](vault/vault-k8s/ingress.yml) file contains the following,
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault-kubernetes-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: test-vault.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: vault
            port:
              number: 8200
```
> host, refers to the hostname pointing to the kubernetes.     
 
On successful execution, we can access vault from the following url : http://test-vault.com/

## Initialize / Unseal Vault
### Initialize Vault

To initialize vault, run the command as below,
```sh
$ bash vault/initialize-vault/intialize-vault.sh
Unseal Key 1: Fq2YbFYxp5GLf3KT+Mk06PNOJbu+bQMtoOcmuEqzNQLb
Unseal Key 2: lyxUm2SyYprBGmErsBgdbXeFACLMh5Dbix0D6gXz6Y3Q
Unseal Key 3: nx+oIlrQcZr9zEdJAjt5oZSH5JZLQKnecTP4wa3F2ZU1
Unseal Key 4: J9PxCKfrwSSWQyEnm76ya+QbBtVL4cYLJ4HtH4D1zN0m
Unseal Key 5: AJK1T7+WO6N2LybElbpiliazRj32z1yjd+yBZdZPKQC9

Initial Root Token: hvs.IFBdcPOBMV3YvzxavGacBtzk

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 keys to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```
> Don't forget to set the VAULT_ADDR in the script       

The above unseal keys & root token is saved to the [vault/initialize-vault/vault-keys.txt](vault/initialize-vault/vault-keys.txt) file.

### Unseal Vault
To unseal vault, execute as below,
```sh
$ bash vault/unseal-vault/unseal-vault.sh --root-token hvs.IFBdcPOBMV3YvzxavGacBtz
Unseal Key (will be hidden): 
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       db54ff8a-c6b1-4df6-a01a-5037c89b8f54
Version            1.12.1
Build Date         2022-10-27T12:32:05Z
Storage Type       consul
HA Enabled         true


Unseal Key (will be hidden): 
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       db54ff8a-c6b1-4df6-a01a-5037c89b8f54
Version            1.12.1
Build Date         2022-10-27T12:32:05Z
Storage Type       consul
HA Enabled         true


Unseal Key (will be hidden): 
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.12.1
Build Date      2022-10-27T12:32:05Z
Storage Type    consul
Cluster Name    vault-cluster-137c7f33
Cluster ID      9cee6b3e-ece7-1b4b-a53b-bc46c1619862
HA Enabled      true
HA Cluster      https://10.68.5.27:8201
HA Mode         active
Active Since    2022-11-30T19:22:58.251922193Z
```
> The script requires the --root-token argumant value, where the root token has to be passed.      
> Don't forget to set the VAULT_ADDR in the script       

The script will ask for any 3 Unseal keys from the total 5 Unseal keys, generated while initializing the vault & if the provided keys checks right, the vault gets unsealed.

## Enable Database Secret Engine & Configure for Dynamic Credentials:

### Enable Database Secret Engine:
To enable database secrect engine,
```sh
$ vault secrets enable database
Success! Enabled the database secrets engine at: database/
```
The database secrets engine is enabled.

### Configure Database Secret Engine (Postgres):
To confgiure Postgres database secrect engine, run the script [vault/database/postgres/configure-postgres.sh](vault/database/postgres/configure-postgres.sh) as below,
```sh
$ bash vault/database/postgres/configure-postgres.sh --root-token hvs.IFBdcPOBMV3YvzxavGacBtzk
Writing database config to vault database secret engine


Success! Data written to: database/config/exampledb-pg

Saving Postgres sql statements for creation statements


Saved

Writing vault role with creation statements


Success! Data written to: database/roles/exampledb-p
```
> Don't forget to set the VAULT_ADDR in the script      
  
The [configure-postgres.sh](vault/database/postgres/configure-postgres.sh) script configures the database secrect engine in 2 parts,
* Write Vault Database Config: <br>	
Below block of code responsible for writing postgres database config to vault database secret engine,
```bash
# Writing database config to vault database secret engine
echo -e "Writing database config to vault database secret engine\n\n"

vault write database/config/exampledb-pg \
plugin_name=postgresql-database-plugin \
allowed_roles="exampledb-pg" \
connection_url="postgresql://{{username}}:{{password}}@postgres.intern-deploy-testing:5432/exampledb?sslmode=disable" \
username=exampledb \
password=exampledb
```
> plugin_name, Specifies the name of the plugin to use for this connection. For MySQL, plugin_name would be mysql-database-plugin. <br> 
allowed_roles, List of the roles allowed to use the database connection <br>
username, Specifies the name of the user to use when connecting to the database <br>
password, Specifies the password of the user to use when connecting to the database<br>

For connection_url, "@postgres.intern-deploy-testing" is formatted as "postgres-sercvice-name.namespace-name"

* Create Vault Database Role:<br>
The postgres database secrets engine is configured with the allowed role named exampledb-pg in previous step. A role is a logical name within Vault that maps to database credentials. These credentials are expressed as SQL statements and assigned to the Vault role.
<br>The following block of code saves the SQL to vault-postgres-creation.sql, which is used to create credentials mapped to the allowed role list,
```bash
# Saving Postgres sql statements for creation statements
echo -e "\nSaving Postgres sql statements for creation statements\n\n"

cat <<EOF > vault-postgres-creation.sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "{{name}}";
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public to "{{name}}";
EOF
echo -e "Saved"
```

Now, The below code block writes the role named exampledb-pg that creates credentials using the vault-postgres-creation.sql,

```bash
# Writing vault role with creation statements
echo -e "\nWriting vault role with creation statements\n\n"

vault write database/roles/exampledb-pg \
db_name=exampledb-pg \
creation_statements=@vault-postgres-creation.sql \
default_ttl="5m" \
max_ttl="24h"
```

## Create Policy & Token for Dynamic Credentials:
A policy defines a list of paths. Each path expresses the capabilities that are allowed. Capabilities for a path must be granted, as Vault defaults to denying capabilities to paths to ensure that it is secure by default. 
To assign policy to credentials & save token for the policy, run the [vault/database/postgres/postgres-policy-token.sh](vault/database/postgres/postgres-policy-token.sh) script as below,
```sh
$ bash vault/database/postgres/postgres-policy-token.sh --root-token hvs.IFBdcPOBMV3YvzxavGacBtzk
Saving policy rules for credentials


Saved

Writing to vault policy with policy rules


Success! Uploaded policy: exampledb-pg-policy

Generating & Saving Token for the vault policy


Saved
```
> Don't forget to set the VAULT_ADDR in the script       
    
The Token generated for the policy is saved to the [vault/database/postgres/exampledb-pg-policy-token.txt](vault/database/postgres/exampledb-pg-policy-token.txt) in below format,
```
Key                  Value
---                  -----
token                hvs.CAESILzyUZSP6xr_SGMRoAP1U0hoUjt14P0yIUCXQqe6lVYbGh4KHGh2cy5Zd2hhQXVKWjFLa25RTk5uWnE4aU5CT0Y
token_accessor       ACH3MjeJptjZaxLa28VOJ9xZ
token_duration       768h
token_renewable      true
token_policies       ["default" "exampledb-pg-policy"]
identity_policies    []
policies             ["default" "exampledb-pg-policy"]
```

The [postgres-policy-token](vault/database/postgres/postgres-policy-token.sh) script writes policy for credentials & generates token for that policy in 2 steps,
* Create Policy: <br>
The following code block saves the policy rules as exampledb-pg-role-policy.hcl & writes the policy to vault as exampledb-pg-policy,
```bash
# Saving policy rules for credentials
echo -e "Saving policy rules for credentials\n\n"

cat <<EOF > exampledb-pg-role-policy.hcl
path "database/creds/exampledb-pg" {
  capabilities = [ "read" ]
}
EOF
echo -e "Saved"

# Writing to vault policy with policy rules.
echo -e "\nWriting to vault policy with policy rules\n\n"

vault policy write exampledb-pg-policy exampledb-pg-role-policy.hcl
```
* Generate & Save Token: <br>
The below code blocks generates and saves token for the policy, exampledb-pg-policy, at [vault/database/postgres/exampledb-pg-policy-token.txt](vault/database/postgres/exampledb-pg-policy-token.txt)
```bash
# Generating & Saving Token for the vault policy
echo -e "\nGenerating & Saving Token for the vault policy\n\n"

vault token create -policy="exampledb-pg-policy" >> exampledb-pg-policy-token.txt
echo -e "\n\n" >> exampledb-pg-policy-token.txt
echo -e "Saved"
```

## Access Database Credentials via API:
Here, we demonstrate the way for acquiring dynamic databse secrect from vault using vault API & usage of the secret to connect to a PostgreSQL database via golang. Here we have two seperate files,
 * vault.go
 * server.go 

### vault.go
It implements a function named requestVault() which requires the following parameters of string type,
 * address, The address of the vault server.
 * token, Token is for authentication within Vault.
 * mountPath, The mount path is the location where the target dynamic database secrect engine resides in Vault.
 * secretPath, The secret path is the location where secret resides in a particular dynamic database secrect engine.
 ```
 func requestVault(address, token, mountpath, key string) (*vault.KVSecret, error)
 ```

And on a successful call on the function, requestVault(), with appropiate parameters values, the function returns either,
 * A variable of type KVSecret, which contains the database secrects within a secret path.  
Or, 
 * A variable of type error, which contains any error occured as the function performs it task.

An appropiate call on requestVault() is presented below,
 ```
 psqlDBcreds, err := requestVault(os.Getenv("VAULT_ADDRESS"), os.Getenv("VAULT_TOKEN"), "database", "creds/exampledb-pg")
 ``` 
 > --> VAULT_ADDRESS, VAULT_TOKEN are the ENV Variables holding the Vault Address & Vault Authentication Token accordingly. <br>
 > --> "database" is the mountPath of Database Secrets Engine & "creds/exampledb-pg" is the secretPath.

Here, psqlDBcreds holds the returned value(from requestVault()) of type KVSecret which is the most basic struct type used to store secrects in Vault. The type defination is given below for further elaboration, 

```
type KVSecret struct {
	Data            map[string]interface{}
	VersionMetadata *KVVersionMetadata
	CustomMetadata  map[string]interface{}
	Raw             *Secret
}
```
> Data, contains the secrets mapped to itself.

### server.go
It shows how to use previously described requestVault() function & access mapped secrets from the returned KVSecret struct type to acquire the credentials to make a successful connection to PostgreSQL database.


```
psqlInfo := fmt.Sprintf("host=%s port=%d user=%s "+
		"password=%s dbname=%s sslmode=disable",
		os.Getenv("DB_HOST_NAME"), os.Getenv("PORT"), psqlDBcreds.Data["username"], psqlDBcreds.Data["password"], os.Getenv("DB_NAME"))
db, err := sql.Open("postgres", psqlInfo)
```
> --> DB_HOST_NAME, DB_NAME, PORT are the ENV Variables holding the Database Host Name, Databse Name & Port accordingly. <br>
> --> psqlDBcreds.Data["username"], psqlDBcreds.Data["password"] are database Username & Password, acquired from the KVSecret struct type variable, name psqlDBcreds.
