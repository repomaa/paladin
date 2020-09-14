require "watcher"
require "http/server"
require "http/server/handlers/websocket_handler"

class Paladin
  OUTPUT_TIMEOUT = 2.seconds

  @target_channel : Channel(Process?)
  @build_channel : Channel(Process?)
  @reload_listeners : Array(Channel(Bool)) = [] of Channel(Bool)
  @reload_trigger : String?

  def initialize(@target : String, @files : Array(String), websocket_port : Int32?, @params = [] of String, @reload_trigger = nil)
    @target_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }
    @build_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }
    @reload_listeners_mutex = Mutex.new

    websocket_port.try do |port|
      reload_server = setup_reload_server
      puts "Starting up websocket reload server on ws://127.0.0.1:#{port}"
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

  def watch_output(output, trigger)
    channel = Channel(Bool).new(3)

    spawn do
      buffer = Deque(Char).new(trigger.size)

      loop do
        char = output.read_char
        break if char.nil?
        print char
        buffer.push(char)
        buffer.shift if buffer.size > trigger.size
        break if buffer.join == trigger
      end

      channel.send(true)
      IO.copy(output, STDOUT)
      channel.send(false)
    end

    spawn do
      sleep OUTPUT_TIMEOUT
      channel.send(false)
    end

    channel.receive

    @reload_listeners_mutex.synchronize do
      @reload_listeners.each(&.send(true))
    end

    2.times { channel.receive }
  rescue IO::Error
  end

  def start_target
    output = @reload_trigger ? Process::Redirect::Pipe : Process::Redirect::Inherit
    process = Process.new(
      "bin/#{@target}",
      @params,
      output: output,
      error: Process::Redirect::Inherit
    )
    @target_channel.send(process)

    reload_trigger = @reload_trigger

    if reload_trigger
      spawn watch_output(process.output, reload_trigger)
    else
      spawn do
        sleep OUTPUT_TIMEOUT

        @reload_listeners_mutex.synchronize do
          @reload_listeners.each(&.send(true))
        end
      end
    end

    process.wait
  end
end
