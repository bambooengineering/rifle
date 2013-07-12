lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'rifle/version'
require 'rifle'

Gem::Specification.new do |s|
  s.name = 'rifle'
  s.version = Rifle::VERSION
  s.authors = ['Harry Lascelles']
  s.email = ['harry@harrylascelles.com']
  s.homepage = 'https://github.com/firstbanco/rifle'
  s.summary = 'Redis search server'

  s.files = Dir["{app,lib}/**/*"] + ["README.md"]
  s.require_paths = ['lib']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails'
  s.add_dependency 'redis'
  s.add_dependency 'text'
  s.add_dependency 'resque'
  s.add_dependency 'rest-client'
  s.add_dependency 'fitter-happier'
  s.add_dependency 'lograge'
  # 0.5.0 breaks with Devise. Visiting '/' (expecting to get bumped to /users/sign_in) results in:
  # undefined local variable or method `session' for #<Devise::FailureApp:0x00000007e54500>
  # devise (2.2.4) lib/devise/failure_app.rb:176:in `store_location!'
  s.add_dependency 'session_off', '0.4'
end