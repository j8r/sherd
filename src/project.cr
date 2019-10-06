require "./shards"
require "./config"
require "./lock"

struct Sherd::Project
  getter directory : Path
  getter bin_directory : Path { @directory / "bin" }
  getter lib_directory : Path { @directory / "lib" }

  def initialize(@directory : Path)
  end

  getter config : Config do
    if File.exists? Config.file(@directory)
      Config.new @directory
    elsif File.exists? Shards::Config.file(@directory)
      Shards::Config.new(@directory).to_sherd
    else
      raise "No config file #{Config.file(@directory)} or #{Shards::Config.file(@directory)} found"
    end
  end

  getter? lock : Lock? do
    if File.exists? Lock.file(@directory)
      Lock.new @directory
    elsif File.exists? Shards::Lock.file(@directory)
      Shards::Lock.new(@directory).to_sherd
    end
  end
end
