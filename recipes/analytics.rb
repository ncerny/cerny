#
# Cookbook Name:: cerny
# Recipe:: analytics
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

get_chef_secrets

include_recipe 'firewalld'

firewalld_service 'https' do
  zone 'public'
  notifies :reload, 'service[firewalld]', :delayed
end

include_recipe 'chef-analytics'

# rubocop:enable LineLength
