require_recipe 'apt'
require_recipe 'gems'
require_recipe 'git'
require_recipe 'openssl'
require_recipe "build-essential"
require_recipe "java"
require_recipe "rvm"
require_recipe "rvm::vagrant"
require_recipe "sqlite"
require_recipe "mysql::server"
require_recipe "postgresql::server"
require_recipe "memcached"

# modify from https://github.com/jeroenvandijk/rails_test_box
mysql_shell = "/usr/bin/mysql -u root"
cookbook_file "/tmp/rails_mysql_user_grants.sql"
execute "Create Mysql Rails user" do
  command "#{mysql_shell} < /tmp/rails_mysql_user_grants.sql"
  not_if %[echo "select User from mysql.user" | #{mysql_shell} | grep rails]
end

execute "Create postgres vagrant user" do
  user "postgres"
  command "/usr/bin/createuser vagrant --superuser"
  not_if %[echo "select usename from pg_user" | psql | grep vagrant], :user => 'postgres'
end

# pg gem dependency
package "libpq-dev"
node['rvm']['rubies'].each do |platform|
  rvm_shell "Install rails dependencies for #{platform}" do
    ruby_string platform
    cwd         "/vagrant/rails"
    code        "bundle install"
  end
end  

execute "Build mysql databases" do
  cwd "/vagrant/rails/activerecord"
  command "rake mysql:build_databases"
  not_if %[echo "show databases" | #{mysql_shell} | grep activerecord]
end

execute "Build postgresql databases" do
  user "vagrant"
  cwd "/vagrant/rails/activerecord"
  command "rake postgresql:build_databases"
  not_if %[echo "select datname from pg_database" | psql | grep activerecord], :user => 'postgres'
end