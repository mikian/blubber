require 'open3'

require 'blubber/builder'
require 'blubber/tagger'

module Blubber
  class Flow
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
