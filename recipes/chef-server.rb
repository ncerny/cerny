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

  file "/etc/opscode/#{user[:name]}.password" do
    sensitive true
    content node.run_state['chef-users'][user[:name]]['password']
    action :nothing
  end

  chef_server_user user[:name] do
    sensitive true
    firstname user[:first]
    lastname user[:last]
    email user[:email]
    password node.run_state['chef-users'][user[:name]]['password']
    private_key_path "/etc/opscode/#{user[:name]}.pem"
    action :create
    notifies :create, "file[/etc/opscode/#{user[:name]}.password]", :immediately
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

node.run_state['chef-server-secrets'] = { 'id' => node.chef_environment }

ruby_block 'gather chef-server secrets' do
  sensitive true
  block do
    files = Dir.glob('/etc/opscode*/*.{rb,pem,pub,json}')
    files.each do |file|
      node.run_state['chef-server-secrets'][file] = IO.read(file)
    end
  end
  action :run
end

chef_vault_secret node.chef_environment do
  sensitive true
  data_bag 'chef-server-secrets'
  raw_data(node.run_state['chef-server-secrets'])
  admins node.name
  clients "chef_environment:#{node.chef_environment}"
  search "chef_environment:#{node.chef_environment}"
  only_if { File.exist?('/etc/opscode/private-chef-secrets.json') }
end

# rubocop:enable LineLength
