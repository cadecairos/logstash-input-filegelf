# encoding: utf-8
require 'logstash/inputs/base'
require 'logstash/namespace'

# Read GELF Formatted events from one or many files
#
# Each event is should be on a separate line of the file
class LogStash::Inputs::FileGelf < LogStash::Inputs::Base
  config_name 'filegelf'
  milestone 2

  default :codec, 'plain'

  # The paths(s) to be used as an input source
  config :path, :validate => :array, :required => true

  # Toggle whether or not to remap GELF fields to Logstash event fields
  #
  # Remapping converts the following GELF fields to Logstash equivalents:
  #
  # * `full\_message` becomes event["message"].
  # * if there is no `full\_message`, `short\_message` becomes event["message"].
  config :remap, :validate => :boolean, :default => false

  # strip leading underscores from all event fields
  config :strip_leading_underscore, :validate => :boolean, :default => true

  public
  def register
    require 'gelfd'
    @logger.info("Registering GELF file input", :path => @path)

    @path.each do |path|
      if Pathname.new(path).relative?
        raise ArgumentError.new("File paths must be absolute, relative path specified: #{path}")
      end
      if !File.exists?(path)
        raise ArgumentError.new("File does not exist: #{path}")
      end
    end
  end # def register

  public
  def run(output_queue)
    puts @path
    @path.each do |path|
      File.open(path).readlines.each do |line|
        begin
          event = LogStash::Event.new(JSON.parse(line))
        rescue => ex
          raise
        end
        if event['timestamp'].is_a?(Numeric)
          event['@timestamp'] = Time.at(event['timestamp']).gmtime
          event.remove('timestamp')
        end

        remap_gelf(event) if @remap
        strip_leading_underscore(event) if @strip_leading_underscore
        decorate(event)
        output_queue << event
      end
    end
  end # def run

  private
  def remap_gelf(event)
    if event["full_message"]
      event["message"] = event["full_message"].dup
      event.remove("full_message")
      if event["short_message"] == event["message"]
        event.remove("short_message")
      end
    elsif event["short_message"]
      event["message"] = event["short_message"].dup
      event.remove("short_message")
    end
  end # def remap_gelf

  private
  def strip_leading_underscore(event)
     # Map all '_foo' fields to simply 'foo'
     event.to_hash.keys.each do |key|
       next unless key[0,1] == "_"
       event[key[1..-1]] = event[key]
       event.remove(key)
     end
  end # def strip_leading_underscore
end # def class Logstash::Inputs::FileGelf
