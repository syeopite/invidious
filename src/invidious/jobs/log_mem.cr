require "perf_tools/mem_prof"
require "perf_tools/fiber_trace"

class Invidious::Jobs::LogMemory < Invidious::Jobs::BaseJob
  def begin
    LOGGER.info "Sleeping 5 seconds to await completion of other jobs before first run of LogMemory job"
    sleep 5.seconds
    LOGGER.info "Begin running LogMemory job"

    loop do
      Dir.mkdir("perftools_memprof") if !Dir.exists?("perftools_memprof")
      Dir.mkdir("perftools_memprof/counts") if !Dir.exists?("perftools_memprof/counts")
      Dir.mkdir("perftools_memprof/allocations") if !Dir.exists?("perftools_memprof/allocations")
      Dir.mkdir("perftools_memprof/fibers") if !Dir.exists?("perftools_memprof/fibers")

      LOGGER.info("jobs: running PerfTools::MemProf and PerfTools::FiberTrace")

      File.open("perftools_memprof/counts/#{Time.utc.to_unix}-#{Time.local.to_s}.txt", "w") do |file|
        PerfTools::MemProf.log_object_counts(file)
      end

      File.open("perftools_memprof/allocations/#{Time.utc.to_unix}-#{Time.local.to_s}.md", "w") do |file|
        PerfTools::MemProf.pretty_log_allocations(file)
      end

      File.open("perftools_memprof/fibers/#{Time.utc.to_unix}-#{Time.local.to_s}.md", "w") do |file|
        PerfTools::FiberTrace.pretty_log_fibers(file)
      end

      LOGGER.info("jobs: finished running PerfTools::MemProf and PerfTools::FiberTrace")

      sleep 30.minutes
    end
  end
end
