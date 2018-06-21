require 'highline'

require 'blubber/layer'

module Blubber
  class Flow
    def initialize(layers:, context:, build: true, tag: true, push: true)
      @context = context
      @layers = detect_layers(layers: layers)
      @flow = { build: build, tag: tag, push: push }
    end

    def run
      results = layers.map do |layer|
        status = true
        status &= layer.build if flow[:build]
        status &= layer.tag if flow[:tag] && layer.build_id
        status &= layer.push if flow[:push] && layer.build_id

        [layer, status]
      end.to_h

      table = [HighLine.color('Layer', :bold), HighLine.color('Tag', :bold)]
      table += results.map do |layer, result|
        if result
          layer.tags.map { |tag| [layer.project, tag] }
        else
          [layer.project, HighLine.color('FAILED', :red)]
        end
      end
      puts HighLine.new.list(table.flatten, :columns_across, 2)

      results.values.reduce(:&)
    end

    private

    attr_reader :layers, :context, :flow

    def detect_layers(layers: nil)
      Dir['**/*/Dockerfile']
        .map { |d| File.dirname(d) }
        .sort
        .select { |layer| layers.nil? || layers.include?(layer) }
        .map { |layer| Layer.new(name: layer, directory: File.expand_path('.', layer), context: context) }
    end
  end
end
