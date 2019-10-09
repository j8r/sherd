require "clicr"
require "colorize"
require "./logger"
require "./sherd"
require "./git"
require "semantic_version"

module Sherd::CLI
  extend self

  def create
    Clicr.create(
      name: "sherd",
      info: "Fast Crystal package manager",
      options: {
        quiet: {
          short: 'q',
          info:  "No output",
        },
        verbose: {
          short: 'v',
          info:  "More information",
        },
      },
      commands: {
        build: {
          alias:     'b',
          inherit:   %w(quiet verbose),
          action:    "build",
          info:      "Alias for `sherd exec build`",
          variables: {
            extra: {
              info: "Extra instructions to pass to the command",
            },
          },
        },
        exec: {
          alias:     'e',
          inherit:   %w(quiet verbose),
          action:    "exec",
          info:      "Executes a script, or build a Crystal file",
          arguments: %w(scripts...),
          variables: {
            extra: {
              info: "Extra instructions to pass to the command",
            },
          },
        },
        install: {
          alias:     'i',
          inherit:   %w(quiet verbose),
          arguments: %w(packages...),
          action:    "install",
          info:      "Install package dependencies",
        },
        update: {
          alias:   'u',
          inherit: %w(quiet verbose),
          action:  "update",
          info:    "Update package dependencies to their latest versions",
        },
      }
    )
  rescue ex : Clicr::Help
    Logger.output.puts ex
    exit 0
  rescue ex : Clicr::ArgumentRequired | Clicr::UnknownCommand | Clicr::UnknownOption | Clicr::UnknownVariable
    Logger.error ex
    exit 1
  rescue ex
    if ENV["DEBUG"]?
      ex.inspect_with_backtrace Logger.error
    else
      Logger.error ex
    end
    exit 1
  end

  def build(quiet : Bool, verbose : Bool, extra : String? = nil)
    exec quiet, verbose, ["build"], extra
  end

  def exec(quiet : Bool, verbose : Bool, scripts : Array(String), extra : String? = nil)
    scripts.each do |script|
      Sherd.project.exec_script script, extra
    end
  end

  def install(quiet : Bool, verbose : Bool, packages : Array(String))
    if lock = Sherd.project.lock?
      package_downloader = PackageDownloader(Lock::DependencyLock).new verbose
      max_name_size = lock.dependencies.max_of { |arg, _| arg.size }
      # Copy first all libraries, then build executables
      library_paths = Array(Path).new
      package_downloader.download lock.dependencies do |entry|
        library_paths << entry.copy
        Logger.success "Installed", "#{entry.package_name.ljust(max_name_size)} | #{entry.metadata.version_or_rev}"
      end
      library_paths.each do |path|
        Project.new(path).exec_postinstall?
      end
    else
      raise "For now only installing from lock file is supported"
      # if deps = Sherd.config.dependencies
      # download_dependencies deps, verbose
      # end
      # if dev_deps = Sherd.config.dev_dependencies
      # download_dependencies dev_deps, verbose
      # end
    end
    # At the end, run the project's postinstall
    Sherd.project.exec_postinstall?
  end

  def update(quiet : Bool, verbose : Bool)
    raise "Not implemented yet"
  end

  private struct PackageDownloader(D)
    record Entry(D), package_name : String, metadata : D, git : Git do
      # Copies the package to the project's library directory.
      # Returns the path where it was copied.
      def copy : Path
        dest = Sherd.project.lib_directory / @package_name
        @git.copy @metadata.version_or_rev, dest
        dest
      end
    end

    def initialize(@verbose : Bool = false)
    end

    # Yields each downloaded dependency.
    def download(dependencies, & : Entry(D) ->)
      channel = Channel(Entry(D)).new
      packages = 0
      dependencies.try &.each do |package, metadata|
        packages += 1
        Logger.info "Retrieving", package
        spawn do
          git = Git.new metadata.uri, Sherd.cache_path, @verbose
          channel.send Entry(D).new package, metadata, git
        rescue ex
          channel.close
          raise ex
        end
      end
      packages.times do
        if entry = channel.receive?
          yield entry
        end
      end
    end
  end
end
