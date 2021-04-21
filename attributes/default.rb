# main, test, or dev - dev has been trailing lately, hence defaulting to test
default['elrond']['network'] = 'test'

# package version - must be available in staker repo
default['elrond']['version'] = '1.1.50'

# the log level for the elrond node service(s)
default['elrond']['node']['log_level'] = '*:INFO'

# node list
# each hash in the nodes array can specify
## id - Integer >= 0 - indicating the node ID
## validator - Boolean - whether the node is a validator
## key_manager - Symbol - which resource provides the node key
default['elrond']['nodes'] = [
  {
    id: 0,
    # these defaults are appropriate for an observer
    validator: false,
    key_manager: :elrond_keygen,
  },
]
