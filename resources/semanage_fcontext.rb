# frozen_string_literal: true

resource_name :semanage_fcontext
provides :semanage_fcontext
unified_mode false

property :path, String, name_property: true
property :type, String

default_action :set

action :set do
  # SELinux doesn't work well (read: at all) when the context is set for a file
  # which is put in a path with a symlink
  path = ::File.realpath new_resource.path
  type = new_resource.type

  bash "semanage-fcontext-#{path}" do
    code <<~CODE
      set -e
      semanage fcontext --add --type #{type} #{path}
      restorecon #{path}
    CODE

    only_if 'selinuxenabled'
    not_if "ls -Z #{path} | grep #{type}"
  end
end
