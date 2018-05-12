require 'highline'
require 'logger'
require 'open3'

require 'blubber/runner'
require 'blubber/tagger'

module Blubber
  class Builder
    def initialize(layer:, logger: nil)
      @layer = layer
      @logger = logger
    end

    def run
      logger.info ui.color("BUILDING", :yellow)
      retval = build(layer)
      level, color = retval.zero? ? [:info, :green] : [:error, :red]

      logger.public_send(level, ui.color("#{layer}: #{retval.zero? ? 'SUCCESS' : 'ERROR'}", color))

      { success: retval.zero?, id: build_ids[layer] }
    end

    private

    attr_reader :layer, :logger

    def docker_registry
      format('%<host>s/%<project>s',
             host: ENV.fetch('DOCKER_REGISTRY'),
             project: 'etl')
    end

    def ui
      @ui ||= HighLine.new
    end

    def runner
      @runner ||= Runner.new(logger: logger)
    end

    def tags
      @tags ||= Tagger.new(layer: layer, image_id: nil).tags
    end

    def build_ids
      @build_ids ||= {}
    end

    def build(layer)
      # NOTICE : Speed up build for fresh slave
      tags.each do |tag|
        runner.run("docker pull #{docker_registry}/#{layer}:#{tag}")
      end

      status = nil
      Dir.chdir(layer) do
        status = runner.run('docker build .') do |stdout, _, _|
          if stdout && (m = stdout.match(/Successfully built ([a-z0-9]{12})/))
            build_ids[layer] = m[1]
          end
        end
      end
      status
    end
  end
end
