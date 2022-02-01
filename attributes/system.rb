# frozen_string_literal: true

# these attributes are not meant to be changed i.e if you touch these, then you
# must know what you're doing - safety's off - you can easily shoot your own
# foot - see https://docs.chef.io/attribute_precedence/

# set base var dir for Elrond nodes
force_override['elrond']['system']['var_dir'] = '/opt/var/elrond'

# set whether arwen is built as separate binary or not
# n.b this was experimently unset on testnet for 1.1.60.0, but arwen came back
# as separate build afterwards - setting to true as it mainly influences the
# systemd unit template - shall review if this is needed to be addressed
# in the future
force_override['elrond']['system']['arwen'] = true
