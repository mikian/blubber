require 'thor'

require 'blubber/flow'

module Blubber
  class Cli < Thor
    desc 'build', 'Builds all found Docker images'
    def build
      exit(Flow.build) # Fails to build if any layer fails
    end
  end
end
