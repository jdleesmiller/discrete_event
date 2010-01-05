require 'rubygems'
require 'rake'
require 'erb'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "discrete_event"
    gem.summary = %Q{Event-based discrete event simulation.}
    gem.description = %Q{Some simple primitives for event-based discrete event simulation.}
    gem.email = "jdleesmiller@gmail.com"
    gem.homepage = "http://github.com/jdleesmiller/discrete_event"
    gem.authors = ["John Lees-Miller"]
    gem.add_development_dependency "yard", ">= 0"
    gem.add_dependency "pqueue", ">= 1.0.0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', '-', 'LICENSE']
  end
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "discrete_event #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

file "README.rdoc" => ["make_readme.erb"] + Dir["test/ex_*.rb"] do |t|
  File.open(t.name, 'w') do |f|
    f.puts(ERB.new(File.read(t.prerequisites.first)).result)
  end
end 
task :yard => "README.rdoc"
task :rdoc => "README.rdoc"

