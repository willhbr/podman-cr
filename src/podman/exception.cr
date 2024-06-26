class Podman::Exception < Exception
  def initialize(message, @container_logs : String? = nil)
    super message
  end

  def initialize(message, cause)
    super
  end

  def print_message(io : IO)
    io.puts self.message.colorize(:red)
    if logs = @container_logs
      unless logs.blank?
        io.puts logs
      end
    end
  end
end

class Podman::PodmanException < Podman::Exception
  def initialize(message : String, @command : String, @failure : String? = nil)
    super message
  end

  def print_message(io : IO)
    Colorize.with.red.surround(io) do
      if msg = self.message
        io << msg
      else
        io << "podman command failed"
      end
      io << "\n\n> " << @command
      if f = @failure
        io << "\n"
        io.puts f
      end
    end
  end
end
