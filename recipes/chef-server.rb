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
#
# rubocop:disable LineLength

require 'securerandom'

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

  user user[:name] do
    comment "#{user[:first]} #{user[:last]}"
    shell '/bin/bash'
    home "/home/#{user[:name]}"
    password node.run_state['chef-users'][user[:name]]['password']
    action :create
  end

  file "/home/#{user[:name]}/.password" do
    sensitive true
    content node.run_state['chef-users'][user[:name]]['password']
    owner user[:name]
    group user[:name]
    mode '0600'
    action :nothing
  end

  file "/home/#{user[:name]}/#{user[:name]}.pem" do
    owner user[:name]
    group user[:name]
    mode '0600'
    action :create
  end

  chef_server_user user[:name] do
    sensitive true
    firstname user[:first]
    lastname user[:last]
    email user[:email]
    password node.run_state['chef-users'][user[:name]]['password']
    private_key_path "/home/#{user[:name]}/#{user[:name]}.pem"
    action :create
    notifies :create, "file[/home/#{user[:name]}/.password]", :immediately
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

execute 'Delivery ssh keys' do
  user 'delivery'
  creates '/home/delivery/.ssh/builder_key.pub'
  command 'ssh-keygen -t rsa -q -f /home/delivery/.ssh/builder_key -P ""'
end

chef_vault_secret node.chef_environment do
  sensitive true
  data_bag 'chef-secrets'
  raw_data(gather_secrets)
  admins node.name
  clients "chef_environment:#{node.chef_environment}"
  search "chef_environment:#{node.chef_environment}"
end

# rubocop:enable LineLength
