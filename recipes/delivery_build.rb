#
# Cookbook Name:: cerny
# Recipe:: delivery_build
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

directory '/etc/delivery' do
  recursive true
end

deliverybag = data_bag_item('keys', 'delivery_builder_keys')

file '/etc/delivery/delivery.pem' do
  content deliverybag['delivery_pem']
  mode '0600'
end

file '/etc/delivery/builder_key' do
  content deliverybag['builder_key']
  mode '0600'
end

directory '/var/opt/delivery/license' do
  recursive true
end

cookbook_file '/var/opt/delivery/license/delivery.license' do
  source 'delivery.license'
end

directory '/var/opt/delivery/workspace/etc/' do
  recursive true
end

directory '/var/opt/delivery/workspace/.chef' do
  recursive true
end

link '/var/opt/delivery/workspace/etc/builder_key' do
  to '/etc/delivery/builder_key'
end

link '/var/opt/delivery/workspace/etc/delivery.pem' do
  to '/etc/delivery/delivery.pem'
end

link '/var/opt/delivery/workspace/.chef/builder_key' do
  to '/etc/delivery/builder_key'
end

link '/var/opt/delivery/workspace/.chef/delivery.pem' do
  to '/etc/delivery/delivery.pem'
end

execute 'knife ssl fetch https://delivery.cerny.cc' do
  not_if 'knife ssl check https://delivery.cerny.cc'
end

include_recipe 'delivery_build'
include_recipe 'push-jobs'
