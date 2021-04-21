# main, test, or dev - dev has been trailing lately, hence defaulting to test
default['elrond']['network'] = 'test'

# package version - must be available in staker repo
default['elrond']['version'] = '1.1.50'

# if this is false, it runs keygenerator
# keygenerator runs only when the key is unavailable
# essentially validator = false creates an observer
default['elrond']['node']['validator'] = false
