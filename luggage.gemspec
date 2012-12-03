# -*- encoding: utf-8 -*-

require File.expand_path('../lib/luggage/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "luggage"
  gem.version       = Luggage::VERSION
  gem.summary       = %q{Net::IMAP DSL}
  gem.description   = %q{Easily interact with IMAP servers}
  gem.license       = "MIT"
  gem.authors       = ["Ryan Michael", "Eric Pinzur"]
  gem.email         = "ryanmichael@otherinbox.com"
  gem.homepage      = "https://github.com/otherinbox/luggage"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'mail', '~> 2.4.4'
  gem.add_dependency 'uuidtools', '~> 2.1.3'

  gem.add_development_dependency 'bundler', '~> 1.0'
  gem.add_development_dependency 'rake', '~> 0.8'
  gem.add_development_dependency 'rdoc', '~> 3.0'
  gem.add_development_dependency 'rspec', '~> 2.4'
  gem.add_development_dependency 'activesupport', '~> 3.2.9'
  gem.add_development_dependency 'fuubar', '~> 1.1.0'
  gem.add_development_dependency 'pry', '~> 0.9.10'
end
