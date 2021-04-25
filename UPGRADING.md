## Upgrading

Our `elrond-$network` package upgrade (where `$network is` either `main`, `test`, or `dev`) is handled by Chef/Cinc. The `['elrond']['version']` attribute must be specified for setting up nodes using this cookbook and it identifies a published version in our repositories.

The upgrade of the package itself triggers a set of actions (via the notify/subscribe system) to refresh the configuration based on the upstream configuration packaged with the new build. Then, Chef/Cinc re-creates the changes to the configuration in order to restore the node state. At the end of the run, all of the `elrond-node@ID` services are restated.

Essentially, this means:

 * Restoring p2p.toml custom setting i.e `Port`.
 * Restoring prefs.toml custom settings i.e `NodeDisplayName`, `Identity`, `RedundancyLevel`.
 * Create new node keys for observers or restore node keys from the local key store for validators.
