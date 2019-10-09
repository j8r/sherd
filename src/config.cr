require "ini"
require "uri"
require "./git"

struct Sherd::Config
  record Info, name : String, description : String?, license : String?, version : String?

  struct DependencyMetadata
    getter uri : URI
    getter version_expr_or_rev : String | Git::Revision | Nil

    # getter versions
    def initialize(path : String, @version_expr_or_rev : String | Git::Revision | Nil = nil)
      @uri = URI.parse "//" + path
    end

    def self.parse(metadata : String) : DependencyMetadata
      path, _, raw_version_or_rev = metadata.partition ' '
      if raw_version_or_rev.empty?
        version_or_rev = nil
      elsif git_revision = Git::Revision.parse? raw_version_or_rev
        version_or_rev = git_revision
      else
        version_or_rev = raw_version_or_rev
      end
      new path, version_or_rev
    end

    def to_s(io : IO)
      io << uri.host << uri.path
      io << ' ' if @version_expr_or_rev
      io << @version_expr_or_rev
    end
  end

  record Package, name : String, version : String, description : String?, license : String?

  getter package : Package,
    authors : Hash(String, String)?,
    dependencies : Hash(String, DependencyMetadata)?,
    dev_dependencies : Hash(String, DependencyMetadata)?,
    scripts : Hash(String, String)?

  def initialize(
    @package : Package,
    @authors : Hash(String, String)?,
    @dependencies : Hash(String, DependencyMetadata)?,
    @dev_dependencies : Hash(String, DependencyMetadata)?,
    @scripts : Hash(String, String)?
  )
  end

  def self.file(directory : Path)
    directory / "sherd.ini"
  end

  def self.new(directory : Path)
    File.open file(directory) do |io|
      new io
    rescue ex
      raise Exception.new "Failed to parse #{file(directory)}", ex
    end
  end

  def initialize(data : IO | String)
    ini = INI.parse data
    package_hash = ini.delete("package") || raise "Package section missing"
    @package = Package.new(
      name: (package_hash.delete("name") || raise "Package name field is missing"),
      version: (package_hash.delete("version") || raise "Package version field missing"),
      description: package_hash.delete("description"),
      license: package_hash.delete("license"),
    )
    raise "Unknown package key: #{package_hash[0]}" if !package_hash.empty?

    @authors = ini.delete "authors"
    @dependencies = convert_deps ini.delete("dependencies")
    @dev_dependencies = convert_deps ini.delete("dev_dependencies")
    @scripts = ini.delete("scripts")

    raise "Unknown section: #{ini.keys[0]}" if !ini.empty?
  end

  private def convert_deps(deps)
    if deps
      hash = Hash(String, DependencyMetadata).new
      deps.each do |name, metadata|
        hash[name] = DependencyMetadata.parse metadata
      end
      hash
    end
  end

  def build(io : IO)
    ini = Hash(String, Hash(String, String)).new

    ini["package"] = {"name" => @package.name, "version" => @package.version}
    if description = @package.description
      ini["package"]["description"] = description
    end
    if license = @package.license
      ini["package"]["license"] = license
    end

    if authors = @authors
      ini["authors"] = authors
    end

    if dependencies = @dependencies
      ini["dependencies"] = dependencies.transform_values &.to_s
    end
    if dev_dependencies = @dev_dependencies
      ini["dev_dependencies"] = dev_dependencies.transform_values &.to_s
    end

    if scripts = @scripts
      ini["scripts"] = scripts
    end

    INI.build io, ini, space: true
  end

  def build : String
    String.build do |str|
      build str
    end
  end
end
