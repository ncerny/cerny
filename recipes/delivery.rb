#
# Cookbook Name:: cerny
# Recipe:: delivery
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
#
# rubocop:disable LineLength

if node.run_state['delivery']['configuration']
  node.default['delivery']['configuration'] += node.run_state['delivery']['configuration'] # rubocop:disable LineLength
end

directory '/etc/delivery' do
  recursive true
end

directory '/var/opt/delivery/license' do
  recursive true
end

directory '/etc/delivery/delivery.cerny.cc' do
  owner 'root'
  group 'root'
  mode '0700'
end

directory '/var/opt/delivery/nginx/ca'

cookbook_file '/etc/delivery/delivery.cerny.cc/fullchain.pem' do
  source 'fullchain.pem'
end

cookbook_file '/etc/delivery/delivery.cerny.cc/privkey.pem' do
  source 'privkey.pem'
end

link '/var/opt/delivery/nginx/ca/delivery.cerny.cc.crt' do
  to '/etc/delivery/delivery.cerny.cc/fullchain.pem'
end

link '/var/opt/delivery/nginx/ca/delivery.cerny.cc.key' do
  to '/etc/delivery/delivery.cerny.cc/privkey.pem'
end

cookbook_file '/var/opt/delivery/license/delivery.license' do
  source 'delivery.license'
end

execute 'Delivery ssh keys' do
  creates '/etc/delivery/builder_key.pub'
  command 'ssh-keygen -t rsa -q -f /etc/delivery/builder_key -P ""'
end

# Delivery data bag
chef_data_bag 'keys' do
  action :create
end

chef_data_bag_item 'keys/delivery_builder_keys' do
  action :create
  secret_path '/etc/chef/encrypted_data_bag_secret'
  encryption_version 3
  raw_data lazy { { builder_key: IO.read('/etc/delivery/builder_key') } } # rubocop:disable LineLength
end

deliverybag = data_bag_item('keys', 'delivery_builder_keys')

file '/etc/delivery/delivery.pem' do
  content deliverybag['delivery_pem']
  mode '0600'
end

chef_ingredient 'delivery' do
  config node['delivery']['configuration']
end

ingredient_config 'delivery' do
  notifies :reconfigure, 'chef_ingredient[delivery]', :immediately
end

execute 'create cerny enterprise' do
  command 'delivery-ctl create-enterprise cerny --ssh-pub-key-file=/etc/delivery/builder_key.pub > /etc/delivery/cerny.creds'
  not_if 'delivery-ctl list-enterprises --ssh-pub-key-file=/etc/delivery/builder_key.pub | grep -w cerny'
end

# rubocop:enable LineLength
