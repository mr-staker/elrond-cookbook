# these attributes are not meant to be changed i.e if you touch these, then you
# must know what you're doing - safety's off - you can easily shoot your own
# foot - see https://docs.chef.io/attribute_precedence/

# set base var dir for Elrond nodes
force_override['elrond']['system']['var_dir'] = '/opt/var/elrond'

# set whether arwen is built as separate binary or not
force_override['elrond']['system']['arwen'] = false
if Gem::Version.new(node['elrond']['version']) < Gem::Version.new('1.1.60.0')
  force_override['elrond']['system']['arwen'] = true
end
