# frozen_string_literal: true

require 'yaml'

desc 'Runs rubocop'
task :cop do
  sh 'rubocop'
end

desc 'Runs cookstyle and chefstyle'
task :lint do
  sh 'cookstyle'
  sh 'chefstyle'
end

desc 'Runs test for specifiedd instance and destroy'
task :test_instance, [:instance] do |_t, args|
  sh "kitchen verify #{args[:instance]}" # implies create and converge
  sh "kitchen destroy #{args[:instance]}"
end

desc 'Runs all tests in sequence and cleans up after every instance'
task :integration do
  kcfg = YAML.load_file '.kitchen.yml'
  kcfg['suites'].each do |pl|
    platform = pl['name']
    kcfg['platforms'].each do |su|
      suite = su['name']
      instance = "#{platform}-#{suite}"

      puts "Run integration test for #{instance}"
      Rake::Task[:test_instance].invoke instance
      Rake::Task[:test_instance].reenable
    end
  end

  Rake::Task[:clean].invoke
end

desc 'Runs concurrent kitchen verify'
task :verify do
  sh 'kitchen verify -c'
end

desc 'Runs complete test setup sequentially'
task test: %i[lint integration]

desc 'Runs complete test setup concurrently'
task test_multi: %i[lint verify clean]

desc 'Cleanup project'
task :clean do
  sh 'kitchen destroy -c'
  rm_rf '.kitchen'
end

def vagrant_task(tsk)
  desc "Wrap kitchen #{tsk} for vagrant"
  task tsk do
    sh "KITCHEN_LOCAL_YAML=.kitchen.vagrant.yml kitchen #{tsk}"
  end
end

namespace :vagrant do
  vagrant_task :status
  vagrant_task :create
  vagrant_task :converge
  vagrant_task :login
  vagrant_task :verify
  vagrant_task :destroy

  desc 'kitchen destroy & clean'
  task clean: %i[destroy] do
    rm_rf '.kitchen'
  end
end
