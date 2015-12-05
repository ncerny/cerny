# Cookbook Name:: cerny
# Attribute:: chef-server
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

default['chef-server']['version'] = nil
default['chef-server']['api_fqdn'] = 'chef.cerny.cc'
default['chef-server']['addons'] = %w(manage reporting) # push-server
default['chef-server']['configuration'] = <<-EOF
  oc_id['applications'] = {
    "analytics"=>{"redirect_uri"=>"https://analytics.cerny.cc/"},
    "supermarket"=>{"redirect_uri"=>"https://supermarket.cerny.cc/auth/chef_oauth2/callback"}
  }
  rabbitmq['vip'] = '192.168.200.50'
  rabbitmq['node_ip_address'] = '0.0.0.0'
  nginx['ssl_certificate'] = '/etc/opscode/chef.cerny.cc/fullchain.pem'
  nginx['ssl_certificate_key'] = '/etc/opscode/chef.cerny.cc/privkey.pem'
  nginx['ssl_ciphers'] = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
  nginx['ssl_protocols'] = "TLSv1.2"
EOF

default['chef-server']['users'] = [
  {
    name: 'ncerny',
    first: 'Nathan',
    last: 'Cerny',
    email: 'ncerny@gmail.com'
  },
  {
    name: 'delivery',
    first: 'Delivery',
    last: 'User',
    email: 'delivery@cerny.cc'
  }
]

default['chef-server']['orgs'] = [
  {
    name: 'cerny',
    long_name: 'cerny.cc infrastructure',
    admins: %w( ncerny )
  },
  {
    name: 'chef_delivery',
    long_name: 'Chef Delivery Organization',
    admins: %w( delivery )
  }
]

# rubocop:enable LineLength
