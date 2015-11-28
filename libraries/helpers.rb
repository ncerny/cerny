#
# Cookbook Name:: cerny
# Library:: helpers
#
# Copyright 2015 Nathan Cerny
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def load_secrets
  include_recipe 'chef-vault'
  begin
    chef_secrets = chef_vault_item('chef-secrets', node.chef_environment)
    chef_secrets.delete('id')
  rescue
    raise 'The chef-server must be built first to generate secrets!'
  end
  chef_secrets
end

def write_secrets
  load_secrets.each do |key, value|
    directory "/etc/#{key}"
    value.each do |k, v|
      path = k[%r{^(?<path>.*)/(?<file>[^/]*)|(?<file>[^/]*)}, 'path']
      directory "/etc/#{key}/#{path}" do
        recursive true
      end if path
      file "/etc/#{key}/#{k}" do
        sensitive true
        content v.to_s
        mode '0600'
      end
    end
  end
end
