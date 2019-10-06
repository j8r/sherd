require "./project"

module Sherd
  class_getter project : Project = Project.new Path[Dir.current]
  # Returns the cache path.
  class_getter cache_path : Path do
    cache = if sherd_cache = ENV["SHRED_CACHE_PATH"]?
              Path[sherd_cache]
            elsif xdg_cache = ENV["XDG_CACHE_HOME"]?
              Path[xdg_cache] / "sherd"
            elsif home = ENV["HOME"]?
              Path[home] / ".cache" / "sherd"
            else
              Path[Dir.tempdir] / "sherd-cache"
            end
    Dir.mkdir_p cache.to_s
    cache
  end
end
