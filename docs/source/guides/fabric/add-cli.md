[//]: # (##############################################################################################)
[//]: # (Copyright Accenture. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)
[//]: # (##############################################################################################)

<a name = "adding-cli-to-existing-network-in-fabric"></a>
# Adding cli to Hyperledger Fabric

- [Prerequisites](#prerequisites)
- [Modifying Configuration File](#modifying-configuration-file)
- [Run playbook](#run-playbook)

<a name = "prerequisites"></a>
## Prerequisites
To add  cli  a fully configured Fabric network must be present already, i.e. a Fabric network which has Orderers, Peers, Channels (with all Peers already in the channels). The corresponding crypto materials should also be present in their respective Hashicorp Vault.

---
**NOTE**: Addition of cli has been tested on an existing network which is created by Bevel. Networks created using other methods may be suitable but this has not been tested by Bevel team.

---

<a name = "create_config_file"></a>
## Modifying Configuration File

Refer [this guide](../networkyaml-fabric.md) for details on editing the configuration file.

While modifying the configuration file(`network.yaml`) for adding cli, all the existing organizations should have `org_status` tag as `existing` and the new organization should have `org_status` tag as `new` under `network.channels` e.g.


```yaml
--8<-- "platforms/hyperledger-fabric/configuration/samples/network-fabric-add-organization.yaml:65:139"
```

and under `network.organizations` as

```yaml
--8<-- "platforms/hyperledger-fabric/configuration/samples/network-fabric-add-organization.yaml:143:155"
      ..
      ..
--8<-- "platforms/hyperledger-fabric/configuration/samples/network-fabric-add-organization.yaml:406:414"
      ..
      ..
```

The `network.yaml` file should contain the specific `network.organization` details along with the orderer information.


<a name = "run_network"></a>
## Run playbook

The [add-cli.yaml](https://github.com/hyperledger/bevel/tree/main/platforms/hyperledger-fabric/configuration/add-cli.yaml) playbook is used to add cli to the existing network. This can be done using the following command

```
ansible-playbook platforms/shared/configuration/add-cli.yaml --extra-vars "@path-to-network.yaml"
```