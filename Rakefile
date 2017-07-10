# frozen_string_literal: true

require 'erb'
require 'rubygems'
require 'bundler/setup'
require 'gemma'

Gemma::RakeTasks.with_gemspec_file 'discrete_event.gemspec'

task default: :test

file 'README.rdoc' => ['make_readme.erb'] + Dir['test/ex_*.rb'] do |t|
  File.open(t.name, 'w') do |f|
    f.puts(ERB.new(File.read(t.prerequisites.first)).result)
  end
end

task yard: 'README.rdoc'
task rdoc: 'README.rdoc'
