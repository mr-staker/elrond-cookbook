desc 'Runs cookstyle'
task :lint do
  sh 'cookstyle'
end

desc 'Runs concurrent kitchen verify'
task :verify do
  sh 'kitchen verify -c'
end

desc 'Cleanup project'
task :clean do
  sh 'kitchen destroy -c'
  rm_rf '.kitchen'
end
