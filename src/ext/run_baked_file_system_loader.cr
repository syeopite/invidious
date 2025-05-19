require "./baked_file_system_loader.cr"

path = File.expand_path(ARGV[0], ARGV[1])

BakedFileSystem::Loader.load(STDOUT, path)
