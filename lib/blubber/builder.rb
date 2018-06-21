require 'highline'
require 'logger'

require 'blubber/runner'
require 'blubber/logger'

module Blubber
  class Builder
    def initialize(layer:, logger: nil)
      @layer = layer
      @logger = logger || Logger.for(name: layer.name)
    end

    def build
      logger.info ui.color('BUILDING', :yellow)
      retval = do_build
      level, color = retval.zero? ? %i[info green] : %i[error red]

      logger.public_send(level,
                         ui.color((retval.zero? ? 'SUCCESS' : 'ERROR'), color))

      retval.zero?
    end

    def tag
      logger.info ui.color('TAGGING', :yellow)
      status = {}
      layer.tags.each do |tag|
        status[tag] = runner.run("docker tag #{layer.build_id} #{layer.project_tag(tag)}")
      end

      retval = status.values.reduce(:+)

      level, color = retval.zero? ? %i[info green] : %i[error red]

      logger.public_send(level,
                         ui.color((retval.zero? ? 'SUCCESS' : 'ERROR'), color))

      retval.zero?
    end

    def push
      logger.info ui.color('PUSHING', :yellow)
      status = {}
      layer.tags.each do |tag|
        status[tag] = runner.run("docker push #{layer.project_tag(tag)}")
      end

      retval = status.values.reduce(:+)

      level, color = retval.zero? ? %i[info green] : %i[error red]

      logger.public_send(level,
                         ui.color((retval.zero? ? 'SUCCESS' : 'ERROR'), color))

      retval.zero?
    end

    private

    attr_reader :layer, :logger

    def ui
      @ui ||= HighLine.new
    end

    def runner
      @runner ||= Runner.new(logger: logger)
    end

    def do_build
      status = nil
      Dir.chdir(layer.directory) do
        cmd = []
        cmd += %w[docker build]
        cmd += %W[--build-arg VERSION=#{layer.build_tag}]
        cmd += %W[--cache-from #{layer.cache}] if layer.cache
        cmd << '.'

        status = runner.run(cmd) do |stdout, _, _|
          if stdout && (m = stdout.match(/Successfully built ([a-z0-9]{12})/))
            layer.build_id = m[1]
          end
        end
      end

      status
    end
  end
end
