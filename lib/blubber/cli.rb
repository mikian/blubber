require 'thor'

require 'blubber/flow'
require 'blubber/context'

module Blubber
  class Cli < Thor
    class_option :registry, aliases: %w(-r), desc: 'Docker Registry', default: ENV['DOCKER_REGISTRY']

    desc 'build LAYER [LAYER...]', 'Builds all found Docker images'
    method_option :tag,  aliases: %w(-t), desc: 'Tag all built images', default: true
    method_option :push, aliases: %w(-p), desc: 'Push images as they are built', default: true
    def build(layers = nil)
      flow = Flow.new(
        layers: layers,
        build: true,
        tag: options.tag,
        push: options.push,
        context: Context.new(docker_registry: options.registry)
      )
      exit flow.run
    end
  end
end
