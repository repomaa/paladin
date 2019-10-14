require "docker"
require "option_parser"
require "../paladin"

USAGE = "Usage: #{PROGRAM_NAME} [options] target file [files ...]"

websocket_port = nil
reload_trigger = nil

parser =  OptionParser.new do |p|
  p.banner = USAGE

  p.on(
    "-w PORT",
    "--websocket-port=PORT",
    "Start a websocket server at http://localhost:PORT that notifies clients when the target has been restarted"
  ) do |port|
    websocket_port = Int32.new(port)
  end

  p.on(
    "-d", "--docker",
    "Use docker specific workarounds for stdio and ipc signalling. Set this if you start paladin from docker"
  ) do
    Docker.setup
  end

  p.on(
    "-t STRING",
    "--reload-trigger=STRING",
    "Send reload message to websocket clients when STRING appears on the standard output of the built target"
  ) do |string|
    reload_trigger = string
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

puts "Starting paladin. Target: #{target} files: #{files}"
paladin = Paladin.new(target, files, websocket_port, reload_trigger)

Signal::INT.trap do
  paladin.kill_running_build
  paladin.kill_running_target
  exit
end

paladin.run
