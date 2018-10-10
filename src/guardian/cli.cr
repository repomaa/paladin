require "option_parser"
require "../guardian"

USAGE = "Usage: #{PROGRAM_NAME} [options] target file [files ...]"

websocket_port = nil

parser =  OptionParser.new do |p|
  p.banner = USAGE

  p.on(
    "-w PORT",
    "--websocket-port=PORT",
    "Start a websocket server at http://localhost:PORT that notifies clients when the target has been restarted"
  ) do |port|
    websocket_port = Int32.new(port)
  end

  p.on("-h", "--help", "Show this message") do
    puts p
    exit
  end
end

parser.parse!
abort(parser) if ARGV.size < 2

target = ARGV.first
files = ARGV[1..-1]

puts "Starting guardian. Target: #{target} files: #{files}"
guardian = Guardian.new(target, files, websocket_port)

Signal::INT.trap do
  guardian.kill_running_build
  guardian.kill_running_target
  exit
end

guardian.run
