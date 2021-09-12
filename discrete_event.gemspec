# -*- encoding: utf-8 -*-
# frozen_string_literal: true

require 'English'

lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'discrete_event/version'

Gem::Specification.new do |s|
  s.name              = 'discrete_event'
  s.version           = DiscreteEvent::VERSION
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['John Lees-Miller']
  s.email             = ['jdleesmiller@gmail.com']
  s.homepage          = 'http://github.com/jdleesmiller/discrete_event'
  s.summary = 'Event-based discrete event simulation.'
  s.description = 'Some simple primitives for event-based discrete event
simulation.'

  s.rubyforge_project = 'discrete_event'

  s.add_runtime_dependency 'priority_queue_cxx', '~> 0.3.4'
  s.add_development_dependency 'gemma', '~> 5.0'
  s.add_development_dependency 'simplecov', '~> 0.14'

  s.files       = Dir.glob('{lib,bin}/**/*.rb') + %w[README.rdoc]
  s.test_files  = Dir.glob('test/discrete_event/*_test.rb')
  s.executables = Dir.glob('bin/*').map { |f| File.basename(f) }

  s.rdoc_options = [
    '--main',    'README.rdoc',
    '--title',   "#{s.full_name} Documentation"
  ]
  s.extra_rdoc_files << 'README.rdoc'
end
