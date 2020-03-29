#!/usr/bin/env ruby
require 'pry'
require 'curb'
require 'awesome_print'
require 'json'
require 'optparse'
require 'active_support'
require 'active_support/core_ext'
require 'pstore'
optHash = Hash.new
ERROR = 1
WARN = 2
UNKNOWN = 3
OptionParser.new do |o|
  helpmsg = "\n"
  o.on('-q', '--queue QUEUE', 'queue to check') { |queue| optHash['queue'] = queue }
  o.on('-m', '--min-error MIN-ERROR', 'minimum threshold for error') { |opt| optHash['error-min'] = opt }
  o.on('-M', '--max-error MAX-ERROR', 'maximum threshold for error') { |opt| optHash['error-max'] = opt }
  o.on('-w', '--min-warn MIN-WARNING', 'minimum threshold for warning') { |opt| optHash['warn-min'] = opt }
  o.on('-W', '--max-warn MAX-WARNING', 'maximum threshold for warning') { |opt| optHash['warn-max'] = opt }
  o.on('-a', '--attribute ATTRIBUTE', 'attribute to check') { |opt| optHash['attribute'] = opt }
  o.on('-f', '--host HOST', 'hostname running jolokia') { |opt| optHash['host'] = opt }
  o.on('-p', '--port PORT', 'port to connect to jolokia') { |opt| optHash['port'] = opt }
  o.on('-r', '--min-range MINRANGE', 'minimum number of minutes to look back for delta') { |opt| optHash['minrange'] = opt }
  o.on('-R', '--max-range MAXRANGE', 'maximum number of minutes to look back for delta') { |opt| optHash['maxrange'] = opt }
  o.on('-d', '--datastore DATASTORE', 'location of datastore directory') { |opt| optHash['datastore'] = opt }
  o.on('-h', '--help', 'Returns this help message.') {
    puts helpmsg
    puts o; exit ERROR
  }
  begin #rescue to prevent nasty exception on bad arguements
    o.parse!
  rescue OptionParser::InvalidOption  => e
    puts e
    puts helpmsg
    puts o; exit ERROR
  end
end
['host','port','attribute','queue', 'minrange', 'datastore'].each do |opt|
  unless optHash.has_key? opt
    puts "ERROR: Required option #{opt} not passed.  Use -h to get help."
    exit ERROR
  end
end
url = "http://#{optHash['host']}:#{optHash['port']}/jolokia/read/org.apache.activemq:BrokerName=*,Type=Queue,Destination=#{optHash['queue']}/#{optHash['attribute']}"
begin
  http = Curl.get(url)
rescue Curl::Err::HostResolutionError => e
  puts "ERROR: Failed to resolve host"
  exit ERROR
rescue Exception => e
  puts "ERROR: failed to acquire data : #{e.message}"
end
queue_data = Hash.new
begin
  json_data = JSON.parse(http.body_str)
rescue Exception => e
  puts "ERROR: Error parsing returned json. #{e.message}"
  exit ERROR
end
if json_data.has_key? 'error_type'
  puts "ERROR: #{json_data['error_type']}"
  exit ERROR
end
value = json_data['value'].flatten[1].flatten[1]
unless value.class == Fixnum
  puts "ERROR: #{value.class} returned as value for #{optHash['attribute']}"
  exit ERROR
end
begin
  class Result
    attr_accessor :queue, :attribute, :value, :host, :port, :created_at
  end
  result = Result.new
  result.value = value.to_i
  result.host = optHash['host']
  result.port = optHash['port'].to_i
  result.queue = optHash['queue']
  result.attribute = optHash['attribute']
  result.created_at = DateTime.now
  datastore = PStore.new("#{optHash['datastore']}/queue_jmx_#{result.host}_#{result.port}_#{result.queue}_#{result.attribute}.pstore")
rescue Exception => e
  puts "ERROR: #{e.message} during pstore"
  exit ERROR
end
changePerMinute = nil
if optHash.has_key? 'maxrange'
  optHash['maxrange'] = optHash['maxrange'].to_i.minutes.ago.to_datetime
else
  optHash['maxrange'] = 0
end
datastore.transaction do
  datastore[:results] ||= Array.new
  datastore[:results].push(result)
  validResults = datastore[:results].select { |item| item.created_at < optHash['minrange'].to_i.minutes.ago.to_datetime  && item.created_at > optHash['maxrange']}
  if (validResults.count > 0)
    validResults.sort! {|x,y| x.created_at <=> y.created_at }
    historical_result = validResults.last
    datastore[:results].reject! { |item|  item.created_at < optHash['minrange'].to_i.minutes.ago.to_datetime }
    datastore[:results].push(historical_result)
    timediff = ( result.created_at - historical_result.created_at ) * 1.days
    valuediff = result.value - historical_result.value
    changePerMinute = (valuediff/timediff)*1.minutes
  else
    puts "WARN: Not enough data based on #{optHash['minrange']} minrange."
    exit WARN
  end
end
if optHash.has_key? 'error-min'
  if optHash['error-min'].to_i > changePerMinute
    puts "ERROR: #{optHash['attribute']} of #{changePerMinute} is less than minimum threshold of #{optHash['error-min']}|#{optHash['attribute']}=#{changePerMinute.round}"
    exit ERROR
  end
end
if optHash.has_key? 'error-max'
  if optHash['error-max'].to_i < changePerMinute
    puts "ERROR: #{optHash['attribute']} of #{changePerMinute} is greater than maximum threshold of #{optHash['error-max']}|#{optHash['attribute']}=#{changePerMinute.round}"
    exit ERROR
  end
end
if optHash.has_key? 'warn-min'
  if optHash['warn-min'].to_i > changePerMinute
    puts "WARN: #{optHash['attribute']} of #{changePerMinute} is less than minimum threshold of #{optHash['warn-min']}|#{optHash['attribute']}=#{changePerMinute.round}"
    exit WARN
  end
end
if optHash.has_key? 'warn-max'
  if optHash['warn-max'].to_i < changePerMinute
    puts "WARN: #{optHash['attribute']} of #{changePerMinute} is greater than maximum threshold of #{optHash['warn-max']}|#{optHash['attribute']}=#{changePerMinute.round}"
    exit WARN
  end
end
puts "OK: #{optHash['attribute']} of #{changePerMinute} is great.|#{optHash['attribute']}=#{changePerMinute.round}"
exit 0
