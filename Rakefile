require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

begin
  require 'foodcritic'

  FoodCritic::Rake::LintTask.new do |task|
    task.options = { :fail_tags => [ 'any' ] }
  end

  task :default => [ :foodcritic, :spec ]
rescue LoadError
  task :default => [ :spec ]
end
