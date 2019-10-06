require "ini"
require "semantic_version"
require "openssl"
require "./git"

struct Sherd::Lock
  getter dependencies : Hash(String, DependencyLock)

  struct DependencyLock
    getter uri : URI,
      version_or_rev : SemanticVersion | Git::Revision,
      hash : String

    def initialize(path : String, @version_or_rev : SemanticVersion | Git::Revision, hash : String)
      @hash = hash.lchop "sha512:"
      @uri = URI.parse "//" + path
    end

    def to_h : Hash(String, String)
      {
        "path"    => uri.host.to_s + uri.path.to_s,
        "version" => @version_or_rev.to_s,
        "hash"    => "sha512:" + @hash,
      }
    end
  end

  def initialize(@dependencies : Hash(String, DependencyLock))
  end

  def self.file(directory : Path)
    directory / "sherd.ini"
  end

  def self.new(path : Path)
    File.open path / "sherd.lock" do |io|
      new io
    rescue ex
      raise Exception.new "Failed to parse #{path}", ex
    end
  end

  def initialize(data : IO | String)
    ini = INI.parse data
    @dependencies = Hash(String, DependencyLock).new
    ini.each do |name, lock_data|
      if raw_version_or_rev = lock_data.delete "version"
        version_or_rev = Git::Revision.parse?(raw_version_or_rev) || SemanticVersion.parse(raw_version_or_rev)
        lock = DependencyLock.new(
          path: (lock_data.delete("path") || raise "Dependency path missing for '#{name}'"),
          version_or_rev: version_or_rev,
          hash: (lock_data.delete("hash") || raise "Dependency hash missing for '#{name}'"),
        )
      else
        raise "Dependency version missing for '#{name}'"
      end
      raise "Unknown lock key in '#{name}' section: #{lock_data[0]}" if !lock_data.empty?
      @dependencies[name] = lock
    end
  end

  def build(io : IO)
    hash = @dependencies.transform_values &.to_h
    INI.build io, hash, space: true
  end

  def build : String
    String.build do |str|
      build str
    end
  end

  # Lock a dependency.
  def lock(dependency : String, path : String, version_or_rev : SemanticVersion | Git::Object::Type, local_path : Path) : DependencyLock
    dependencies[dependency] = DependencyLock.new(
      path: path,
      version_or_rev: version_or_rev,
      hash: hash_library local_path / dependency
    )
  end

  private def hash_library(path : Path, digest : OpenSSL::Digest = OpenSSL::Digest.new("SHA512")) : String
    walk path, digest
    Base64.strict_encode digest.digest
  end

  private def walk(path : Path, digest : OpenSSL::Digest)
    Dir.each_child path.to_s do |child|
      child_path = path / child
      if Dir.exists? child_path
        walk child_path, digest
      else
        digest.file child_path.to_s
      end
    end
  end
end
