require 'singleton'
require 'forwardable'
require 'logger'

module Blubber
  class Logger
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :for
    end

    def for(name:)
      loggers.fetch(name) do
        ::Logger.new(STDOUT).tap do |logger|
          logger.progname = name
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

    private

    def loggers
      @loggers ||= {}
    end
  end
end
