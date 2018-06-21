require 'singleton'
require 'forwardable'

module Blubber
  class BuildInfo
    extend Forwardable
    def_delegators :shared, :branch_name, :dirty?, :commit, :last_successful_commit

    def initialize(layer:)
      @layer = layer
    end

    def dirty?
      @dirty ||= system("git status --porcelain 2>&1 | grep -q '#{layer.directory}'")
    end

    private

    attr_reader :layer

    def shared
      @shared ||= Class.new do
        include Singleton

        def branch_name
          @branch_name ||= ENV.fetch('BRANCH_NAME') do
            `
              git rev-parse HEAD |
              git branch -a --contains |
              sed -n 2p |
              cut -d'/' -f 3-
            `.strip
          end
        end

        def commit
          @commit ||= ENV.fetch('GIT_COMMIT') { `git rev-parse HEAD`.strip }
        end

        def last_successful_commit
          @last_successful_commit ||= ENV['GIT_PREVIOUS_SUCCESSFUL_COMMIT']
        end
      end.instance
    end
  end
end
