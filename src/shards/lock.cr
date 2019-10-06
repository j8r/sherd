require "yaml"
require "semantic_version"
require "./converter"

struct Sherd::Shards::Lock
  include YAML::Serializable
  @version : Float64?
  getter shards : Hash(String, Hash(String, String))

  def self.file(directory : Path)
    directory / "shard.lock"
  end

  def self.new(directory : Path)
    File.open file(directory) do |io|
      from_yaml io
    rescue ex
      raise Exception.new "Failed to parse #{file(directory)}", ex
    end
  end

  def to_sherd : Sherd::Lock
    sherd_dependencies = Hash(String, Sherd::Lock::DependencyLock).new
    @shards.each do |package, keys|
      path, rev_or_version = Converter.keys_to_path_or_version keys
      case rev_or_version
      when String then rev_or_version = SemanticVersion.parse rev_or_version
      when Git::Revision
      when Nil then raise "Version missing"
      end
      sherd_dependencies[package] = Sherd::Lock::DependencyLock.new path, rev_or_version, ""
    rescue ex
      raise Exception.new "Failed to parse #{package}", ex
    end
    Sherd::Lock.new sherd_dependencies
  end
end
