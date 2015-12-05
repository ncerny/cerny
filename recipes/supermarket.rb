#
# Cookbook Name:: cerny
# Recipe:: supermarket
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

include_recipe 'firewalld'

firewalld_service 'https' do
  zone 'public'
  notifies :reload, 'service[firewalld]', :delayed
end

supermarket = JSON.load(load_secrets['/etc/opscode']['/etc/opscode/oc-id-applications/supermarket.json']) # rubocop:disable LineLength

directory '/etc/supermarket/supermarket.cerny.cc' do
  owner 'root'
  group 'root'
  mode '0700'
end

cookbook_file '/etc/supermarket/supermarket.cerny.cc/fullchain.pem' do
  source 'fullchain.pem'
end

cookbook_file '/etc/supermarket/supermarket.cerny.cc/privkey.pem' do
  source 'privkey.pem'
end

supermarket_server 'supermarket' do
  chef_server_url 'https://chef.cerny.cc'
  chef_oauth2_app_id supermarket['uid']
  chef_oauth2_secret supermarket['secret']
  chef_oauth2_verify_ssl false
  config node['supermarket_omnibus']['config'].to_hash
end
