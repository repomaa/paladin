require "watcher"

class Guardian
  @target_channel : Channel(Process?)
  @build_channel : Channel(Process?)

  def initialize(@target : String, @files : Array(String))
    @target_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }
    @build_channel = Channel(Process?).new(1).tap { |c| c.send(nil) }
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
    process.wait
  end
end
