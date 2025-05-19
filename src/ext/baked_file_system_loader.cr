# Modified directory loader of the baked_file_system shard to
# preserve folder name

require "baked_file_system"
require "baked_file_system/loader/string_encoder.cr"

module BakedFileSystem
  module Loader
    class Error < Exception
    end

    def self.load(io, root_path)
      if !File.exists?(root_path)
        raise Error.new "path does not exist: #{root_path}"
      elsif !File.directory?(root_path)
        raise Error.new "path is not a directory: #{root_path}"
      elsif !File.readable?(root_path)
        raise Error.new "path is not readable: #{root_path}"
      end

      root_path_length = root_path.size
      parsed_root_path = Path[root_path]

      result = [] of String

      files = Dir.glob(parsed_root_path.to_posix.join("**", "*"))
        # Reject hidden entities and directories
        .reject { |path| File.directory?(path) || !(path =~ /(\/\..+)/).nil? }

      files.each do |path|
        io << "bake_file BakedFileSystem::BakedFile.new(\n"
        io << "  path:            " << Path[path[(root_path_length - parsed_root_path.basename.size)..]].expand("/").to_posix.to_s.dump << ",\n"
        io << "  size:            " << File.info(path).size << ",\n"
        compressed = path.ends_with?("gz")

        io << "  compressed:      " << compressed << ",\n"

        File.open(path, "rb") do |file|
          io << "  slice:         \""

          StringEncoder.open(io) do |encoder|
            if compressed
              IO.copy file, encoder
            else
              Compress::Gzip::Writer.open(encoder) do |writer|
                IO.copy file, writer
              end
            end

            io << "\".to_slice,\n"
          end
        end

        io << ")\n"
        io << "\n"
      end
    end
  end
end
