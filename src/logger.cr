require "colorize"

module Sherd::Logger
  extend self
  class_property output : IO::FileDescriptor = STDOUT
  class_property error : IO::FileDescriptor = STDERR
  class_property colorize : Bool = @@output.tty?

  private def log(title : String, message : String, color)
    title += ": "
    if @@colorize
      @@output << title.colorize.fore color
    else
      @@output << title
    end
    @@output.puts message
  end

  def info(title : String, message : String)
    log title, message, :yellow
  end

  def success(title : String, message : String)
    log title, message, :green
  end

  def error(message : String)
    print_error message
  end

  private def print_error(message)
    if @@colorize
      @@error << "ERR!".colorize.red.mode(:bold) << ' ' << message.colorize.light_magenta << '\n'
    else
      @@error << "ERR! \"" << message << "\"\n"
    end
    @@error.flush
  end

  def error(ex : Exception)
    print_error ex
    if cause = ex.cause
      error cause
    end
  end

  def finalize
    @@output.close
    @@error.close
  end
end
