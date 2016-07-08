require 'poise'
require 'chef/resource'
require 'chef/provider'

module TestApp
  class Resource < Chef::Resource
    include Poise
    provides  :test_app
    actions   :install, :delete
    attribute :name, name_attribute: true
    attribute :user, default: 'root'
    attribute :group, default: 'root'
    attribute :mode, default: 0777
    attribute :app_dir, default: ::File.join('/apps/', 'myapp')
    attribute :template, default: 'app.erb'
    attribute :context, default: {:configuration => [
      {:key=> 'debug', :val => 'true'}
    ]}
  end
  class Provider < Chef::Provider
    include Poise
    provides :test_app
    def common
      directory new_resource.app_dir do
        recursive true
      end
    end
    def action_install
      common
      template "#{::File.join(new_resource.app_dir, new_resource.name)}" do
        user new_resource.user
        group new_resource.group
        mode new_resource.mode
        source new_resource.template
        variables :context => new_resource.context
      end
    end
    def action_delete
      common
      template "#{::File.join(new_resource.app_dir, new_resource.name)}" do
        action :delete
      end
    end
  end
end
