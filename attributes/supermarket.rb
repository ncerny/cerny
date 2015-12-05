#
# Cookbook Name:: cerny
# Attribute:: supermarket
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

default['supermarket_omnibus']['config'] = <<-EOF
  nginx['ssl_certificate'] = '/etc/supermarket/supermarket.cerny.cc/fullchain.pem'
  nginx['ssl_certificate_key'] = '/etc/supermarket/supermarket.cerny.cc/privkey.pem'
  nginx['ssl_ciphers'] = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
  nginx['ssl_protocols'] = "TLSv1.2"
EOF
