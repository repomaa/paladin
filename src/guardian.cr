require "watcher"
require "http/server"
require "http/server/handlers/websocket_handler"

class Guardian
  @target_channel : Channel(Process?)
  @build_channel : Channel(Process?)
  @reload_channel : Channel(Bool)?

  def initialize(@target : String, @files : Array(String), websocket_port : Int32?)
    @target_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }
    @build_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }

    websocket_port.try do |port|
      reload_channel = Channel(Bool).new(1)
      reload_server = setup_reload_server(reload_channel)
      puts "Starting up websocket reload server"
      spawn { reload_server.listen(port) }
      @reload_channel = reload_channel
    end
  end

  def setup_reload_server(channel)
    websocket_handler = HTTP::WebSocketHandler.new do |socket, context|
      loop do
        channel.receive
        puts "Reloading clients"
        socket.send("Server reloaded!")
      end
    end

    HTTP::Server.new([websocket_handler])
  end

  def run
    watch @files do |event|
      event.on_change do
        kill_running_build

        spawn do
          next unless build.success?
          kill_running_target
          start_target
        end
      end
    end
  end

  def kill_running_build
    @build_channel.receive.try do |process|
      next unless process.exists?
      puts "Killing running build process"
      process.kill(Signal::INT)
    end
  end

  def kill_running_target
    @target_channel.receive.try do |process|
      next unless process.exists?
      puts "Killing old server process"
      process.kill(Signal::INT)
    end
  end

  def build
    process = Process.new(
      "shards", ["build", @target],
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit
    )
    @build_channel.send(process)
    process.wait
  end

  def start_target
    process = Process.new(
      "bin/#{@target}",
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit
    )
    @target_channel.send(process)
    @reload_channel.try(&.send(true))
    process.wait
  end
end
