# frozen_string_literal: true

# Cookbook:: ultimate_config_cookbook - borrowed from
#
# The MIT License (MIT)
#
# Copyright:: 2017, Garry Lachman
# https://github.com/garrylachman/chef-ultimate-config-cookbook
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

resource_name :toml_file
# n.b this is the bit missing from upstream cookbook
# as consequence it stopped working on Chef/Cinc 16
provides :toml_file
unified_mode false

property :file_path, String, name_property: true
property :file_content, Hash, default: {}
property :file_sensitive, [true, false], default: false

require 'toml-rb'
# this is another addition as toml_file's own deep_merge is not very reliable
require 'deep_merge'

# rewrite actions using native resources to track state changes and be able to
# subscribe / notify
action :create do
  file new_resource.name do
    path new_resource.file_path
    content TomlRB.dump(new_resource.file_content)
    sensitive new_resource.file_sensitive

    not_if { ::File.exist? new_resource.file_path }
  end
end

action :edit do
  if ::File.exist?(new_resource.file_path)
    current_content = TomlRB.load_file(new_resource.file_path)
    new_content = current_content.deep_merge!(new_resource.file_content)
  end

  file new_resource.name do
    path new_resource.file_path
    content TomlRB.dump(new_content)
    sensitive new_resource.file_sensitive

    only_if { ::File.exist? new_resource.file_path }
  end
end

action :create_or_edit do
  action_create
  action_edit
end

action :delete do
  ::File.delete(new_resource.file_path) if ::File.exist?(new_resource.file_path)
end

action :replace do
  action_delete
  action_create
end
