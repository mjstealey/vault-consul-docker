# Vault with Consul backend in Docker


The code herein should not be considered production level by any means, but rather serve as a development or learning environment for using HashiCorp Vault.

**What is Vault?**

- HashiCorp Vault secures, stores, and tightly controls access to tokens, passwords, certificates, API keys, and other secrets in modern computing. Vault handles leasing, key revocation, key rolling, and auditing. Through a unified API, users can access an encrypted Key/Value store and network encryption-as-a-service, or generate AWS IAM/STS credentials, SQL/NoSQL databases, X.509 certificates, SSH credentials, and more. [Read more](https://www.vaultproject.io).

**What is Consul?**

- Consul is a distributed service mesh to connect, secure, and configure services across any runtime platform and public or private cloud. [Read more](https://www.consul.io).

This work is based on content from [http://pcarion.com/2017/04/30/A-consul-a-vault-and-a-docker-walk-into-a-bar..html](http://pcarion.com/2017/04/30/A-consul-a-vault-and-a-docker-walk-into-a-bar..html)

## Configure and run

**NOTE**: The example provided is using [macOS specific Docker networking](https://docs.docker.com/docker-for-mac/networking/) values which would need to be modified to fit your environment.

### ACL tokens

Using `uuidgen`, generate two tokens, one for the consul master, and one for the vault agent

Consul master token:

```console
$ uuidgen
ED6F90AE-8254-4202-B157-E6B05339FD86
```

Vault agent token:

```console
$ uuidgen
98402653-FF9A-4B7F-B564-2F4744E67B0B
```

Update the `acl_master_token` and `acl_agent_token` lines in [config/consul.config](config/consul.config)

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
  "acl_master_token": "CONSUL_MASTER_TOKEN", ### <-- This
  "acl_default_policy": "deny",
  "acl_down_policy": "extend-cache",
  "acl_agent_token": "VAULT_AGENT_TOKEN", ### <-- This
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

Update the `token` line in [config/vault.config](config/vault.config)

```json
{
  "backend":
  {
    "consul":
    {
      "address": "host.docker.internal:9500",
      "advertise_addr": "http://host.docker.internal",
      "path": "vault/",
      "token": "VAULT_AGENT_TOKEN" ### <-- This
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

### Server settings

Update the settings in [config/vault.json](config/vault.json) and [docker-compose.yml](docker-compose.yml) to match the system you'll be deploying on.

- From `config/vault.json`:
    
    ```json
          "address":"host.docker.internal:9500",
          "advertise_addr":"http://host.docker.internal",
    ```

- From `docker-compose.yml`:
    
    ```yaml
        environment:
          - CONSUL_HTTP_ADDR=host.docker.internal:9500
          - VAULT_ADDR=http://host.docker.internal:9200
    ```

Ensure the Vault and Consul versions in the `.env` file are the same as defined in the client's `Dockerfile`

- From `.env`:

    ```bash
    # Versions
    VAULT_VERSION=0.11.1
    CONSUL_VERSION=1.2.3
    ```

### Consul

Start the consul container first

```console
$ docker-compose up -d consul
Creating consul ... done
```

Check the Consul UI at [http://127.0.0.1:9500](http://127.0.0.1:9500)

<img width="80%" alt="consul UI on start" src="https://user-images.githubusercontent.com/5332509/46502862-2bc54c00-c7f7-11e8-8368-1b1e3f21a055.png">

Notice that you will not be able to interact with any of the settings until you've provided the proper ACL token

From the **Settings** tab, paste your `CONSUL_MASTER_TOKEN` into the **ACL TOKEN** box and Save.

<img width="80%" alt="consul master token" src="https://user-images.githubusercontent.com/5332509/46502990-8bbbf280-c7f7-11e8-89bd-a3d7f3c52bc6.png">

Now return to the services tab and you should see the **consul** service running

<img width="80%" alt="consul service" src="https://user-images.githubusercontent.com/5332509/46503055-bc9c2780-c7f7-11e8-983b-ef2befda115d.png">

### Register Vault agent ACL

We previously generated a token for our Vault agent, but have not registered it into Consul as of yet.

Go to the ACL tab and choose to create a new ACL token

<img width="80%" alt="acl create" src="https://user-images.githubusercontent.com/5332509/46503162-100e7580-c7f8-11e8-9e30-0823414285ef.png">

Populate the fields with the following information and save:

- NAME: **vault-agent**
- Choose **CLIENT** radio button
- POLICY: 

    ```json
    {
      "key": {
        "vault/": {
          "policy": "write"
        }
      },
      "node": {
        "": {
          "policy": "write"
        }
      },
      "service": {
        "vault": {
          "policy": "write"
        }
      },
      "agent": {
        "": {
          "policy": "write"
        }
    
      },
      "session": {
        "": {
          "policy": "write"
        }
      }
    }
    ```
- ID: generated **VAULT_AGENT_TOKEN**

<img width="80%" alt="vault agent token" src="https://user-images.githubusercontent.com/5332509/46503469-e6098300-c7f8-11e8-9ab7-c57890862779.png">

You'll now see a new ACL registered in Consul

<img width="80%" alt="acl registered" src="https://user-images.githubusercontent.com/5332509/46503557-29fc8800-c7f9-11e8-9f71-74ce0ea2d8b4.png">

We are now ready to start the vault container

### Vault

Start the vault container

```console
$ docker-compose up -d vault
Creating vault ... done
```

Check the Consul UI for the new vault service [http://127.0.0.1:9500](http://127.0.0.1:9500)

<img width="80%" alt="start vault" src="https://user-images.githubusercontent.com/5332509/46503691-8e1f4c00-c7f9-11e8-8446-ca51c41e9d01.png">

Vault has been started, but not yet initialized. For this we'll use the vault client to interact with the RESTful API of the vault container.

### Vault Client

Build and run the vault client in docker-compose

```console
$ docker-compose build
$ docker-compose up -d client
Creating client ... done
```

The vault client is set to volume mount the [client-scripts](client-scripts/) directory as `/mnt/data` of the running `client` container.

Docker exec onto the client container, initialize and unseal the vault.

```console
$ docker exec -ti client /bin/bash
root@d5422a13cd59:/# cd /mnt/data/
root@d5422a13cd59:/mnt/data# ./initialize-and-unseal.sh
INFO: init Vault
Unseal Key 1: kIxHHDH3S/xlKVgy+oEncP9U2mQDq4KCdzr08d4S837n
Unseal Key 2: AGUiDKcWzLONaqLlCUxDjKT6ExhFsY+xYRFrpR9BoC9h
Unseal Key 3: Wo2WjjKCdWXyupvtMrjyaB+WclSebVhjU9MAsCWgYmpB
Unseal Key 4: h6HpWksKFsr6sTdC/rvH4jX0pwom+pisibNECFAjwdR4
Unseal Key 5: 1wLVrhT7F0VPUkvIgurcvbqrUthh7b9Bk0eIqMDsrWmC

Initial Root Token: d0d3e78f-8e5b-3cb3-bc05-d4c117a5645e

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
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       7d82bc48-85eb-3fd5-4588-79edba4e425e
Version            0.11.1
HA Enabled         true
Key                Value
---                -----
Seal Type          shamir
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       7d82bc48-85eb-3fd5-4588-79edba4e425e
Version            0.11.1
HA Enabled         true
Key                    Value
---                    -----
Seal Type              shamir
Sealed                 false
Total Shares           5
Threshold              3
Version                0.11.1
Cluster Name           vault-cluster-9bd61b1e
Cluster ID             044d1768-4137-f735-c814-6da43e5ae58f
HA Enabled             true
HA Cluster             n/a
HA Mode                standby
Active Node Address    <none>
Key             Value
---             -----
Seal Type       shamir
Sealed          false
Total Shares    5
Threshold       3
Version         0.11.1
Cluster Name    vault-cluster-9bd61b1e
Cluster ID      044d1768-4137-f735-c814-6da43e5ae58f
HA Enabled      true
HA Cluster      https://host.docker.internal:444
HA Mode         active
INFO: Vault has been unsealed
VAULT_ADDR=http://host.docker.internal:9200
VAULT_VERSION=0.11.1
VAULT_TOKEN=d0d3e78f-8e5b-3cb3-bc05-d4c117a5645e
```

At this stage the vault service should be unsealed and active

<img width="80%" alt="unsealed vault" src="https://user-images.githubusercontent.com/5332509/46503975-801dfb00-c7fa-11e8-8250-3a0624f9fc7b.png">

**NOTE**: The vault can also be initialized and unsealed manually using the following commands

- `$ vault operator init`: Initialize the vault
- `$ vault operator unseal`: Unseal vault - follow the prompts

You are now ready to start creating secrets

## Creating secrets

Docker exec into the `client` container as described above.

Export token (using the initial root token for demonstration purposes)

```console
# export VAULT_TOKEN=d0d3e78f-8e5b-3cb3-bc05-d4c117a5645e
```

Create kv pair

```console
# vault kv put secret/hello foo=world
Success! Data written to: secret/hello
```

Get secret

```console
# vault kv get secret/hello
=== Data ===
Key    Value
---    -----
foo    world
```

### using curl

Get list of keys

```console
# curl \
>   --header "X-Vault-Token: $VAULT_TOKEN" \
>   --request LIST \
>   "http://host.docker.internal:9200/v1/secret"
{
  "request_id":"a64d2863-54d0-e3b7-a31b-8b07de648097",
  "lease_id":"",
  "renewable":false,
  "lease_duration":0,
  "data":
  {
    "keys":
    [
      "hello"
    ]
  },
  "wrap_info":null,
  "warnings":null,
  "auth":null
}
```

Get data from key

```console
# curl \
>   --header "X-Vault-Token: $VAULT_TOKEN" \
>   "http://docker.for.mac.localhost:9200/v1/secret/hello"
{
  "request_id":"e958a939-89c3-04e1-29d1-d191457f607a",
  "lease_id":"",
  "renewable":false,
  "lease_duration":2764800,
  "data":
  {
    "foo":"world"
  },
  "wrap_info":null,
  "warnings":null,
  "auth":null
}
```

### From the Consul UI

From the **Settings** tab, enter the `VAULT_AGENT_TOKEN` into the **ACL TOKEN** field and Save

<img width="80%" alt="vault agent token" src="https://user-images.githubusercontent.com/5332509/46504473-0850d000-c7fc-11e8-8ea5-d92b7550a2f1.png">

Navigate to the **Key/Value** tab and select `vault` > `logical` > `GUID` > `hello`

<img width="80%" alt="key/value" src="https://user-images.githubusercontent.com/5332509/46504570-43eb9a00-c7fc-11e8-9137-423bd4fa343c.png">

From the Consul UI, assuming a valid ACL token, you can update, create and delete key/value pairs 

## help

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
    secrets        Interact with secrets engines
    ssh            Initiate an SSH session
    token          Interact with tokens
```

## References

- HashiCorp Vault: [https://www.vaultproject.io](https://www.vaultproject.io)
- HashiCorp Consul: [https://www.consul.io](https://www.consul.io)
- curl reference: [https://curl.haxx.se](https://curl.haxx.se)
