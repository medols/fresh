# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fresh-mc}
  s.version = "0.0.1" unless ENV['TRAVIS']
  s.version = "0.0.2-#{ENV['TRAVIS_BUILD_NUMBER']}" if ENV['TRAVIS']
  s.authors = ["Jaume Masip-Torne", "Ismael Merodio-Codinachs"]
  s.date = Time.now
  s.description = "Fresh gem for many-core processing"
  s.email = ["jmasip@gianduia.net", "ismael@gianduia.net"]
  s.files = Dir['{lib,examples}/**/*'] + Dir['{*.txt,*.gemspec,Rakefile}']
  s.homepage = "http://github.com/medols/fresh"
  s.require_paths = ["lib"]
  s.summary = "Fresh gem for many-core processing"
  s.add_dependency 'rubinius-actor'
  s.license = 'BSD 3-Clause'
end

