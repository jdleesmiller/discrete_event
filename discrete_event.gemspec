# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'discrete_event/version'
 
Gem::Specification.new do |s|
  s.name              = 'discrete_event'
  s.version           = DiscreteEvent::VERSION
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['John Lees-Miller']
  s.email             = ['jdleesmiller@gmail.com']
  s.homepage          = 'http://github.com/jdleesmiller/discrete_event'
  s.summary = %Q{Event-based discrete event simulation.}
  s.description = %Q{Some simple primitives for event-based discrete event simulation.}

  s.rubyforge_project = 'discrete_event'

  s.add_runtime_dependency "pqueue", "~> 1.0.0"
  s.add_development_dependency 'gemma', '~> 2.0.0'

  s.files       = Dir.glob('{lib,bin}/**/*.rb') + %w(README.rdoc)
  s.test_files  = Dir.glob('test/discrete_event/*_test.rb')
  s.executables = Dir.glob('bin/*').map{|f| File.basename(f)}

  s.rdoc_options = [
    "--main",    "README.rdoc",
    "--title",   "#{s.full_name} Documentation"]
  s.extra_rdoc_files << "README.rdoc"
end

