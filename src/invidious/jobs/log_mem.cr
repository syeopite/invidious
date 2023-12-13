require "perf_tools/mem_prof"

class Invidious::Jobs::LogMemory < Invidious::Jobs::BaseJob
  def begin
    loop do
      Dir.mkdir("perftools_memprof") if !Dir.exists?("perftools_memprof")
      Dir.mkdir("perftools_memprof/counts") if !Dir.exists?("perftools_memprof/counts")
      Dir.mkdir("perftools_memprof/allocations") if !Dir.exists?("perftools_memprof/allocations")

      LOGGER.info("jobs: running PerfTools::MemProf")

      File.open("perftools_memprof/counts/#{Time.utc.to_unix}", "w") do |file|
        PerfTools::MemProf.log_object_counts(file)
      end

      File.open("perftools_memprof/allocations/#{Time.utc.to_unix}", "w") do |file|
        PerfTools::MemProf.pretty_log_allocations(file)
      end

      LOGGER.info("jobs: finished running PerfTools::MemProf")

      sleep 30.minutes
    end
  end
end
