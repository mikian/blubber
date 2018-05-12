require 'open3'

module Blubber
  class Runner
    def initialize(logger:)
      @logger = logger
    end

    def run(cmd)
      # see: http://stackoverflow.com/a/1162850/83386
      Open3.popen3(cmd) do |_stdin, stdout, stderr, thread|
        # read each stream from a new thread
        { out: stdout, err: stderr }.each do |key, stream|
          Thread.new do
            until (line = stream.gets).nil?
              # yield the block depending on the stream
              if key == :out
                logger.info line.strip
                yield line, nil, thread if block_given?
              else
                logger.error line.strip
                yield nil, line, thread if block_given?
              end
            end
          end
        end

        thread.join
        thread.value.exitstatus
      end
    end

    private

    attr_reader :logger
  end
end
