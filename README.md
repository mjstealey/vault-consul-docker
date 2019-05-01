# Vault with Consul backend in Docker

The code herein should not be considered production level by any means, but rather serve as a development or learning environment for using HashiCorp Vault.

**What is Vault?**

- HashiCorp Vault secures, stores, and tightly controls access to tokens, passwords, certificates, API keys, and other secrets in modern computing. Vault handles leasing, key revocation, key rolling, and auditing. Through a unified API, users can access an encrypted Key/Value store and network encryption-as-a-service, or generate AWS IAM/STS credentials, SQL/NoSQL databases, X.509 certificates, SSH credentials, and more. [Read more](https://www.vaultproject.io).

**What is Consul?**

- Consul is a distributed service mesh to connect, secure, and configure services across any runtime platform and public or private cloud. [Read more](https://www.consul.io).

This work was inspired by: [http://pcarion.com/2017/04/30/A-consul-a-vault-and-a-docker-walk-into-a-bar..html](http://pcarion.com/2017/04/30/A-consul-a-vault-and-a-docker-walk-into-a-bar..html)

**Last updated**: 2019-04-29

- [Consul](https://hub.docker.com/_/consul) version: **1.4.4**
- [Vault](https://hub.docker.com/_/vault) version: **1.1.2**

**NOTE**: The example provided is using [macOS specific Docker networking](https://docs.docker.com/docker-for-mac/networking/) values which would need to be modified to fit your environment.

## How to use

### Configuration files

Outside of development mode, Vault and Consul are configured using a file. The format of this file is [HCL](https://github.com/hashicorp/hcl) or JSON. The examples herein will use the JSON format.

Copy the template files for both Vault and Consul.

```
cp config/vault.json.template config/vault.json
cp config/consul.json.template config/consul.json
```

### Consul

**Configure**

Using `uuidgen`, generate a consul master token.

Consul master token:

```console
$ uuidgen
ED6F90AE-8254-4202-B157-E6B05339FD86
```

Replace `CONSUL_MASTER_TOKEN` with the value you've generated in the [config/consul.json](config/consul.json) file

```json
{
  "datacenter": "dc-example",
  "data_dir": "/consul/data",
  "log_level": "DEBUG",
  "node_name": "dc-master",
  "server": true,
  "bootstrap_expect": 1,
  "client_addr": "0.0.0.0",
  "ui" : true,
  "acl_datacenter": "dc-example",
  "acl_master_token": "CONSUL_MASTER_TOKEN", // <-- Replace with: ED6F90AE-8254-4202-B157-E6B05339FD86
  "acl_default_policy": "deny",
  "acl_down_policy": "extend-cache",
  "ports": {
    "dns": 9600,
    "http": 9500,
    "https": -1,
    "serf_lan": 9301,
    "serf_wan": 9302,
    "server": 9300
  }
}
```


**Start Consul**

With the configuration file in place and updated with the master token, you can start the consul container with docker compose.

```
docker-compose up -d consul
```

Navigate to [http://127.0.0.1:9500]() and ensure the Consul UI is running

<img width="80%" alt="Consul on startup" src="https://user-images.githubusercontent.com/5332509/56913034-a3eaac00-6a7e-11e9-98ca-3210a44ff7c8.png">

From the ACL tab, enter the value generated for `CONSUL_MASTER_TOKEN` and press save

<img width="80%" alt="Enter master token" src="https://user-images.githubusercontent.com/5332509/56913328-57ec3700-6a7f-11e9-9f13-e922ff1687a5.png">

You should observe a success message and be operating as the root level administrator of Consul

<img width="80%" alt="root level administrator" src="https://user-images.githubusercontent.com/5332509/56913341-5f134500-6a7f-11e9-99c2-67fa6c922efd.png">


**Create a policy for Vault**

From the ACL tab, select Policies and create a new policy

<img width="80%" alt="Policies" src="https://user-images.githubusercontent.com/5332509/56913439-ad284880-6a7f-11e9-8cd1-e3a17691306d.png">

New Policy - copy/paste entries as presented below and save

<img width="80%" alt="New Policy" src="https://user-images.githubusercontent.com/5332509/56913598-10b27600-6a80-11e9-92f2-0e3418d0e172.png">

- **Name**: vault-agent
- **Rules**:

```json
{
  "key_prefix": {
    "vault/": {
      "policy": "write"
    }
  },
  "node_prefix": {
    "": {
      "policy": "write"
    }
  },
  "service": {
    "vault": {
      "policy": "write"
    }
  },
  "agent_prefix": {
    "": {
      "policy": "write"
    }
    
  },
  "session_prefix": {
    "": {
      "policy": "write"
    }
  }
}
```
- **Description**: None

You should observe a success message and see a new policy named **vault-agent** listed

<img width="80%" alt="vault-agent policy" src="https://user-images.githubusercontent.com/5332509/56913735-6d159580-6a80-11e9-8aca-6ae8a7d1aa66.png">

**Generate token for Vault**

From the ACL tab, select Tokens and create a new token

<img width="80%" alt="Tokens" src="https://user-images.githubusercontent.com/5332509/56913862-b1a13100-6a80-11e9-98fe-975e5ff440bf.png">

New Token - apply existing **vault-agent** policy to new token named Vault Agent and save

<img width="80%" alt="Create new token" src="https://user-images.githubusercontent.com/5332509/56914094-3429f080-6a81-11e9-8ff6-539f012eda14.png">

You should observe a success message and see a new token named **Vault Agent** listed

<img width="80%" alt="Vault Agent Token" src="https://user-images.githubusercontent.com/5332509/56914127-4f94fb80-6a81-11e9-9278-a5b0055e2234.png">

### Vault

**Configure**

Click the Vault Agent token (puts it into edit mode) so that the details can be observed.

<img width="80%" alt="token details" src="https://user-images.githubusercontent.com/5332509/56914248-9f73c280-6a81-11e9-95cc-0348dcee2482.png">

Replace the value of `VAULT_AGENT_TOKEN` in the [config/vault.json](config/vault.json) file with newly generated Vault Agent Token 

From example, `VAULT_AGENT_TOKEN` = `d92ac4aa-836c-b887-6144-81dfaaa3366c`

```json
{
  "storage":
  {
    "consul":
    {
      "address": "host.docker.internal:9500",
      "advertise_addr": "http://host.docker.internal",
      "path": "vault/",
      "token": "VAULT_AGENT_TOKEN" // <-- Replace with: d92ac4aa-836c-b887-6144-81dfaaa3366c
    }
  },
  "listener":
  {
    "tcp":
    {
      "address": "0.0.0.0:8200",
      "tls_disable": 1
    }
  },
  "log_level": "DEBUG"
}

```

**Start Vault**

With the configuration file in place and updated with the vault token, you can start the vault container with docker compose.

```
docker-compose up -d vault
```

Navigate to [http://127.0.0.1:9500]() and verify that a new service named vault is running in standby mode.

<img width="80%" alt="Services" src="https://user-images.githubusercontent.com/5332509/56924171-4d8b6680-6a9a-11e9-9690-d9685de8d6ec.png">

Vault has been started, but not yet initialized. For this we'll use the vault client to interact with the RESTful API of the vault container.

## Vault Client

Build and run the vault client in docker-compose

```
docker-compose build
docker-compose up -d client
```

The vault client defaults to volume mounting the [client-scripts](client-scripts) directory as `/mnt/data` of the running client container.

Docker exec onto the client container, initialize and unseal the vault.

```console
$ docker exec -ti client /bin/bash
root@ac3e3a01a4a5:/# cd /mnt/data/
root@ac3e3a01a4a5:/mnt/data# ./initialize-and-unseal.sh
INFO: init Vault
Unseal Key 1: CkU4RFOn0jl3IoD3ZBMId3g9V4yPqaBPwLZtelBn4ZXB
Unseal Key 2: 0mn/hNvkzY8FvBMpmqQfXTLa+9L0OaWKeFmIlINiwdmR
Unseal Key 3: DAEJRhYvD+P2um40CfJ50okF23MQaBJpymmPWupWGhM3
Unseal Key 4: +M8F0DfI7JqpWEFMKxVx4meUlQD/f8UigxbRohc01Qkc
Unseal Key 5: 6douRfxKIlqfzEodMjPHSELT+WLm+PVw4d/37Ibf1WQQ

Initial Root Token: s.ZQSMW5tJmSXNhGFZrr0oKuUR

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
INFO: unseal Vault
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       7389c6bd-768c-3bad-aea6-c1b923141019
Version            1.1.2
HA Enabled         true
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       7389c6bd-768c-3bad-aea6-c1b923141019
Version            1.1.2
HA Enabled         true
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           5
Threshold              3
Version                1.1.2
Cluster Name           vault-cluster-a1069ec3
Cluster ID             115e5944-aa2b-3cb6-2fc4-c1778c84b36a
HA Enabled             true
HA Cluster             n/a
HA Mode                standby
Active Node Address    <none>
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.1.2
Cluster Name    vault-cluster-a1069ec3
Cluster ID      115e5944-aa2b-3cb6-2fc4-c1778c84b36a
HA Enabled      true
HA Cluster      https://host.docker.internal:444
HA Mode         active
INFO: Vault has been unsealed
VAULT_ADDR=http://host.docker.internal:9200
VAULT_VERSION=1.1.2
VAULT_TOKEN=s.ZQSMW5tJmSXNhGFZrr0oKuUR
```

At this stage the vault service should be unsealed and active

<img width="80%" alt="Services active" src="https://user-images.githubusercontent.com/5332509/56924549-297c5500-6a9b-11e9-9350-256aa0dfa8f5.png">

**NOTE**: The vault can also be initialized and unsealed manually using the following commands

- `$ vault operator init`: Initialize the vault
- `$ vault operator unseal`: Unseal vault - follow the prompts

You are now ready to start running vault commands

## Vault commands

Docker exec into the `client` container as described above, and set the value of `VAULT_TOKEN` as an environment variable (using the initial root token for demonstration purposes)

```console
docker exec -ti \
  -e VAULT_TOKEN=s.ZQSMW5tJmSXNhGFZrr0oKuUR \
  client /bin/bash
```

```
export VAULT_TOKEN=s.ZQSMW5tJmSXNhGFZrr0oKuUR
export VAULT_ADDR=http://host.docker.internal:9200
export CONSUL_HTTP_ADDR=host.docker.internal:9500
docker run --rm -ti \
  -e VAULT_TOKEN=$VAULT_TOKEN \
  -e VAULT_ADDR=$VAULT_ADDR \
  -e CONSUL_HTTP_ADDR=$CONSUL_HTTP_ADDR \
  -v $(pwd):/mnt/data \
  mjstealey/vault-client:latest \
  /bin/bash
```

**help**

```console
# vault --help
Usage: vault <command> [args]

Common commands:
    read        Read data and retrieves secrets
    write       Write data, configuration, and secrets
    delete      Delete secrets and configuration
    list        List data or secrets
    login       Authenticate locally
    agent       Start a Vault agent
    server      Start a Vault server
    status      Print seal and HA status
    unwrap      Unwrap a wrapped secret

Other commands:
    audit          Interact with audit devices
    auth           Interact with auth methods
    kv             Interact with Vault's Key-Value storage
    lease          Interact with leases
    namespace      Interact with namespaces
    operator       Perform operator-specific tasks
    path-help      Retrieve API help for paths
    plugin         Interact with Vault plugins and catalog
    policy         Interact with policies
    print          Prints runtime configurations
    secrets        Interact with secrets engines
    ssh            Initiate an SSH session
    token          Interact with tokens
```

**status**

```console
# vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.1.2
Cluster Name    vault-cluster-a1069ec3
Cluster ID      115e5944-aa2b-3cb6-2fc4-c1778c84b36a
HA Enabled      true
HA Cluster      https://host.docker.internal:444
HA Mode         active
```

**kv secrets**

To enable a version 1 kv store

```
vault secrets enable -version=1 kv
```

After the secrets engine is configured and a user/machine has a Vault token with the proper permission, it can generate credentials. The kv secrets engine allows for writing keys with arbitrary values.

Write arbitrary data:

```console
# vault kv put kv/my-secret my-value=s3cr3t
Success! Data written to: kv/my-secret
```

Read arbitrary data:

```console
# vault kv get kv/my-secret
====== Data ======
Key         Value
---         -----
my-value    s3cr3t
```

List the keys:

```console
# vault kv list kv/
Keys
----
my-secret
```

This is also visible from the consul UI under the Key/Value tab

<img width="80%" alt="my-secret" src="https://user-images.githubusercontent.com/5332509/57043536-d4287b00-6c35-11e9-8718-de8f90e4af39.png">

### using curl

Example cURL calls to a vault instance running on the localhost

**Get list of keys**

```
export VAULT_TOKEN=s.ZQSMW5tJmSXNhGFZrr0oKuUR
export VAULT_ADDR=http://127.0.0.1:9200
curl \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --request LIST \
  "$VAULT_ADDR/v1/kv"
```

Example: 

```console
$ curl -s \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --request LIST \
  "$VAULT_ADDR/v1/kv" | jq .
{
  "request_id": "400a6e82-212f-3276-cda9-f0b1622c95b0",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "keys": [
      "my-secret"
    ]
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

**Get data from key**

```
export VAULT_TOKEN=s.ZQSMW5tJmSXNhGFZrr0oKuUR
export VAULT_ADDR=http://127.0.0.1:9200
curl \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/kv/my-secret"
```

Example:

```console
$ curl -s \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/kv/my-secret" | jq .
{
  "request_id": "2e2480c6-9a8f-8b65-2914-2b9813c0a1e7",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "my-value": "s3cr3t"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

## References

- HashiCorp Vault: [https://www.vaultproject.io](https://www.vaultproject.io)
- HashiCorp Consul: [https://www.consul.io](https://www.consul.io)
- curl reference: [https://curl.haxx.se](https://curl.haxx.se)
