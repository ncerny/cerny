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

directory '/etc/delivery' do
  recursive true
end

directory '/var/opt/delivery/license' do
  recursive true
end

write_secrets('/etc/delivery')

cookbook_file '/var/opt/delivery/license/delivery.license' do
  source 'delivery.license'
end

chef_ingredient 'delivery' do
  config <<-EOS
delivery_fqdn "#{node['fqdn']}"
delivery['chef_username']    = "delivery"
delivery['chef_private_key'] = "/etc/delivery/delivery.pem"
delivery['chef_server']      = "https://chef.cerny.cc/organizations/chef_delivery"
delivery['default_search']   = "((recipes:delivery_build OR recipes:delivery_build\\\\\\\\:\\\\\\\\:default) AND chef_environment:#{node.chef_environment})"
  EOS
  channel :stable
  version node['delivery']['version']
  action :install
end

ingredient_config 'delivery' do
  notifies :reconfigure, 'chef_ingredient[delivery]', :immediately
end
