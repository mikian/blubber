require 'highline'
require 'logger'
require 'open3'

require 'blubber/runner'

module Blubber
  class Tagger
    def self.docker_registry
      ENV.fetch('DOCKER_REGISTRY')
    end

    def initialize(layer:, image_id:, logger: nil)
      @layer = layer
      @image_id = image_id
      @logger = logger
    end

    def run
      logger.info ui.color("#{layer}: PUSHING", :yellow)

      push
    end

    def project
      [
        Tagger.docker_registry,
        *layer.split('/').select { |p| p[/[a-z0-9]+/] }
      ].join('/')
    end

    def tags
      @tags ||= begin
        tags = []
        tags << "#{commit}#{dirty? ? '-dirty' : ''}"

        unless dirty?
          tags << branch_name.gsub(/[^\w.-]/, '_') unless branch_name.empty?
          tags << 'latest' if branch_name == 'master'
        end

        tags << File.read("#{layer}/Dockerfile").scan(/LABEL version=([\w][\w.-]*)/)

        tags.flatten
      end
    end

    private

    attr_reader :layer, :image_id, :logger

    def runner
      @runner ||= Runner.new(logger: logger)
    end

    def ui
      @ui ||= HighLine.new
    end

    def dirty?
      @dirty ||= system("git status --porcelain 2>&1 | grep -q '#{layer}'")
    end

    def commit
      @commit ||= ENV['GIT_COMMIT'] || `git rev-parse HEAD`.strip
    end

    def branch_name
      @branch_name ||= ENV['BRANCH_NAME'] || `git rev-parse HEAD | git branch -a --contains | sed -n 2p | cut -d'/' -f 3-`.strip
    end

    def push
      status = true
      tags.each do |tag|
        logger.info "Tagging #{image_id} as #{layer}:#{tag}"
        retval = runner.run("docker tag #{image_id} #{project}:#{tag}")
        next unless retval.zero?
        retval = runner.run("docker push #{project}:#{tag}")

        status &= retval.zero?
      end

      tags if status
    end
  end
end
