require 'rake/clean'
require 'erb'

begin
  require 'rubygems'
  require 'gemma'

  Gemma::RakeTasks.with_gemspec_file 'discrete_event.gemspec'
rescue LoadError
  puts 'Install gemma (sudo gem install gemma) for more rake tasks.'
end

task :default => :test

#require 'rake/testtask'
#Rake::TestTask.new(:test) do |test|
#  test.libs << 'lib' << 'test'
#  test.pattern = 'test/**/test_*.rb'
#  test.verbose = true
#end
#
#begin
#  require 'rcov/rcovtask'
#  Rcov::RcovTask.new do |test|
#    test.libs << 'test'
#    test.pattern = 'test/**/test_*.rb'
#    test.verbose = true
#  end
#rescue LoadError
#  task :rcov do
#    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
#  end
#end
#
#task :test => :check_dependencies
#

#begin
#  require 'yard'
#  YARD::Rake::YardocTask.new do |t|
#    t.files = ['lib/**/*.rb', '-', 'LICENSE']
#  end
#rescue LoadError
#  task :yardoc do
#    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
#  end
#end
#
#require 'rake/rdoctask'
#Rake::RDocTask.new do |rdoc|
#  version = File.exist?('VERSION') ? File.read('VERSION') : ""
#
#  rdoc.rdoc_dir = 'rdoc'
#  rdoc.title = "discrete_event #{version}"
#  rdoc.rdoc_files.include('README*')
#  rdoc.rdoc_files.include('LICENSE')
#  rdoc.rdoc_files.include('lib/**/*.rb')
#end

file "README.rdoc" => ["make_readme.erb"] + Dir["test/ex_*.rb"] do |t|
  File.open(t.name, 'w') do |f|
    f.puts(ERB.new(File.read(t.prerequisites.first)).result)
  end
end 

task :yard => "README.rdoc"
task :rdoc => "README.rdoc"

