# elrond Cookbook

Cookbook providing the necessary tools to install Elrond nodes (observers and validators). It uses our repositories ([deb](https://deb.staker.ltd/) and [rpm](https://rpm.staker.ltd/)) to install a binary build for the platforms we support.

## TODO

This list isn't sorted in a particular order:

 * CLI helper to simplify the access to termui, logviewer, service status in a multi-node environment
 * Complete the work on node config (i.e some bits are missing)
 * Keybase identity
 * Service ID
 * Node roles (i.e primary / backup)
 * Handle one-shot type of upgrades (e.g conditionally drop the db if requested)
 * elrond_node `:remove` action
 * [Observing squad](https://docs.elrond.com/integrators/observing-squad/) recipe

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

 - `default` - includes `install` and `configure_node`
 - `install` - installs Mr Staker repository (platform dependent) and the appropriate elrong package.
 - `configure_node` - configures Elrond Network nodes based on specific configuration.

## Attributes

| Attribute | Description |
| --------- | ----------- |
| default['elrond']['network'] | Indicates which network package to install: main, test, or dev. |
| default['elrond']['version'] | Indicates which Elrond package build to install. The indicated version must exist in our repository. |
| default['elrond']['node']['log_level'] | The log level for the Elrond node(s) service(s). |
| default['elrond']['nodes'] | The list of nodes to create. See details below. |
| default['elrond']['keyvault']['address'] | Hashicorp Vault cluster address. Only used by the `elrond_keyvault` resource. |
| default['elrond']['keyvault']['token'] | Access token. Can be one time use and CIDR scoped for additional security. Only used by the `elrond_keyvault` resource. |
| default['elrond']['keyvault']['path'] | The mount path for the secrets store. Only KV V2 is supported. Only used by the `elrond_keyvault` resource. |

The elrond nodes attribute is an Array of Hashes containing the following:

 * `action` - defaults to `:create` ('create' i.e String format is also acceptable). The other accepted value is `:remove` (or 'remove') to destroy a configured node.
 * `id` - indicates the node ID / index. Must be an Integer >= 0.
 * `validator` - indicates whether the node is a validator. If false, the node is setup as observer.
 * `key_manager` - indicates which Chef resource provides the node key. This is a pluggable resource, so you can provide any resource that conforms to the same specification, allowing the use of arbitrary data sources. Our implementation includes:
  * `elrond_keygen` - resource use to generate the `validatorKey.pem` file for a node. Can only be used when `validator = false`. If the key file already exists, the key generator won't trigger.
  * `elrond_keystore` - resource used to fetch the `validatorKey.pem` file for a node from a Hashicopr Vault cluster. Can only be used when `validator = true`. The initial vault export only triggers once per node due to the nature of the keys, so this resource doesn't require persistent access to the Vault, unless new keys need to be read. The keys are staged, then copied into each node's `config` directory.

Technically, the setup of an observer and validator are the same on the server side. The difference is that a validator has a stake transaction and the validatorKey.pem is declared in Elrond Wallet. The differentiation in this setup is the key_manager backend each use.

Each node is setup individually, so you don't have to have only validators or only observers.

## Libraries

 - None

## Resources/Providers

### elrond_node

Configures an Elrond node. This is typically invoked from the `configure_node` recipe by looping over `node['elrond']['nodes']`.

The configuration flow:

 * Creates user and group for the service. These are created as system user / group. For security reasons, the node user is not sudo enabled. Each node has it's own user/group.
 * Creates the home directory for the service, which is also the WorkingDirectory for the systemd unit.
 * Creates a distinct copy of the upstream configuration which is bundled with the elrond package build. This is then configured for each particular use case.
 * Deploys the node key via the indicated `key_manager` resource. We provide `elrond_keygen` for observers and `elrond_keystore` for validators as `key_manager` implementations, but any conforming to our specs can be configured in place.

There's only one systemd unit which is managing all of the node services. This systemd unit is a template unit, so the services are named, for example: elrond-node@0 (for `id: 0`), elrond-node@1 (for `id: 1`), etc. You get the gist.

### Actions

 - `:add`: adds an Elrond node and configures the node based on the specified properties.
 - `:remove`: remove a configured node. Normally, the configuration may be removed from `node['elrond']['nodes']` post node removal.

### Property Parameters

 - name: implicit name property. Only used for naming the resource, but it is not producing any changes in the resource itself.
 - id: the node ID. Must be Integer >= 0.
 - validator: boolean, indicating whether this is a validator node. This property is passed as parameter to the underlying `key_manager` resource.
 - key_manager: string, indicating which `key_manager` resource to use to setup the validatorKey.pem files.

#### Examples

This is invoked from the `configure_node` recipe by looping over `node['elrond']['nodes']`. The canonical implementation reads:

```ruby
elrond_node "node-#{elrond_node['id']}" do
  id elrond_node['id']
  validator elrond_node['validator']
  key_manager elrond_node['key_manager']

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

 - name: implicit name property. Only used for naming the resource, but it is not producing any changes in the resource itself.
 - id: the node ID. Must be Integer >= 0.
 - validator: boolean, indicating whether this is a validator node. While you can set this to true, the node service will fail to start as no key shall be created.

#### Examples

This is used implicitly by `elrond_node`.

### elrond_keyvault

`key_manager` implementation. Reads keys from Hashicorp Vault KV V2 store and exports them into `/opt/etc/elrond/keyvault`. The keys are then copied over for each node in their `config` directory. They are staged into `/opt/etc/elrond/keyvault` as a node configuration may be reset during upgrades, then re-created by the `elrond_node` resource.

This resource works only when the `validator` property is set to `true`.

This resource may be invoked from `elrond_node` when it dispatches dynamically the `key_manager` resource based on `node['elrond']['nodes']` configuration.


#### Actions

 - `:add`: Export validatorKey.pem from Hashicorp Vault and configure for indicated node.

#### Property Parameters

 - name: implicit name property. Only used for naming the resource, but it is not producing any changes in the resource itself.
 - id: the node ID. Must be Integer >= 0.
 - validator: boolean, indicating whether this is a validator node. While you can set this to false, the attempt to copy the key from the staging area will fail in this circumstance and it will stop the Chef/Cinc execution with an error.

#### Examples

This is used implicitly by `elrond_node`.

## Usage

Create a wrapper / role cookbook to setup the right attributes and consume. You'll need to `include_recipe 'elrond::default'` to do the setup the way our cookbook has implemeneted.

## Maintainer

[Mr Staker](https://github.com/mr-staker)

## License

[MIT](https://github.com/mr-staker/elrond-cookbook/blob/main/LICENSE)
