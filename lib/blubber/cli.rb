require 'thor'

require 'blubber/flow'

module Blubber
  class Cli < Thor
    desc 'build', 'Builds all found Docker images'
    def build
      # Build images
      images = layers.map { |layer| Flow.new(layer: layer).run }

      table = [set_color('Layer', :bold), set_color('Tag', :bold)]
      table += images.map do |(project, tags)|
        tags.map do |tag|
          [project, tag ]
        end
      end

      puts HighLine.new.list(table.flatten, :columns_across, 2)
    end

    no_tasks do
      def layers
        @layers ||= Dir['**/*/Dockerfile'].map { |d| File.dirname(d) }
      end
    end
  end
end
