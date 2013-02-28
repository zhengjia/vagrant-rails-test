ENV['LANGUAGE'] = ENV['LANG'] = ENV['LC_ALL'] = "en_US.UTF-8"
require_recipe 'apt'
require_recipe 'git'
require_recipe 'openssl'
require_recipe "build-essential"
require_recipe "java"
require_recipe "vagrant_main::packages"
require_recipe "rvm::system"
require_recipe "rvm::vagrant"
require_recipe "sqlite"
require_recipe "mysql::server"
require_recipe "postgresql::server"
require_recipe "memcached"

node['rvm']['rubies'].each do |ruby|
  rvm_shell "Bundle for #{ruby}" do
    ruby_string ruby
    cwd         "/vagrant/rails"
    if !ruby.include?('rbx')
      code      "bundle install"
    else  
      code      "RBXOPT=-X19 bundle install"  
    end  
  end
end  

# modify from https://github.com/jeroenvandijk/rails_test_box
mysql_shell = "/usr/bin/mysql -u root"
cookbook_file "/tmp/rails_mysql_user_grants.sql"
execute "Create Mysql Rails user" do
  command "#{mysql_shell} < /tmp/rails_mysql_user_grants.sql"
  not_if %[echo "select User from mysql.user" | #{mysql_shell} | grep rails]
end

rvm_shell "Build mysql databases" do
  ruby_string node['rvm']['default_ruby']
  cwd "/vagrant/rails/activerecord"
  code "bundle exec rake mysql:build_databases"
  not_if %[echo "show databases" | #{mysql_shell} | grep activerecord]
end

rvm_shell "Build postgresql databases" do
  ruby_string node['rvm']['default_ruby']
  user 'postgres'
  cwd "/vagrant/rails/activerecord"
  code "/usr/local/rvm/bin/rake postgresql:build_databases"
  not_if %[echo "select datname from pg_database" | psql | grep activerecord]
end