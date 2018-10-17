require "watcher"
require "http/server"
require "http/server/handlers/websocket_handler"

class Paladin
  OUTPUT_TIMEOUT = 2.seconds

  @target_channel : Channel(Process?)
  @build_channel : Channel(Process?)
  @reload_listeners : Array(Channel(Bool)) = [] of Channel(Bool)
  @reload_trigger : String

  def initialize(@target : String, @files : Array(String), websocket_port : Int32?, @reload_trigger = "listening")
    @target_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }
    @build_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }
    @reload_listeners_mutex = Mutex.new

    websocket_port.try do |port|
      reload_server = setup_reload_server
      puts "Starting up websocket reload server"
      spawn { reload_server.listen(port) }
    end
  end

  def setup_reload_server
    websocket_handler = HTTP::WebSocketHandler.new do |socket, context|
      channel = Channel(Bool).new(1)

      @reload_listeners_mutex.synchronize do
        @reload_listeners << channel
      end

      socket.on_close do
        @reload_listeners_mutex.synchronize do
          @reload_listeners.delete(channel)
        end
      end

      channel.receive
      puts "Reloading client"
      socket.send("Server reloaded!")
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

  def watch_output(output)
    channel = Channel(Bool).new(2)

    spawn do
      loop do
        line = output.gets
        puts line
        break unless line
        next if line.includes?(@reload_trigger)
        channel.send(true)
        break
      end
    end

    spawn do
      sleep OUTPUT_TIMEOUT
      channel.send(true)
    end

    channel.receive

    @reload_listeners_mutex.synchronize do
      @reload_listeners.each(&.send(true))
    end

    IO.copy(output, STDOUT)
  rescue Errno
  end

  def start_target
    process = Process.new(
      "bin/#{@target}",
      output: Process::Redirect::Pipe,
      error: Process::Redirect::Inherit
    )
    @target_channel.send(process)

    spawn watch_output(process.output)
    process.wait
  end
end
