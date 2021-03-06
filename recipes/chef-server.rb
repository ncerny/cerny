#
# Cookbook Name:: cerny
# Recipe:: chef-server
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

require 'securerandom'

chef_gem 'cheffish'

if node.run_state['chef-server']['configuration']
  node.default['chef-server']['configuration'] += node.run_state['chef-server']['configuration'] # rubocop:disable LineLength
end

directory '/etc/opscode/chef.cerny.cc' do
  owner 'root'
  group 'root'
  mode '0700'
end

cookbook_file '/etc/opscode/chef.cerny.cc/fullchain.pem' do
  source 'fullchain.pem'
end

cookbook_file '/etc/opscode/chef.cerny.cc/privkey.pem' do
  source 'privkey.pem'
end

include_recipe 'chef-vault'
include_recipe 'chef-server'
include_recipe 'chef-server::addons'

include_recipe 'firewalld'

firewalld_service 'https' do
  zone 'public'
  notifies :reload, 'service[firewalld]', :delayed
end

# rabbitmq
firewalld_port '5672/tcp' do
  zone 'public'
  notifies :reload, 'service[firewalld]', :delayed
end

# Push-Jobs Heartbeat Port
firewalld_port '10000/tcp' do
  zone 'public'
  notifies :reload, 'service[firewalld]', :delayed
end

# Push-Jobs Command Port
firewalld_port '10003/tcp' do
  zone 'public'
  notifies :reload, 'service[firewalld]', :delayed
end

node['chef-server']['users'].each do |user|
  node.run_state['chef-users'] ||= {}
  node.run_state['chef-users'][user[:name]] ||= {}
  node.run_state['chef-users'][user[:name]]['password'] = SecureRandom.hex(36)

  directory '/home/chef-user-data' do
    owner 'root'
    group 'root'
    mode '0700'
  end

  file "/home/chef-user-data/#{user[:name]}.password" do
    sensitive true
    content node.run_state['chef-users'][user[:name]]['password']
    owner 'root'
    group 'root'
    mode '0600'
    action :nothing
  end

  file "/home/chef-user-data/#{user[:name]}.pem" do
    owner 'root'
    group 'root'
    mode '0600'
    action :create
  end

  chef_server_user user[:name] do
    sensitive true
    firstname user[:first]
    lastname user[:last]
    email user[:email]
    password node.run_state['chef-users'][user[:name]]['password']
    private_key_path "/home/chef-user-data/#{user[:name]}.pem"
    action :create
    notifies :create, "file[/home/chef-user-data/#{user[:name]}.password]", :immediately # rubocop:disable LineLength
  end
end

node['chef-server']['orgs'].each do |org|
  chef_server_org org[:name] do
    org_long_name org[:long_name]
    org_private_key_path "/etc/opscode/#{org[:name]}-validator.pem"
    admins org[:admins]
    action [:create, :add_admin]
  end
end

file '/etc/opscode/encrypted_data_bag_secret' do
  sensitive true
  content gen_secret_key
  owner 'root'
  group 'root'
  mode '0600'
  not_if { File.exist?('/etc/opscode/encrypted_data_bag_secret') }
end

chef_vault_secret node.chef_environment do
  sensitive true
  data_bag 'chef-secrets'
  raw_data(gather_secrets)
  admins node.name
  clients "chef_environment:#{node.chef_environment}"
  search "chef_environment:#{node.chef_environment}"
end

# Delivery data bag
chef_data_bag 'keys' do
  action :create
end

chef_data_bag_item 'keys/delivery_builder_keys' do
  action :create
  secret_path '/etc/chef/encrypted_data_bag_secret'
  encryption_version 3
  raw_data lazy { { delivery_pem: IO.read('/home/chef-user-data/delivery.pem') } } # rubocop:disable LineLength
end
