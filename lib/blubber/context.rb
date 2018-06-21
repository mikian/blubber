require 'singleton'
require 'forwardable'

module Blubber
  class Context
    attr_reader :docker_registry

    def initialize(docker_registry: nil)
      @docker_registry = docker_registry || ENV.fetch('DOCKER_REGISTRY')
    end
  end
end
