Introduction
------------
Vagrant box configured with necessary chef cookbooks to run rails test suites with ruby 1.9.2, ree, jruby, and rbx.

Usage
-----

* Install VirtualBox and Vagrant http://vagrantup.com/docs/getting-started/index.html
* git clone git@github.com:zhengjia/vagrant-rails-test.git
* cd vagrant-rails-test
* vagrant up
* vagrant ssh
* cd /vagrant/rails
* rake test

Tested with Vagrant 0.8