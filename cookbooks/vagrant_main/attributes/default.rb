set['rvm']['rubies']                 = ['ruby-2.0.0-p0', 'ruby-1.9.3-p392', 'jruby-1.7.3', 'rbx']
set['rvm']['default_ruby']           = 'ruby-2.0.0-p0'
set['rvm']['upgrade']  = "stable"
set['rvm']['global_gems'] = [
  { 'name' => 'bundler' }
]

set['mysql']['server_root_password'] = ""

# https://github.com/opscode-cookbooks/postgresql#chef-solo-note
# set to md5 of empty string
set['postgresql']['password']['postgres'] = 'd41d8cd98f00b204e9800998ecf8427e'

set['postgresql']['pg_hba'] = [
  {:type => 'local', :db => 'all', :user => 'all', :addr => '', :method => 'trust'}
]