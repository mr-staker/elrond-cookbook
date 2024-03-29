## Development setup

You must have:

 * Cinc Workstation. This cookbook has been developed / tested using [22.1.745](https://cinc.osuosl.org/files/unstable/cinc-workstation/22.1.745/ubuntu/20.04/cinc-workstation_22.1.745-1_amd64.deb). Chef Workstation should work with minor modifications to `.kitchen.docker.yml`.
 * Working Docker setup. This must run under a system with systemd. If you're using Docker Desktop on Windows with WSL2 backend, then [genie](https://github.com/arkane-systems/genie) must be used to setup systemd as init. Podman works as alternative under Linux/WSL2. Podman under WSL2 requires genie - the same as Docker.
 * kitchen-docker driver.

The`kitchen-docker` driver is, sadly, not part of Workstation anymore. kitchen-dokken doesn't work with Cinc / thick containers.

Install with:

```bash
# make sure this runs with Workstation being configured for your shell
# e.g eval "$(cinc shell-init zsh)" or eval "$(cinc shell-init bash)"
gem install kitchen-docker
```

## Test Kitchen crash course

A test instance is created for every platform and for every test suite, so, for 2 platform and 2 test suites there's 4 instances. Beware: testing all instances at the same time creates 6 nodes on testnet (2 for each observer test instance and 1 for each validator instance), so the hardware requirements can be substantial. Resource contention can significantly slow things down, so it's recommended not to build/test more than one instance at a time.

```bash
# instance status
kitchen status
Instance          Driver  Provisioner  Verifier  Transport  Last Action    Last Error
observer-ubuntu   Docker  ChefZero     Busser    Docker     <Not Created>  <None>
observer-oracle   Docker  ChefZero     Busser    Docker     <Not Created>  <None>
validator-ubuntu  Docker  ChefZero     Busser    Docker     <Not Created>  <None>
validator-oracle  Docker  ChefZero     Busser    Docker     <Not Created>  <None>

# configure all instances sequentially
kitchen converge

# configure all instances concurrently
kitchen converge -c

# test all instances concurrently
rake verify

# cleanup test setup
rake clean

# build individual instance
kitchen converge observer-ubuntu

# test individual instance - this is an extreme example to show how the
# substring name matcher works - you don't have to specify the full name
kitchen verify er-u # this verifies observer-ubuntu

# debug stuff in a particular instance - this is supplied by .kitchen_patch.rb
# which is included with this project i.e the upstream driver doesn't have login
kitchen login observer-ubuntu

# run all tests sequentially and clean up after every test
rake integration
```

## Testing a custom version / release channel

By default, Test Kitchen is configured for testnet using the latest testnet release. To override the version and release channel, use environment variables:

 * ELROND_VERSION
 * ELROND_NETWORK

Example:

```bash
ELROND_VERSION=1.2.38.1 ELROND_NETWORK=main rake test
```

## Static code analysis

This is done via Cookstyle. Invoke with:

```bash
rake lint
```

## Customise Test Kitchen setup

You can create a `.kitchen.local.yml` file to completely override `.kitchen.yml`. You can base it on our `.kitchen.docker.yml` or use `kitchen-vagrant` if you fancy.

## Troubleshooting

The only known issue is with Test Kitchen running in Docker. Sometimes, something in Docker breaks and the Elrond processes exit with an unexplained stacktrace. The only known solution is to restart the Docker VM.
