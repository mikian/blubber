require 'highline'
require 'open3'

require 'blubber/builder'
require 'blubber/tagger'

module Blubber
  class Flow
    def self.build(layers = nil)
      layers ||= Dir['**/*/Dockerfile'].map { |d| File.dirname(d) }

      images = layers.map { |layer| Flow.new(layer: layer).run }

      table = [HighLine.color('Layer', :bold), HighLine.color('Tag', :bold)]
      table += images.map do |(project, tags)|
        tags.map do |tag|
          [project, tag ]
        end
      end

      puts HighLine.new.list(table.flatten, :columns_across, 2)
    end

    def initialize(layer:)
      @layer = layer
    end


    def run
      image = Builder.new(layer: layer, logger: logger).run
      return unless image[:success]

      tagger = Tagger.new(layer: layer, image_id: image[:id], logger: logger)
      tagger.run

      [tagger.project, tagger.tags]
    end

    private

    attr_reader :layer

    def logger
      @logger ||= Logger.new(STDOUT).tap do |logger|
        logger.progname = layer
        logger.formatter = proc do |severity, datetime, progname, msg|
          format("%<severity>s, [%<datetime>s] -- %<progname>s: %<msg>s\n",
                 severity: severity[0],
                 datetime: datetime.strftime('%Y-%m-%d %H:%M:%S'),
                 progname: progname,
                 msg: msg)
        end
      end
    end
  end
end
