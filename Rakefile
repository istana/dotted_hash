require "bundler/gem_tasks"

desc 'Run tests'
task :test do
  puts
  puts '****** Test::Unit'
  
  Dir[File.join('test', "*unit.rb")].each do |unit|
    puts unit
    system("ruby #{unit}")
  end
  
  puts
  puts '****** RSpec'
  
  Dir[File.join('test', "*spec.rb")].each do |unit|
    puts unit
    system("rspec #{unit}")
  end
end