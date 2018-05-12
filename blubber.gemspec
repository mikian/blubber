lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blubber/version'

Gem::Specification.new do |spec|
  spec.name          = 'blubber'
  spec.version       = Blubber::VERSION
  spec.authors       = ['Mikko Kokkonen']
  spec.email         = ['mikko@mikian.com']

  spec.summary       = 'Blubber - build collection of docker images'
  spec.description   = 'Blubber allows easily to build collection of docker-images at ease.'
  spec.homepage      = 'https://github.com/mikian/blubber'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'highline'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
