require 'blubber/build_info'
require 'blubber/builder'
require 'blubber/runner'

module Blubber
  class Layer
    attr_reader :directory, :name
    attr_accessor :build_id

    def initialize(context:, directory:, name:)
      @context = context
      @directory = Pathname.new(directory)
      @name = name
    end

    # Actions
    def build
      builder.build
    end

    def tag
      builder.tag
    end

    def push
      builder.push
    end

    # Accessors
    def repo
      @repo ||= name.split('/').select { |p| p[/[a-z0-9]+/] }.join('/')
    end

    def project
      "#{context.docker_registry}/#{repo}"
    end

    def project_tag(tag)
      "#{project}:#{tag}"
    end

    def cache
      @cache ||= begin
        cache_tags = []

        if build_info.last_successful_commit
          cache_tags << build_info.last_successful_commit.to_s
        end
        cache_tags << build_tag.to_s if build_tag
        cache_tags << branch_tag.to_s if branch_tag
        cache_tags << 'latest'

        cache_tags
          .map { |tag| "#{project}:#{tag}" }
          .find { |img| runner.run("docker pull #{img}").zero? }
      end
    end

    def tags
      @tags ||= begin
        tags = []
        tags << build_info.commit

        unless build_info.dirty?
          tags << branch_tag if branch_tag
          tags << 'latest' if branch_tag == 'master'
        end

        tags << File.read(directory.join('Dockerfile')).scan(/LABEL version=([\w][\w.-]*)/)

        tags.flatten.map { |t| "#{t}#{build_info.dirty? ? '-dirty' : ''}" }
      end
    end

    def branch_tag
      filter(build_info.branch_name) unless build_info.branch_name.empty?
    end

    def build_tag
      branch_tag || build_info.commit
    end

    private

    attr_reader :context

    def builder
      @builder ||= Builder.new(layer: self, logger: logger)
    end

    def filter(thing)
      thing.gsub(/[^\w.-]/, '_')
    end

    def build_info
      @build_info ||= BuildInfo.new(layer: self)
    end

    def runner
      @runner ||= Runner.new(logger: logger)
    end

    def logger
      Logger.for(name: name)
    end
  end
end
