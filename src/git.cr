require "uri"
require "semantic_version"
require "crystar"
require "./logger"
require "file_utils"

struct Sherd::Git
  module Revision
    def self.parse?(data : String) : Revision?
      if rev = data.lchop? "commit:"
        Commit.new rev
      elsif head = data.lchop? "heads/"
        Head.new head
      elsif tag = data.lchop? "tags/"
        Tag.new tag
      end
    end
  end

  record Commit, value : String do
    include Revision

    def to_s(io : IO)
      io << @value
    end
  end

  record Head, value : String do
    include Revision

    def to_s(io : IO)
      io << "heads/" << @value
    end
  end

  record Tag, value : String do
    include Revision

    def to_s(io : IO)
      io << "tags/" << @value
    end
  end

  getter name : String,
    repository_path : Path,
    uri : URI

  # Creates a new Git repositor by cloning it or updates it if already present.
  def initialize(@uri : URI, directory : Path, @verbose : Bool = false)
    unless uri_host = @uri.host
      raise "URI host field missing: #{uri}"
    end
    unless uri_path = @uri.path
      raise "URI path field missing: #{uri}"
    end
    @repository_path = directory / uri_host / uri_path
    @name = @repository_path.basename

    url = URI.new(scheme: "https", host: uri.host.as(String), path: uri.path.as(String))
    # url = URI.new(scheme: "ssh", user: "git", host: uri.host.as(String), path: uri.path.as(String)).to_s

    # "ssh://"
    if Dir.exists?(@repository_path)
      if git({"fetch", "--all", "--force", "--prune", "--tags"})
        return
      else
        # Try to clone the repository again in any case of fetch failing
        FileUtils.rm_rf @repository_path.to_s
      end
    end

    if !git({"clone", "--mirror", url.to_s, @repository_path.to_s}, chdir: false)
      raise "Fail to clone #{url}"
    end
  end

  # Copy the repository to a given version.
  def copy(version_or_rev : SemanticVersion | Revision, destination : Path)
    if File.exists? destination
      FileUtils.rm_r destination.to_s
    end
    Dir.mkdir_p destination.to_s
    version = convert_version version_or_rev
    if output = git_string({"archive", "--format=tar", "--prefix=", version})
      first = true
      Crystar::Reader.open IO::Memory.new(output), &.each_entry do |entry|
        if first
          first = false
          next
        end
        path = destination / entry.name
        case entry.file_info.type
        when .directory?
          Dir.mkdir path.to_s
        when .file?
          File.open path, "wb", entry.file_info.permissions do |io|
            IO.copy entry.io, io
          end
        else
          if @verbose
            Logger.info "File ignored", path.to_s
          end
        end
      end
    else
      raise "Fail to archive #{@repository_path} at #{version}"
    end
    # Crystar::Reader.open io, &.each_entry do |entry|
    # p "Contents of #{entry.name}"
    # IO.copy entry.io, STDOUT
    # p "\n"
    # end
  end

  # Yields each version tag, starting with `v`, for a given repository path.
  def each_version(&block : String ->) : Nil
    if output = git_string { "tag" }
      output.each_line do |tag|
        if version = tag.lchop? 'v'
          yield version
        end
      end
    else
      raise "Git tag returns status code error 1 for #{@repository_path}"
    end
  end

  # Show a file at a revision. Returns `nil` if not present, or if the command failed.
  def show(version_or_rev : SemanticVersion | Object::Type, file : String) : String?
    git_string({"show", convert_version(version_or_rev) + ':' + file})
  end

  # Returns the command output as a string, or `nil` if it failed.
  private def git_string(args : Tuple) : String?
    success = false
    output = String.build do |str|
      success = git args, str
    end
    success ? output : nil
  end

  private def git(args : Tuple, io : IO = (@verbose ? Logger.output : Process::Redirect::Close), chdir : Bool = true) : Bool
    Process.new(
      "git",
      chdir ? ({"-C", @repository_path.to_s} + args) : args,
      output: io,
      error: (@verbose ? Logger.error : Process::Redirect::Close),
    ).wait.success?
  end

  private def convert_version(version_or_rev : SemanticVersion | Revision) : String
    if version_or_rev.is_a? SemanticVersion
      "v" + version_or_rev.to_s
    else
      version_or_rev.to_s
    end
  end
end
