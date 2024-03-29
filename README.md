# elrond Cookbook

Chef/Cinc cookbook providing the necessary tools to install Elrond nodes (observers and validators). It uses our repositories ([deb](https://deb.staker.ltd/) and [rpm](https://rpm.staker.ltd/)) to install a binary build for the platforms we support. Only one set of binaries it used for all of the services involved for setting up Elrond Network nodes. The packages are built using our [elrond build-pkg](https://github.com/mr-staker/build-pkg/tree/main/recipes/elrond) fpm-cookery recipe.

By convention, the port numbering is as follows:

 * 8080 + node ID - for REST API port (i.e those used by termui and logviewer for example). These ports are bound to localhost/127.0.0.1.
 * 37373 + node ID - for P2P port (37373 is configurable).

There's additional information for specific topics described in these documents:

 * [Testing](/TESTING.md) - build, test, and develop using this cookbook.
 * [Upgrading](/UPGRADING.md) - upgrading Elrond nodes.
 * [Security](/SECURITY.md) - our security manifesto.

On Red Hat/CentOS/Oracle Linux, this cookbook provides appropriate support for SELinux (runs in enforcing mode). This is part of the standard configuration and we run within the confines of the SELinux policies.

firewalld is used for all distributions to limit inbound access. firewalld is part of the standard setup on Red Hat/CentOS/Oracle Linux and optional on Debian/Ubuntu, but it is used for all.

Hashicorp Vault is used as the initial source of node keys which are then seeded on the nodes. This is only used for validators i.e for observers, the keys are automatically generated.

Additionally, monit is used as secondary daemon monitor for the Elrond node services. Besides the existing daemon monitoring provided by systemd, monit does additional checks for the P2P listener i.e connects to the port and reads the service banner. If the service is not responsive, then it is automatically restarted. systemd is unable to cover the situation where a service is stuck, but the process is still running.

This [deployment template](https://github.com/mr-staker/elrond-deploy) can help you get you started with the practical aspects of this cookbook.

## erctl

`erctl` is an utility deployed by this cookbook which saves a few keystrokes for commonly used administrative functions. Please note that `erctl` assumes the structure deployed by this cookbook i.e it won't work with upstream config scripts.

Examples:

```bash
erctl help
Commands:
  erctl help [COMMAND]                     # Describe available commands or one specific command
  erctl journal [--grep SEARCH] ID         # Read stored logs from journald
  erctl keybase [--format TYPE] [--write]  # Export public BLS keys to be used on Keybase; requires sudo
  erctl list                               # List the node identifiers on this machine
  erctl log [--log-level LEVEL] ID         # Spawn logviewer for specified node
  erctl restart ID                         # Invoke systemctl restart elrond-node@ID; requires sudo
  erctl start ID                           # Invoke systemctl start elrond-node@ID; requires sudo
  erctl status ID                          # Invoke systemctl status elrond-node@ID; may require sudo
  erctl stop ID                            # Invoke systemctl stop elrond-node@ID; requires sudo
  erctl ui [--log-level LEVEL] ID          # Spawn termui for specified node

erctl help ui
Usage:
 erctl ui [--log-level LEVEL] ID

Options:
 -l, [--log-level=LOG-LEVEL]  # Elrond logger level(s)
                              # Default: *:INFO

Spawn termui for specified node

erctl ui 0
# spawns termui for Elrond node with ID = 0

sudo erctl stop 0
# stops elrond-node@0 service
```

Note that `termui` and `logviewer` do not work in the initial phase (e.g during trie sync) as the API port on the node service is not listening. You can check the service via:

```bash
erctl journal 0 --follow
```

To seed Keybase identity, for example:

```bash
# run on machine authenticated on Keybase with KBFS mounted - NOT on server
cd /keybase/public/*
mkdir -p elrond
cd elrond
# this ssh command is invoked against an actual server hosting validators
# the bit after $host runs remotely then it pipes to a local xargs
ssh -p $port -i $ssh_private_key $user@$host sudo erctl keybase | xargs touch
```

### monit-cli

This is a wrapper for our monit setup. Our monit setup is identical for both Enterprise Linux 8 and Ubuntu 20.04. This provides an easier way to tap into the monit information.

Example:

```bash
sudo monit-cli summary
Monit 5.26.0 uptime: 2m
┌─────────────────────────────────┬────────────────────────────┬───────────────┐
│ Service Name                    │ Status                     │ Type          │
├─────────────────────────────────┼────────────────────────────┼───────────────┤
│ b83b891b3536                    │ OK                         │ System        │
├─────────────────────────────────┼────────────────────────────┼───────────────┤
│ node-1                          │ OK                         │ Process       │
├─────────────────────────────────┼────────────────────────────┼───────────────┤
│ node-0                          │ OK                         │ Process       │
└─────────────────────────────────┴────────────────────────────┴───────────────┘

sudo monit-cli status
Monit 5.26.0 uptime: 2m

Process 'node-1'
  status                       OK
  monitoring status            Monitored
  monitoring mode              active
  on reboot                    start
  pid                          1122
  parent pid                   1
  uid                          995
  effective uid                995
  gid                          992
  uptime                       6m
  threads                      29
  children                     0
  cpu                          0.0%
  cpu total                    0.0%
  memory                       40.9% [1.5 GB]
  memory total                 40.9% [1.5 GB]
  security attribute           -
  disk read                    0 B/s [963.1 MB total]
  disk write                   0 B/s [923.7 MB total]
  port response time           794.687 ms to localhost:37374 type TCP/IP protocol generic
  data collected               Sat, 15 May 2021 18:54:51

Process 'node-0'
  status                       OK
  monitoring status            Monitored
  monitoring mode              active
  on reboot                    start
  pid                          956
  parent pid                   1
  uid                          996
  effective uid                996
  gid                          993
  uptime                       8m
  threads                      9
  children                     0
  cpu                          4.3%
  cpu total                    4.3%
  memory                       43.5% [1.5 GB]
  memory total                 43.5% [1.5 GB]
  security attribute           -
  disk read                    0 B/s [886.6 MB total]
  disk write                   0 B/s [378.7 MB total]
  port response time           215.718 ms to localhost:37373 type TCP/IP protocol generic
  data collected               Sat, 15 May 2021 18:54:51

System 'b83b891b3536'
  status                       OK
  monitoring status            Monitored
  monitoring mode              active
  on reboot                    start
  load average                 [11.98] [9.30] [5.42]
  cpu                          0.0%us 0.0%sy 0.0%wa
  memory usage                 3.4 GB [95.0%]
  swap usage                   648.0 MB [16.5%]
  uptime                       23m
  boot time                    Sat, 15 May 2021 18:31:22
  data collected               Sat, 15 May 2021 18:54:51
```

## Requirements

### Platforms

 - Debian
 - Ubuntu
 - Red Hat
 - CentOS
 - Oracle Linux

May work on Amazon Linux (rhel family), but this is untested.

### Chef/Cinc

 - Chef 16+
 - Cinc 16+

For reference, our development tooling is Cinc Workstation.

### Cookbooks

 - elrond

## Recipes

 - `default` - includes `install_staker_repo` and `configure_node`
 - `install_staker_repo` - installs Mr Staker repository (platform dependent).
 - `configure_node` - installs and configures Elrond Network nodes based on specific configuration.

## Attributes

| Attribute | Description |
| --------- | ----------- |
| ['elrond']['network'] | Indicates which network package to install: main, test, or dev. |
| ['elrond']['version'] | Indicates which Elrond package build to install. The indicated version must exist in our repository. |
| ['elrond']['node']['log_level'] | The log level for the Elrond node(s) service(s). |
| ['elrond']['node']['base_p2p_port'] | Default: 37373. The base port for P2P communication. |
| ['elrond']['nodes'] | The list of nodes to create. See details below. |
| ['elrond']['keyvault']['address'] | Hashicorp Vault cluster address. Only used by the `elrond_keyvault` resource. |
| ['elrond']['keyvault']['token'] | Access token. Can be one time use and CIDR scoped for additional security. Only used by the `elrond_keyvault` resource. |
| ['elrond']['keyvault']['path'] | The mount path for the secrets store. Only KV V2 is supported. Only used by the `elrond_keyvault` resource. |
| ['elrond']['keyvault']['ssl_ciphers'] | Override the [default](https://www.rubydoc.info/github/hashicorp/vault-ruby/Vault/Defaults#ssl_ciphers-class_method) list of _TLS_ ciphers. You don't need to change this unless your Vault is running in strict TLS 1.3 mode. Only used by the `elrond_keyvault` resource. |
| ['elrond']['staking']['agency'] | Staking agency value used to compose NodeDisplayName. |
| ['elrond']['keybase']['identity'] | The Keybase identity configured for the node(s). |

The `['elrond']['nodes']` attribute is an Array of Hashes containing the following:

 * `action` - defaults to `:create` ('create' i.e String format is also acceptable). The other accepted values: `:disable` (or `'disable'`) to disable a node but still keep the configuration; `:remove` (or `'remove'`) to destroy a configured node.
 * `id` - indicates the node ID / index. Must be an Integer >= 0.
 * `validator` - Default: false. Indicates whether the node is a validator. If false, the node is setup as observer.
 * `redundancy_level` - Default: 0. Indicates the node redundancy level. -1 = disabled, 0 = main instance (default), 1 = first backup, 2 = second backup, etc.
 * `destination_shard` - Default: 'disabled'. Indicates which is the destination shard for an observer. Only applied for observer nodes. Possible values: 'disabled' (i.e let the network choose, also for validators), 'metachain' (self explanatory), or a number indicating the shard e.g 0, 1, 2.
 * `key_manager` - Default: :elrond_keygen, indicates which Chef resource provides the node key. This is a pluggable resource, so you can provide any resource that conforms to the same specification, allowing the use of arbitrary data sources. Our implementation includes:
  * `:elrond_keygen` - resource use to generate the `validatorKey.pem` file for a node. Can only be used when `validator = false`. If the key file already exists, the key generator won't trigger.
  * `:elrond_keystore` - resource used to fetch the `validatorKey.pem` file for a node from a Hashicorp Vault cluster. Can only be used when `validator = true`. The initial vault export only triggers once per node due to the nature of the keys, so this resource doesn't require persistent access to the Vault, unless new keys need to be read. The keys are staged, then copied into each node's `config` directory.

The stated default values are not set on the attribute itself, but passed down to the elrond_node resource which is consuming the `['elrond']['nodes']` attribute. See the canonical implementation of `elrond_node` from the `configure_node` cookbook.

Technically, the setup of an observer and validator are the same on the server side. The difference is that a validator has a stake transaction and the node key is uploaded to Elrond Wallet. The differentiation in this setup is the `key_manager` backend each use.

Each node is setup individually, so you don't have to have only validators or only observers.

`NodeDisplayName` is a concatenated string generated using: "#{node['elrond']['staking']['agency']}-#{node['elrond']['network'].capitalize}-#{node_id}-#{redundancy_level}"

## Libraries

 - None

## Resources/Providers

### elrond_node

Configures an Elrond node. This is typically invoked from the `configure_node` recipe by looping over `node['elrond']['nodes']`.

The configuration flow:

 * Creates user and group for the service. These are created as system user / group. For security reasons, the node user is not sudo enabled. Each node has it's own user/group.
 * Creates the home directory for the service, which is also the WorkingDirectory for the systemd unit.
 * Creates a distinct copy of the upstream configuration which is bundled with the elrond package build. This is then configured for each particular use case.
 * Deploys the node key via the indicated `key_manager` resource. We provide `elrond_keygen` for observers and `elrond_keystore` for validators as `key_manager` implementations, but any conforming to our specs can be configured as plug-in.

There's only one systemd unit which is managing all of the node services. This systemd unit is a template unit, so the services are named, for example: elrond-node@0 (for `id: 0`), elrond-node@1 (for `id: 1`), etc. You get the gist.

### Actions

 - `:add`: adds an Elrond node and configures the node based on the specified properties.
 - `:remove`: remove a configured node. Normally, the configuration may be removed from `node['elrond']['nodes']` post node removal.

### Property Parameters

 - name: implicit name property. Only used for naming the resource, but it is not producing any changes in the resource itself (i.e there's no attribute alias).
 - id: the node ID. Must be Integer >= 0.
 - validator: boolean, indicating whether this is a validator node. This property is passed as parameter to the underlying `key_manager` resource.
 - key_manager: string, indicating which `key_manager` resource to use to setup the validatorKey.pem files.

#### Examples

This is invoked from the `configure_node` recipe by looping over `node['elrond']['nodes']`. The canonical implementation reads:

```ruby
elrond_node "node-#{elrond_node['id']}" do
  id elrond_node['id'].to_i
  validator elrond_node['validator'] == true
  key_manager elrond_node['key_manager']&.to_sym || :elrond_keygen
  redundancy_level elrond_node['redundancy_level']&.to_i || 0

  if elrond_node['validator'] != true
    destination_shard elrond_node['destination_shard'] || 'disabled'
  end

  action elrond_node['action'].to_sym if elrond_node['action']
end
```

### elrond_keygen

`key_manager` implementation. Invokes `keygenerator` for a particular observer.

This resource works only when the `validator` property is set to `false`.

This resource may be invoked from `elrond_node` when it dispatches dynamically the `key_manager` resource based on `node['elrond']['nodes']` configuration.

#### Actions

 - `:add`: Invoke `keygenerator` for specified node.

#### Property Parameters

 - name: implicit name property. Only used for naming the resource, but it is not producing any changes in the resource itself (i.e there's no attribute alias).
 - id: the node ID. Must be Integer >= 0.
 - validator: boolean, indicating whether this is a validator node. While you can set this to true, the node service will fail to start as no key shall be created.

#### Examples

This is used implicitly by `elrond_node`.

### elrond_keyvault

`key_manager` implementation. Reads keys from Hashicorp Vault KV V2 store and exports them into `/opt/etc/elrond/keyvault`. This `keyvault` directory is owned by `root` and it is only available to the `root` user. The keys are then copied over for each node in their `config` directory. They are staged into `/opt/etc/elrond/keyvault` as a node configuration may be reset during upgrades, then re-created by the `elrond_node` resource.

This resource works only when the `validator` property is set to `true`.

This resource may be invoked from `elrond_node` when it dispatches dynamically the `key_manager` resource based on `node['elrond']['nodes']` configuration.

#### Actions

 - `:add`: Export validatorKey.pem from Hashicorp Vault and configure for indicated node.

#### Property Parameters

 - name: implicit name property. Only used for naming the resource, but it is not producing any changes in the resource itself (i.e there's no attribute alias).
 - id: the node ID. Must be Integer >= 0.
 - validator: boolean, indicating whether this is a validator node. While you can set this to false, the attempt to copy the key from the staging area will fail in this circumstance and it will stop the Chef/Cinc execution with an error.

#### Examples

This is used implicitly by `elrond_node`.

### vault_export

`vault_export` is a resource used by `elrond_keyvault` to export a key value from Hashicorp Vault to the local filesystem to be consumed by an Elrond node process.

#### Actions

 - `:export`: Export secret from Hashicorp Vault to local filesystem.

#### Property Parameters

 - file_path: the file path where to save the exported secret. This is the name property for this custom resource.
 - address: Hashicorp Vault server address.
 - token: Hashicorp Vault access token.
 - secret_path: the Hashicorp Vault path to the KV secret.
 - secret_name: the name of the secret stored in Hashicorp Vault.
 - secret_key: optional, the key of the key/value pair stored in Hashicorp Vault KV2 secret storage. If unspecified, the secret KV structure is exported and serialised as YAML.
 - ssl_ciphers: optional, allows custom definitions for vault-ruby's ssl_ciphers configuration option.

#### Examples

This is used implicitly by `elrond_keyvault`.

## Usage

Create a wrapper / role cookbook to setup the right attributes and consume. You'll need to `include_recipe 'elrond::default'` to do the setup the way our cookbook has implemeneted.

## Maintainer

[Mr Staker](https://github.com/mr-staker)

## License

[MIT](https://github.com/mr-staker/elrond-cookbook/blob/main/LICENSE)
