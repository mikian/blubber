require 'thor'

require 'blubber/flow'

module Blubber
  class Cli < Thor
    desc 'build', 'Builds all found Docker images'
    def build
      Flow.build
  end
end
