lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'rifle/version'
require 'rifle'

Gem::Specification.new do |s|
  s.name = 'rifle'
  s.version = Rifle::VERSION
  s.authors = ['Harry Lascelles']
  s.email = ['harry@harrylascelles.com']
  s.hompage = 'https://github.com/firstbanco/rifle'
  s.summary = 'Redis search server'

  s.files = Dir["{app,lib}/**/*"] + ["README.md"]
  s.require_paths = ['lib']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails'
  s.add_dependency 'redis'
  s.add_dependency 'text'
  s.add_dependency 'resque'
  s.add_dependency 'rest-client'
  s.add_dependency 'session_off'
  s.add_dependency 'fitter-happier'
  s.add_dependency 'lograge'
end