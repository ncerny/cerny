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

def write_secrets(product = nil) # rubocop:disable Metrics/MethodLength
  load_secrets.each do |key, value|
    product ||= key
    next unless product == key
    value.each do |k, v|
      path = k[%r{^(?<path>.*)/(?<file>[^/]*)|(?<file>[^/]*)}, 'path']
      directory path do
        recursive true
      end
      file k do
        sensitive true
        content v.to_s
        mode '0600'
      end
    end
  end
end # rubocop:enable Metrics/MethodLength

def gather_secrets
  hash = { 'id' => node.chef_environment }
  Dir.glob('/etc/opscode*').each do |dir|
    hash[dir] ||= {}
    Dir.glob(File.join(dir, '**', '*.{rb,json,pem,pub}')).each do |file|
      hash[dir][file] = IO.read(file)
    end
  end
  hash
end

def gen_secret_key
  secret = ''
  so = Mixlib::ShellOut.new('openssl rand -base64 512')
  so.run_command.stdout.each_line do |line|
    secret << line.chomp
  end
  secret
end
