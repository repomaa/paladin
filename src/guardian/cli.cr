require "../guardian"

abort("Usage: #{PROGRAM_NAME} target file [files ...]") if ARGV.size < 2

target = ARGV.first
files = ARGV[1..-1]

guardian = Guardian.new(target, files)

Signal::INT.trap do
  guardian.kill_running_build
  guardian.kill_running_target
  exit
end

guardian.run
