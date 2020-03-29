#!/usr/bin/env ruby
require 'optparse'
require 'open-uri'
require 'json'

options = {
  :port => 80,
  :protocol => 'http',
  :standard => 'guess',
}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: check_rl_rest_api_health.rb [options]"

  opts.on('-H', '--host HOST', 'pweb2080.prod.lax.reachlocal.cmo') { |v| options[:host] = v }
  opts.on('-p', '--port PORT', '80') { |v| options[:port] = v }
  opts.on('--path PATH', '/sites/health/status') { |v| options[:path] = v }
  opts.on('--protocol PROTOCOL', 'http') { |v| options[:protocol] = v }
  opts.on('--standard STANDARD', '[health_check_ruby|rseo_grails_original]') { |v| options[:standard] = v }

end

begin
  optparse.parse!
  mandatory = [:host, :port, :path, :protocol, :standard]
  missing = mandatory.select{ |param| options[param].nil? }
  if not missing.empty?
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit 3
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit 3
end

def extract_status_via_standard(json, standard = 'health_check_ruby')
  case standard
  when 'guess'
    case json['status']
    when 'OK', 200
      status = 'OK'
    else
      status = 'FAIL'
    end
  when 'health_check_ruby'
    status = json['status']
  when 'rseo_grails_original'
    status = json['status'] == 200? 'OK': 'FAIL'
  end
  return status
end
def extract_messages_via_standard(json, standard = 'guess')
  case standard
  when 'guess'
    messages = json['messages'] || []
  when 'health_check_ruby'
    messages = json['messages']
  when 'rseo_grails_original'
    messages = []
  end
  return messages
end

def get_exit_code(status)
  case status
  when 'OK'
    0
  when 'WARN'
    1
  when 'FAIL'
    2
  else
    3
  end
end
begin
  url = "#{options[:protocol]}://#{options[:host]}:#{options[:port]}#{options[:path]}"
  contents = open(url, "User-Agent" => 'libexec/check_rl_rest_api_health.rb'){|f| f.read }
  json = JSON.parse(contents)
  status = extract_status_via_standard(json,options[:standard])
  puts extract_messages_via_standard(json,options[:standard])
  exit_code = get_exit_code(status)
rescue OpenURI::HTTPError => e
  exit_code = 3
  puts "#{url} #{e.message}"
end
puts "#{url} is #{json['status']}"
exit exit_code
