# This Rakefile helps manage the lifecycle of cookbook development.
require 'aws-sdk'
namespace :repository do
  cookbook_path = ENV['RAKE_COOKBOOK_PATH']
  cookbook_name = ::File.read('NAME').strip
  task :full_sync do
    %w{repository:pull repository:up_minor_version repository:sync_berkshelf repository:git_commit_and_push}.each do |task|
      Rake::Task[task].invoke
    end
  end
  task :pull do
    `git pull`
  end
  task :tags do
    system 'git tag'
  end
  task :git_commit_and_push do
    commit = <<-EOH
    git add -f *
    git add ./*
    git commit -a -m "commit for version #{::File.read('VERSION').strip}"
    git tag -a #{::File.read('VERSION').strip} -m "version release #{::File.read('VERSION').strip}"
    git push origin #{`git rev-parse --abbrev-ref HEAD`}
    git push origin #{::File.read('VERSION').strip}
    git commit -a -m "commit for version #{::File.read('VERSION').strip}"
    EOH
    system "#{commit}"
  end
  task :up_minor_version do
    stripped = ::File.read('VERSION').strip
    new_minor = stripped.split('.')[-1].to_i
    new_minor += 1
    new_minor_string = new_minor.to_s
    new_minor = new_minor_string.to_s
    new_version = stripped.split('.')[0..-2]
    new_version << new_minor_string
    version = new_version.join('.')
    match = stripped
    replace = version
    file = 'VERSION'
    system 'rm -rf VERSION'
    system 'rm -rf .kitchen.yml'
    ::File.write('VERSION', version.strip)
    puts "Version upped to #{version.strip}"
  end
  task :sync_berkshelf do
    system 'rm -rf Berksfile.lock && berks install && berks update'
  end
  task :supermarket do
    system <<-EOH
    knife cookbook site share #{cookbook_name} "Other" -o #{cookbook_path}
    EOH
  end
  task :kitchen_yml_workaround => 'kitchen:kitchen_yml_workaround'
  task :publish => [:kitchen_yml_workaround, :up_minor_version, :sync_berkshelf, :git_commit_and_push, :supermarket, :kitchen_yml_workaround]
  task :commit => [:kitchen_yml_workaround, :sync_berkshelf, :git_commit_and_push, :kitchen_yml_workaround]
  task :revert, [:arg1] do |t, args|
    system "git reset --hard \"#{args[:arg1]}\""
  end
end
namespace :kitchen do
  task :berks => 'repository:sync_berkshelf'
  task :sync_berkshelf => 'repository:sync_berkshelf'
  task :destroy do
    Rake::Task['special:wipe'].invoke
    system 'kitchen destroy'
    Rake::Task['special:wipe'].invoke
  end
  task :test do
    Rake::Task['kitchen:destroy'].invoke
    system 'kitchen test'
  end
  task :converge do
    system 'kitchen converge'
  end
  task :kitchen_yml_workaround do
# Because environment variables and a .kitchen.yml don't mix
    content = <<-YAML
---
driver:
  name: ec2
  aws_ssh_key_id: <%= ENV['KITCHEN_AWS_KEY'] %>
  security_group_ids: [<%= ENV['KITCHEN_SECURITY_GROUP'] %>]
  region: <%= ENV['KITCHEN_AWS_REGION'] %>
  availability_zone: <%= ENV['KITCHEN_AWS_AVAILABILITY_ZONE'] %>
  require_chef_omnibus: <%= ENV['KITCHEN_OMNIBUS_BOOL'] %>
  subnet_id: <%= ENV['KITCHEN_SUBNET'] %>
  iam_profile_name: <%= ENV['KITCHEN_IAM'] %>
  instance_type: <%= ENV['KITCHEN_SIZE'] %>
  associate_public_ips: <%= ENV['KITCHEN_PUBLIC_IP_BOOL'] %>
  interface: <%= ENV['KITCHEN_NETWORK_INTERFACE'] %>
  tags:
    Name: <%= ENV['KITCHEN_INSTANCE_NAME_TAG'] %>
    Cookbook: #{::File.read('NAME').strip}
    Cookbook_Version: #{::File.read('VERSION').strip}
    Developer: #{`whoami`}

provisioner:
  name: <%= ENV['KITCHEN_PROVISIONER'] %>

transport:
  username: <%= ENV['KITCHEN_USERNAME'] %>
  ssh_key: <%= ENV['KITCHEN_PRIVATE_KEY_PATH'] %>

platforms:
  - name: <%= ENV['KITCHEN_EC2_PLATFORM'] %>
    driver:
      image_id: <%= ENV['KITCHEN_EC2_AMI'] %>

suites:
  - name: default
    run_list:
      - recipe[#{::File.read('NAME').strip}::default]
    attributes:
  YAML
  system 'rm -rf .kitchen.yml'
  ::File.write('.kitchen.yml', content)
  end
  # Sometimes you just gotta use a local .kitchen.yml
  task :kitchen_local_file_replace do
    system 'rm -rf .kitchen.yml'
    content = <<-EOH
---
driver:
  name: vagrant
provisioner:
  name: chef_zero
platforms:
  - name: centos-7.2
    suites:
      - name: default
        run_list:
          - recipe[#{::File.read('NAME').strip}::default]
        attributes:
    EOH
    system 'rm -rf .kitchen.yml'
    ::File.write('.kitchen.yml', content)
  end
  task :reconverge => [:kitchen_yml_workaround, :sync_berkshelf, :destroy, :converge]
  task :local => [:kitchen_local_file_replace]
end
namespace :notifications do
  task :status do
    puts "Cookbook Name: #{::File.read('NAME')}"
    puts "Cookbook Version: #{::File.read('VERSION')}"
    puts "Resources Defined:"
    `ls libraries`.split.each do |resource|
      puts "  #{resource}"
    end
    puts "Templates Defined:"
    `ls templates/default`.split.each do |template|
      puts "  #{template}"
    end
    puts "Files Defined:"
    `ls files/default`.split.each do |template|
      puts "  #{template}"
    end
    puts "Libraries Defined:"
    `ls libraries`.split.each do |lib|
      puts "  #{lib}"
    end
    puts "Relevant cookbook environment variables:"
    not_defined = 0
    [
      {:name => 'RAKE_COOKBOOK_PATH'},
      {:name => 'KITCHEN_AWS_KEY'},
      {:name => 'KITCHEN_SECURITY_GROUP'},
      {:name => 'KITCHEN_AWS_REGION'},
      {:name => 'KITCHEN_AWS_AVAILABILITY_ZONE'},
      {:name => 'KITCHEN_OMNIBUS_BOOL'},
      {:name => 'KITCHEN_SUBNET'},
      {:name => 'KITCHEN_IAM'},
      {:name => 'KITCHEN_SIZE'},
      {:name => 'KITCHEN_PUBLIC_IP_BOOL'},
      {:name => 'KITCHEN_NETWORK_INTERFACE'},
      {:name => 'KITCHEN_INSTANCE_NAME_TAG'},
      {:name => 'KITCHEN_PROVISIONER'},
      {:name => 'KITCHEN_USERNAME'},
      {:name => 'KITCHEN_PRIVATE_KEY_PATH'},
      {:name => 'KITCHEN_EC2_PLATFORM'},
      {:name => 'KITCHEN_EC2_AMI'},
      {:name => 'AWS_REGION'},
      {:name => 'CODE_GENERATOR_PATH'},
    ].each do |evar|
      if ENV[evar[:name]]
        puts "  #{evar[:name]} --> #{ENV[evar[:name]]}"
      else
        puts "  #{evar[:name]} not defined, please define it."
        not_defined += 1
      end
    end
    if not_defined < 1
      puts ""
      puts "All checked values were defined.  This is a good thing."
    else
      puts "#{not_defined} variables not defined, some things related to kitchen and cookbooks may break"
    end
  end
end
namespace :special do
  task :clear, :absolutely do |t, args|
    def destroy
      resource = Aws::EC2::Resource.new
      destroyed = 0
      resource.instances({:filters => [{name: 'tag:Name', values: ['KitchenTest']}]}).each do |instance|
        response = instance.terminate(dry_run: false)
        if response.successful?
          destroyed += 1
        end
      end
      if destroyed > 0
        puts "Ran a check for extra instances related to all Name::KitchenTest tags #{destroyed} were sent a terminate signal"
      end
    end
    unless args[:absolutely]
      puts 'You must absolutely want to execute this as it will kill all kitchen instances for EVERYONE and all instances you have permission to access'
      puts 'Usage:: rake special:clear[:absolutely]'
      puts 'You should only do this if you are absolutely sure...'
    else
      destroy
    end
  end
  task :myself do
    destroyed = 0
    resource = Aws::EC2::Resource.new
    resource.instances({:filters => [{name: 'tag:Owner', values: [ENV['USER']]}]}).each do |instance|
      puts instance
    end
    resource.instances({:filters => [{name: 'tag:Owner', values: [ENV['USER']]}, {name: 'tag:Name', values: ['KitchenTest']}]}).each do |instance|
      puts instance
      puts instance.name
      puts instance.id
      response = instance.terminate(dry_run: false)
      if response.successful?
        destroyed += 1
      end
    end
    if destroyed > 0
      puts "Ran a check for extra instances related to all Name::KitchenTest tags #{destroyed} were sent a terminate signal"
    end
  end
  task :relink do
    if ENV['CODE_GENERATOR_PATH']
      system "rm -rf Rakefile && ln -s #{::File.join(ENV['CODE_GENERATOR_PATH'], 'files', 'default', 'Rakefile')} Rakefile"
    else
      puts "You should have CODE_GENERATOR_PATH defined to do this, aborting..."
    end
  end
  # Sometimes kitchen doesn't clean up after itself, this task can be added anywhere you want an extra cleanup check
  task :wipe do
    resource = Aws::EC2::Resource.new
    destroyed = 0
    resource.instances({:filters => [{name: 'tag:Cookbook', values: [::File.read('NAME').strip]}]}).each do |instance|
      puts instance.id
      response = instance.terminate(dry_run: false)
      if response.successful?
        destroyed += 1
      end
    end
    if destroyed > 0
      puts "Ran a check for extra instances related to cookbook #{::File.read('NAME').strip} and #{destroyed} were sent a terminate signal, these may have been previously terminated"
    end
  end
end

############################################## main task interface
# Prints the general status of the cookbook
task :default => 'notifications:status'
# Explicit version of the same call
task :status => 'notifications:status'
# Commits to git, pushes, git tags version
task :commit => 'repository:commit'
# Git pulls, creates berks files, gets cookbook dependencies from supermarket via berkshelf
task :sync => 'repository:full_sync'
# Cycle berkshelf, destroy kitchen test node, recreate kitchen test node with fully updated dependencies
task :converge => 'kitchen:reconverge'
# This exists because I have a habit to say reconverge but they are really the same thing
task :reconverge => 'kitchen:reconverge'
# Does a kitchen destroy command but also sends backup API calls targetting the cookbook tag to destroy any instances kitchen misses sometimes.  Really helps with the AWS bill.
task :destroy => 'kitchen:destroy'
# If you wanna use kitchen with vagrant, this will give you a base config
task :local => 'kitchen:local'
# Hook reserved for kitchen test and any extra functionality needed to be wrapped here.
task :test => 'kitchen:test'
# Publishes to public supermarket or supermarket otherwise noted in ~/.chef/knife.rb
task :publish => 'repository:publish'
# When you use the cookbook generator a real Rakefile is placed in the repository, alternatively you could link from a central Rakefile that is git revisioned from the cookbook generator.
# This task looks for a CODE_GENERATOR_PATH environment variable that indicates the path to the code generator containing the Rakefile in CODE_GENERATOR_PATH/files/default/Rakefile and links it to the current cookbook repository
task :relinkage => 'special:relink'
# use like rake repository:revert['1.3.2'] to revert repository to its 1.3.2 git tagged version state.
task :revert, [:arg1] => 'repository:revert'
# issues a git tag to list available git tags to revert to
task :tags => 'repository:tags'
# Wipes all instances with the cookbook name from which this was executed.
task :wipe => 'special:wipe'
# Causes a berks cycle and dep resolution
task :berks => 'kitchen:berks'
# ups minor version of VERSION file and therefore everything else as well that uses the ::File.read('VERSION').strip references.
task :version => 'repository:up_minor_version'
# A VERY DANGEROUS/POWERFUL/DESTRUCTIVE COMMAND.  Will look for KitchenTest in Name tags of all servers in the AWS_REGION and terminate them.  Good for making sure all test instances are down at the end of the day.
task :clear => 'special:clear'
task :myself => 'special:myself'
