require "baked_file_system"
require "../../ext/baked_file_system_loader.cr"

class Invidious::Baked
  extend BakedFileSystem

  # Modifies bake_folder macro to run our override
  macro bake_folder(path, dir = __DIR__, allow_empty = false)
    {% raise "BakedFileSystem.load expects `path` to be a StringLiteral." unless path.is_a?(StringLiteral) %}

    %files_size_ante = @@files.size

    {{ run("../../ext/run_baked_file_system_loader", path, dir) }}

    {% unless allow_empty %}
    raise "BakedFileSystem empty: no files in #{File.expand_path({{ path }}, {{ dir }})}" if @@files.size - %files_size_ante == 0
    {% end %}
  end

  bake_folder "../../../locales"
  bake_folder "../../../assets"
end
