# Vault with Consul backend in Docker


The code herein should not be considered production level by any means, but rather serve as a development or learning environment for using HashiCorp Vault.

**What is Vault?**

- HashiCorp Vault secures, stores, and tightly controls access to tokens, passwords, certificates, API keys, and other secrets in modern computing. Vault handles leasing, key revocation, key rolling, and auditing. Through a unified API, users can access an encrypted Key/Value store and network encryption-as-a-service, or generate AWS IAM/STS credentials, SQL/NoSQL databases, X.509 certificates, SSH credentials, and more. [Read more](https://www.vaultproject.io).

**What is Consul?**

- Consul is a distributed service mesh to connect, secure, and configure services across any runtime platform and public or private cloud. [Read more](https://www.consul.io).

This work is based on content from [http://pcarion.com/2017/04/30/A-consul-a-vault-and-a-docker-walk-into-a-bar..html](http://pcarion.com/2017/04/30/A-consul-a-vault-and-a-docker-walk-into-a-bar..html)



## Configure and run

1. Update the settings in [vault-config/vault-config.json](vault-config/vault-config.json) and [docker-compose.yml](docker-compose.yml) to match the system you'll be deploying on (default is [docker.for.mac.localhost]() due to being developed on macOS)

    From `vault-config.json`:
    
    ```json
          "address":"docker.for.mac.localhost:9500",
          "advertise_addr":"http://docker.for.mac.localhost",
    ```

    From `docker-compose.yml`:
    
    ```yaml
        environment:
          - CONSUL_HTTP_ADDR=docker.for.mac.localhost:9500
          - VAULT_ADDR=http://docker.for.mac.localhost:9200
    ```
2. Ensure the Vault and Consul versions in the `.env` file are the same as the one build built by the client in the `Dockerfile`

    ```bash
    # Versions
    VAULT_VERSION=0.11.1
    CONSUL_VERSION=1.2.3
    ```
3. Start the **vault**, **consul** and **client** containers using docker-compose

    ```console
    $ docker-compose build
    $ docker-compose up -d
    Creating network "vault-docker_vault" with the default driver
    Creating network "vault-docker_default" with the default driver
    Creating client ... done
    Creating consul ... done
    Creating vault  ... done
    ```

4. Validate that the Consul UI is running at [http://localhost:9500/ui/dc-example/services](http://localhost:9500/ui/dc-example/services)

<img width="80%" alt="initial consul ui" src="https://user-images.githubusercontent.com/5332509/45655805-08d53100-bab0-11e8-8414-a7c65b279fc7.png">

### Initializing and unsealing the Vault

The vault can be initialized and unsealed manually, or by using the `initialize-and-unseal.sh` script.

Manual method

- Get onto the client container

    ```console
    $ docker exec -ti client /bin/bash
    root@ad1b9bf7a4c3:/# cd /mnt/data/
    root@ad1b9bf7a4c3:/mnt/data#
    ```

- Init:

    ```console
    # vault operator init
    Unseal Key 1: w3z71iZcIa+75in/TBcB4eDI2nULUOgtBApolIlqoSkP
    Unseal Key 2: ECI61314EjYrrwQvujiaVwTcAUOu+scaI2UMXH3+0J/2
    Unseal Key 3: Y/8M8gS3rrlmwF4giuBZVkZd4HOsDUXV/YP+AVxbMqtb
    Unseal Key 4: 2Y3ATG2bPKVZfe860Hgwa+/ElyJr6UAKaVGRnPvFWx0h
    Unseal Key 5: LHa65HxMMESjDbYz+JRRq9knAcdgd+z+kzAjX4DXIvxu
    
    Initial Root Token: 4ef920d0-683e-0d28-1675-628860e644c6
    
    Vault initialized with 5 key shares and a key threshold of 3. Please securely
    distribute the key shares printed above. When the Vault is re-sealed,
    restarted, or stopped, you must supply at least 3 of these keys to unseal it
    before it can start servicing requests.
    
    Vault does not store the generated master key. Without at least 3 key to
    reconstruct the master key, Vault will remain permanently sealed!
    
    It is possible to generate new unseal keys, provided you have a quorum of
    existing unseal keys shares. See "vault operator rekey" for more information.
    ```
- Unseal:

    ```console
    # vault operator unseal
    Unseal Key (will be hidden):
    Key                Value
    ---                -----
    Seal Type          shamir
    Sealed             true
    Total Shares       5
    Threshold          3
    Unseal Progress    1/3
    Unseal Nonce       8bd11c46-0c2c-a524-119e-f0cab132e801
    Version            0.11.1
    HA Enabled         true
    root@ad1b9bf7a4c3:/mnt/data# vault operator unseal
    Unseal Key (will be hidden):
    Key                Value
    ---                -----
    Seal Type          shamir
    Sealed             true
    Total Shares       5
    Threshold          3
    Unseal Progress    2/3
    Unseal Nonce       8bd11c46-0c2c-a524-119e-f0cab132e801
    Version            0.11.1
    HA Enabled         true
    root@ad1b9bf7a4c3:/mnt/data# vault operator unseal
    Unseal Key (will be hidden):
    Key                    Value
    ---                    -----
    Seal Type              shamir
    Sealed                 false
    Total Shares           5
    Threshold              3
    Version                0.11.1
    Cluster Name           vault-cluster-b8e61460
    Cluster ID             f002400a-e8d7-33c0-03af-58ba38a1c292
    HA Enabled             true
    HA Cluster             n/a
    HA Mode                standby
    Active Node Address    <none>
    ```

Script `initialize-and-unseal.sh`

- Get onto the client container

    ```console
    $ docker exec -ti client /bin/bash
    root@e2bf74b4bc41:/# cd /mnt/data/
    root@e2bf74b4bc41:/mnt/data#
    ```

- Run script:

    ```console
    # ./initialize-and-unseal.sh
    INFO: init Vault
    Unseal Key 1: JFtHka5H7vnZ6vkwVYFMb5VbIYHtWQpoa9f3TbQT4J9S
    Unseal Key 2: yb/KDoxLxHRU90hwiJaM0b4MQ8t38oq275eOvIBVNgQb
    Unseal Key 3: kTF4s4WOjNtbYBKmSJvbYLl1FN8LZBTkmYZjohDLcVMQ
    Unseal Key 4: 7h1tzwbkfs/auqkLUecYt9WxQSVECvsvMxa/FQ0dF+oY
    Unseal Key 5: y6KOLNyyqAbbrUYgkf/P9guWSjh0kvGbLFUtEOvEaMBG
    
    Initial Root Token: eeae9f15-7fb7-912d-80b6-c553d83e8616
    
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
    Unseal Nonce       cfa16e4e-af63-1b7e-7905-8a63795ab467
    Version            0.11.1
    HA Enabled         true
    Key                Value
    ---                -----
    Seal Type          shamir
    Sealed             true
    Total Shares       5
    Threshold          3
    Unseal Progress    2/3
    Unseal Nonce       cfa16e4e-af63-1b7e-7905-8a63795ab467
    Version            0.11.1
    HA Enabled         true
    Key                    Value
    ---                    -----
    Seal Type              shamir
    Sealed                 false
    Total Shares           5
    Threshold              3
    Version                0.11.1
    Cluster Name           vault-cluster-8cf22051
    Cluster ID             b01ca305-e87e-e1cd-cb03-6c89891572bf
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
    Cluster Name    vault-cluster-8cf22051
    Cluster ID      b01ca305-e87e-e1cd-cb03-6c89891572bf
    HA Enabled      true
    HA Cluster      https://docker.for.mac.localhost:444
    HA Mode         active
    INFO: Vault has been unsealed
    VAULT_ADDR=http://docker.for.mac.localhost:9200
    VAULT_VERSION=0.11.1
    VAULT_TOKEN=eeae9f15-7fb7-912d-80b6-c553d83e8616
    ```

The usealed vault will look similar to this in the Consul UI.

<img width="80%" alt="unsealed vault" src="https://user-images.githubusercontent.com/5332509/45656272-8f8b0d80-bab2-11e8-9097-6d3e29335b64.png">

## Creating secrets

Export token (using the initial root token for demostration purposes)

```console
# export VAULT_TOKEN=eeae9f15-7fb7-912d-80b6-c553d83e8616
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
>   "http://docker.for.mac.localhost:9200/v1/secret"
{
  "request_id":"f9f9587c-8510-499e-0292-b99386f4dc45",
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
  "request_id":"f89f96c7-1a9e-68df-9419-8a4e6239f516",
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
