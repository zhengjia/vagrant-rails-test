Introduction
------------
Vagrant box configured with necessary chef cookbooks to run rails test suites with ruby 2.0.0, ruby 1.9.3, jruby, and rbx.

Usage
-----

* Install VirtualBox and Vagrant http://vagrantup.com/docs/getting-started/index.html
* Add a base box. Run `vagrant box add precise64 http://files.vagrantup.com/precise64.box`
* git clone git://github.com/zhengjia/vagrant-rails-test.git
* cd vagrant-rails-test
* vagrant up
* vagrant ssh
* cd /vagrant/rails
* bundle install
* bundle exec rake test

Issues:
* rbenv has a compatibility issue with rbx, so rbenv isn't used: https://github.com/sstephenson/rbenv/issues/178
* RBX is 1.8 by default. Use `RBXOPT=-X19` environment variable for 1.9.  