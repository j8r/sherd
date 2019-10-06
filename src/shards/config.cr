require "yaml"
require "./converter"

struct Sherd::Shards::Config
  include YAML::Serializable
  getter name : String,
    version : String,
    description : String?,
    license : String?,
    authors : Array(String)?,
    dependencies : Hash(String, Hash(String, String))?,
    development_dependencies : Hash(String, Hash(String, String))?,
    scripts : Hash(String, String)?,
    targets : Hash(String, Hash(String, String))?

  def self.file(directory : Path)
    directory / "shard.yml"
  end

  def self.new(directory : Path)
    File.open file(directory) do |io|
      from_yaml io
    rescue ex
      raise Exception.new "Failed to parse #{file(directory)}", ex
    end
  end

  def to_sherd : Sherd::Config
    if dependencies = @dependencies
      sherd_dependencies = convert_dependencies_to_metadata dependencies
    end
    if development_dependencies = @development_dependencies
      sherd_development_dependencies = convert_dependencies_to_metadata development_dependencies
    end

    sherd_targets = targets.try &.transform_values &.["main"]

    if authors = @authors
      authors_count = 0
      sherd_authors = Hash(String, String).new
      authors.each do |author|
        sherd_authors["author#{authors_count}"] = author
        authors_count += 1
      end
    end

    package = Sherd::Config::Package.new(
      name: @name,
      description: @description,
      license: @license,
      version: @version,
    )
    Sherd::Config.new(
      package: package,
      authors: sherd_authors,
      dependencies: sherd_dependencies,
      dev_dependencies: sherd_development_dependencies,
      scripts: @scripts,
      targets: sherd_targets,
    )
  end

  private def convert_dependencies_to_metadata(dependencies : Hash(String, Hash(String, String))) : Hash(String, Sherd::Config::DependencyMetadata)
    sherd_dependencies = Hash(String, Sherd::Config::DependencyMetadata).new
    dependencies.each do |package, keys|
      path, rev_or_version = Converter.keys_to_path_or_version keys
      sherd_dependencies[package] = Sherd::Config::DependencyMetadata.new path, rev_or_version
    rescue ex
      raise Exception.new "Failed to parse #{package}", ex
    end
    sherd_dependencies
  end
end
