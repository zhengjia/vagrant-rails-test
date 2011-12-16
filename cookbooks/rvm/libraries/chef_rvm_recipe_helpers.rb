#
# Cookbook Name:: rvm
# Library:: Chef::RVM::RecipeHelpers
#
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2011, Fletcher Nichol
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

class Chef
  module RVM
    module RecipeHelpers
      def build_script_flags(version, branch)
        script_flags = ""
        script_flags += " --version #{version}" if version
        script_flags += " --branch #{branch}"   if branch
        script_flags
      end

      def build_upgrade_strategy(strategy)
        if strategy.nil? || strategy == false
          "none"
        else
          strategy
        end
      end

      def install_pkg_prereqs(install_now = node.recipe?("rvm::gem_package"))
        return if mac_with_no_homebrew

        node['rvm']['install_pkgs'].each do |pkg|
          p = package pkg do
            # excute in compile phase if gem_package recipe is requested
            if install_now
              action :nothing
            else
              action :install
            end
          end
          p.run_action(:install) if install_now
        end
      end

      def install_rvm(opts = {})
        install_now = node.recipe?("rvm::gem_package")

        if opts[:user]
          user_dir    = opts[:rvm_prefix]
          exec_name   = "install user RVM for #{opts[:user]}"
          exec_env    = { 'USER' => opts[:user], 'HOME' => user_dir }
        else
          user_dir    = nil
          exec_name   = "install system-wide RVM"
          exec_env    = nil
        end

        i = execute exec_name do
          user    opts[:user] || "root"
          command <<-CODE
            bash -c "bash \
              <( curl -Ls #{opts[:installer_url]} )#{opts[:script_flags]}"
          CODE
          environment(exec_env)

          # excute in compile phase if gem_package recipe is requested
          if install_now
            action :nothing
          else
            action :run
          end

          not_if  rvm_wrap_cmd(
            %{type rvm | head -1 | grep -q '^rvm is a function$'}, user_dir)
        end
        i.run_action(:run) if install_now
      end

      def upgrade_rvm(opts = {})
        install_now = node.recipe?("rvm::gem_package")

        if opts[:user]
          user_dir    = opts[:rvm_prefix]
          exec_name   = "upgrade user RVM for #{opts[:user]} to " +
                        opts[:upgrade_strategy]
          exec_env    = { 'USER' => opts[:user], 'HOME' => user_dir }
        else
          user_dir    = nil
          exec_name   = "upgrade system-wide RVM to " +
                        opts[:upgrade_strategy]
          exec_env    = nil
        end

        u = execute exec_name do
          user      opts[:user] || "root"
          command   rvm_wrap_cmd(%{rvm get #{opts[:upgrade_strategy]}}, user_dir)
          environment(exec_env)

          # excute in compile phase if gem_package recipe is requested
          if install_now
            action :nothing
          else
            action :run
          end

          only_if   { %w{ latest head }.include?(opts[:upgrade_strategy]) }
        end
        u.run_action(:run) if install_now
      end

      def rvmrc_template(opts = {})
        install_now = node.recipe?("rvm::gem_package")

        if opts[:user]
          system_install  = false
          rvmrc_file      = "#{opts[:rvm_prefix]}/.rvmrc"
          rvm_path        = "#{opts[:rvm_prefix]}/.rvm"
        else
          system_install  = true
          rvmrc_file      = "/etc/rvmrc"
          rvm_path        = "#{opts[:rvm_prefix]}/rvm"
        end

        t = template rvmrc_file do
          source      "rvmrc.erb"
          owner       opts[:user] || "root"
          mode        "0644"
          variables   :system_install   => system_install,
                      :rvm_path         => rvm_path,
                      :rvm_gem_options  => opts[:rvm_gem_options],
                      :rvmrc            => opts[:rvmrc]

          # excute in compile phase if gem_package recipe is requested
          if install_now
            action :nothing
          else
            action :create
          end
        end
        t.run_action(:create) if install_now
      end

      def install_rubies(opts = {})
        # install additional rubies
        opts[:rubies].each do |rubie|
          rvm_ruby rubie do
            user  opts[:user]
          end
        end

        # set a default ruby
        rvm_default_ruby opts[:default_ruby] do
          user  opts[:user]
        end

        # install global gems
        opts[:global_gems].each do |gem|
          rvm_global_gem gem[:name] do
            user      opts[:user]
            [:version, :action, :options, :source].each do |attr|
              send(attr, gem[attr]) if gem[attr]
            end
          end
        end

        # install additional gems
        opts[:gems].each_pair do |rstring, gems|
          rvm_environment rstring do
            user  opts[:user]
          end

          gems.each do |gem|
            rvm_gem gem[:name] do
              ruby_string   rstring
              user          opts[:user]
              [:version, :action, :options, :source].each do |attr|
                send(attr, gem[attr]) if gem[attr]
              end
            end
          end
        end
      end

      private

      def mac_with_no_homebrew
        node['platform'] == 'mac_os_x' &&
          Chef::Platform.find_provider_for_node(node, :package) !=
          Chef::Provider::Package::Homebrew
      end
    end
  end
end
