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

cookbook_file '/etc/delivery/delivery.cerny.cc/fullchain.pem' do
  source 'fullchain.pem'
end

cookbook_file '/etc/delivery/delivery.cerny.cc/privkey.pem' do
  source 'privkey.pem'
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
  config <<-EOS
delivery_fqdn "#{node['delivery']['fqdn']}"
delivery['chef_username']    = "delivery"
delivery['chef_private_key'] = "/etc/delivery/delivery.pem"
delivery['chef_server']      = "#{node['delivery']['chef_server']}"
delivery['default_search']   = "((recipes:cerny\\\\\\\\:\\\\\\\\:delivery_build) AND chef_environment:#{node.chef_environment})"
delivery['delivery']['ssl_certificate'] = '/etc/delivery/delivery.cerny.cc/fullchain.pem'
delivery['delivery']['ssl_certificate_key'] = '/etc/delivery/delivery.cerny.cc/privkey.pem'
delivery['delivery']['ssl_ciphers'] = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
delivery['delivery']['ssl_protocols'] = "TLSv1.2"
  EOS
end

ingredient_config 'delivery' do
  notifies :reconfigure, 'chef_ingredient[delivery]', :immediately
end

execute 'create cerny enterprise' do
  command 'delivery-ctl create-enterprise cerny --ssh-pub-key-file=/etc/delivery/builder_key.pub > /etc/delivery/cerny.creds'
  not_if 'delivery-ctl list-enterprises --ssh-pub-key-file=/etc/delivery/builder_key.pub | grep -w cerny'
end

# rubocop:enable LineLength
