module Podman
  PODMAN = "podman"
  Log    = ::Log.for "podman"

  private def self.add_remote(args, remote)
    if remote
      a = ["--remote=true", "--connection=#{remote}"]
      a.concat(args)
    else
      args
    end
  end

  def self.run_capture_all(args, remote)
    start = Time.utc
    args = add_remote(args, remote)
    Log.debug { "Running: podman #{Process.quote(args)}" }
    process = Process.new(PODMAN, args: args,
      input: Process::Redirect::Close,
      output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    output = process.output.gets_to_end.chomp
    error = process.error.gets_to_end.chomp
    status = process.wait
    Log.debug { "Run in #{Time.utc - start}" }
    {status, output, error}
  end

  def self.run_capture_stdout(args, remote : String?)
    status, output, error = run_capture_all(args, remote)
    unless status.success?
      raise PodmanException.new("podman command failed: #{status.exit_code}",
        "podman #{Process.quote(args)}", error)
    end
    output
  end

  def self.get_containers(names : Array(String), *, remote : String?) : Array(Podman::Container)
    run_interal(Array(Podman::Container),
      %w(container ls -a --format json) + ["--filter=name=#{names.join('|')}"], remote: remote)
  end

  def self.get_container_by_id(id : String, *, remote : String?) : Array(::Podman::Container)
    run_interal(Podman::Container,
      %w(container ls -a --format json) + ["--filter=id=#{id}"], remote: remote)
  end

  def self.inspect_containers(ids : Enumerable(String), *, remote : String?) : Array(Podman::Container::Inspect)
    return [] of Podman::Container::Inspect if ids.empty?
    run_interal(Array(Podman::Container::Inspect),
      %w(container inspect) + ids, remote: remote)
  end

  def self.get_images(remote : String?)
    run_interal(Array(Podman::Image), %w(image ls --format json), remote: remote)
  end

  def self.get_container_logs(id, tail, remote)
    args = add_remote ["logs", "--tail", tail.to_s, id], remote

    Log.debug { "Running: podman #{Process.quote(args)}" }
    String.build do |io|
      Process.run(PODMAN, args: args,
        input: Process::Redirect::Close,
        output: io, error: io)
    end
  end

  private def self.run_interal(t : T.class, *args, **kwargs) : T forall T
    T.from_json(run_capture_stdout(*args, **kwargs))
  end
end
