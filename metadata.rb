name 'cerny'
maintainer 'Nathan Cerny'
maintainer_email 'ncerny@gmail.com'
license 'apache2'
description 'Cookbook for Maintaining Cerny Infrastructure'
long_description 'Installs and maintains my personal infrastructure'
version '0.5.3'

supports 'redhat'

depends 'chef-server'
depends 'chef-server-ctl'
depends 'firewalld'
depends 'chef-vault'
depends 'chef-analytics'
depends 'supermarket-omnibus-cookbook'
depends 'push-jobs'
depends 'delivery_build'
