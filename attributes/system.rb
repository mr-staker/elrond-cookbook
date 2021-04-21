# these attributes are not meant to be changed i.e if you touch these, then you
# must know what you're doing - safety's off - you can easily shoot your own
# foot - see https://docs.chef.io/attribute_precedence/
force_override['elrond']['system']['var_dir'] = '/opt/var/elrond'
