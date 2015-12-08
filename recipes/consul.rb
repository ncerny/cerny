# Cookbook Name:: cerny
# Recipe:: consul
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

user node['consul']['service_user'] do
  group node['consul']['service_group']
  shell '/sbin/nologin'
end

consul_config 'consul' do
  owner node['consul']['service_user']
  group node['consul']['service_group']
  path '/etc/consul.json'
  data_dir '/var/lib/consul'
  ca_file '/etc/consul/ssl/CA/ca.crt'
  cert_file '/etc/consul/ssl/certs/consul.crt'
  client_addr '0.0.0.0'
  key_file '/etc/consul/ssl/private/consul.key'
  ports dns: 8600,
        http: 8500,
        rpc: 8400,
        serf_lan: 8301,
        serf_wan: 8302,
        server: 8300
  bootstrap_expect 3
end

consul_service 'consul' do
  user node['consul']['service_user']
  group node['consul']['service_group']
  version node['consul']['version']
  config_file '/etc/consul.json'
  install_method 'binary'
  config_dir '/etc/consul'
  binary_url "https://releases.hashicorp.com/consul/%{version}/%{filename}.zip" # rubocop:disable Style/StringLiterals
  source_url 'https://github.com/hashicorp/consul'
  subscribes :restart, 'consul_config[consul]', :delayed
end
