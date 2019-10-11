require "./shards"
require "./config"
require "./lock"
require "./logger"

struct Sherd::Project
  getter directory : Path
  getter bin_directory : Path { @directory / "bin" }
  getter lib_directory : Path { @directory / "lib" }
  property verbose : Bool = true

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

  # Executes the postinstall script, if any.
  def exec_postinstall?
    if config.scripts.try &.has_key? "postinstall"
      exec_script "postinstall"
    end
  end

  # Executes the a script, else raise.
  def exec_script(name : String, extra : String? = nil)
    scripts = config.scripts
    if !scripts
      raise "No script is available - define a `scripts` section in the configuration"
    end
    script_command = scripts[name]?
    if !script_command
      raise "No such script: #{name}"
    end
    # If the command is a Crystal source file
    if Path[script_command].extension == ".cr" && File.exists? script_command
      _, _, bin_name = script_command.partition ':'
      bin_name = config.package.name if bin_name.empty?
      command = "crystal build #{script_command} -o #{bin_directory / bin_name} #{extra}"

      Dir.mkdir_p bin_directory.to_s
      Logger.info "Building", bin_name
      if exec command
        Logger.success "Built", bin_name
      else
        raise "Build returned an error: '#{command}'"
      end
    else
      Logger.info "Running", name
      if exec script_command
        Logger.success "Finished", name
      else
        raise "Command returned an error: '#{script_command}'"
      end
    end
  end

  private def exec(command : String) : Bool
    Process.new(
      command: "/bin/sh",
      args: {"-c", "cd #{@directory}; #{command}"},
      output: (@verbose ? Logger.output : Process::Redirect::Close),
      error: Logger.error
    ).wait.success?
  end
end
