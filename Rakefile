task 'default' => 'info'
task all_test: %i[test rubocop]

desc 'Execute `sls info`'
task :info do
  system 'sls info'
end

desc 'Execute `sls deploy`'
task :deploy do
  system 'sls deploy'
end

desc 'Execute `sls invoke` with test.json'
task invoke: [:deploy] do
  system 'sls invoke --function=cloner --path=test.json'
end

desc 'Execute `sls local invoke` with test.json'
task :local_invoke, [:function] do |task, args|
  system "sls invoke local --function=#{args[:function]} --path=test.json"
end

desc 'Execute `sls remove`'
task :remove  do
  system 'sls remove'
end

desc 'Execute Test'
task :test do
  Dir.glob('./test/*_test.rb').each { |file| require file }
end

desc 'Execute Rubocop'
task :rubocop do
  system 'bundle exec rubocop'
end
