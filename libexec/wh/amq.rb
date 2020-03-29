#!/usr/bin/env ruby
require 'stomp'
require 'pry'
require 'nagiosplugin'
require 'optparse'

class AmqCheck < Nagios::Plugin
  def initialize
    @options = Struct.new('Options', :host, :port, :id, :connect_timeout, :sleep_after_publish, :sleep_after_subscribe, :warn_threshold).new
    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: amqcheck [-h host]"
      opts.on("-h", "--host HOST", String, "Host name or IP address") do |h|
        @options.host = h
      end
      opts.on("-p", "--port PORT", Integer, "Port") do |p|
        @options.port = p
      end
      opts.on("-i", "--id ID", String, "Id") do |i|
        @options.id = i
      end
      opts.on("-t", "--timeout TIMEOUT", Integer, "Connection timeout") do |t|
        @options.connect_timeout = t
      end
      opts.on("-s", "--sleep_after_publish SLEEP", Integer, "Sleep after publish") do |s|
        @options.sleep_after_publish = s
      end
      opts.on("-S", "--sleep_after_subscribe SLEEP", Integer, "Sleep after subscribe") do |s|
        @options.sleep_after_publish = s
      end
      opts.on("-w", "--warn_threshold THRESHOLD", Integer, "warning threshold.") do |w|
        @options.warn_threshold = w
      end
      opts.on('-?', '--help', 'Display this screen') do
        puts opts
        exit
      end
    end
    begin
      optparse.parse!
      raise OptionParser::MissingArgument.new("host is required") unless @options.host
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      puts e.message
      puts optparse
      exit 3
    end
    @options.port ||= 61612
    @url ||= "failover://(stomp://#{@options.host}:#{@options.port})?initialReconnectDelay=1&randomize=false&useExponentialBackOff=false"
    @options.id ||= "nagios"
    @options.connect_timeout ||= 3
    @options.sleep_after_publish ||= 0.5
    @options.sleep_after_subscribe ||= 3
    @options.warn_threshold ||= 5
    @queue = "/queue/#{@options.id}"
    @counter = 0
  end
  def check
    begin
      Timeout::timeout(@options.connect_timeout) do
        @client = Stomp::Client.new(@url)
      end
    rescue Timeout::Error
      @msg = "connection timeout of #{@options.connect_timeout} was reached."
      @critical = true
      return
    end
    @client.publish(@queue, @options.id + " " + Time.new.to_i.to_s, {:persistent => true})
    sleep @options.sleep_after_publish
    begin
      @client.subscribe(@queue, {:ack => "client", "activemq.prefetchSize" => 1, "activemq.exclusive" => true }) do |msg|
        @payload = msg.body
        @counter += 1
        @client.acknowledge(msg)
      end
      sleep @options.sleep_after_subscribe
      if @payload.class == String
        id, time = @payload.split
        diff = Time.now - Time.at(time.to_i)
        @corrected_diff = diff - @options.sleep_after_subscribe - @options.sleep_after_publish
        @msg = "#{@corrected_diff.round(2)} seconds since message enqueued corrected. #{@counter} messages dequeued."
      else
        @critical = true
        @msg = "No message received in #{@queue}"
      end
    rescue
      @msg = "exception"
      @critical = true
      exit 1
    end
  end
  def critical?
    @critical
  end
  def warning?
    @corrected_diff > @options.warn_threshold
  end
  def ok?
    @payload.class == String
  end
  def message
    @msg
  end
end
AmqCheck.run!
