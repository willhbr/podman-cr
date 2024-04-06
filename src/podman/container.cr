require "json"

class Podman::Container
  include JSON::Serializable

  enum State
    Unknown
    Created
    Running
    Paused
    Exited
    Stopped
    Configured

    def self.from_json(parser : JSON::PullParser) : State
      parse?(parser.read_string) || State::Unknown
    end
  end

  @[JSON::Field(key: "Id")]
  getter id : String
  @[JSON::Field(key: "Image")]
  getter image : String
  @[JSON::Field(key: "ImageID")]
  getter image_id : String
  @[JSON::Field(key: "Names")]
  getter names : Array(String)

  def name
    @names.first.not_nil!
  end

  @[JSON::Field(key: "StartedAt", converter: Time::EpochConverter)]
  getter started_at : Time
  @[JSON::Field(key: "AutoRemove")]
  getter auto_remove : Bool

  def uptime : Time::Span
    Time.utc - @started_at
  end

  @[JSON::Field(key: "State")]
  getter state : State

  @[JSON::Field(key: "ExitCode")]
  getter exit_code : Int32
  @[JSON::Field(key: "ExitedAt", converter: Time::EpochConverter)]
  getter exited_at : Time

  @[JSON::Field(key: "Networks")]
  getter networks : Set(String)

  def uptime_or_downtime : Time::Span
    if @state.exited?
      self.downtime
    else
      self.uptime
    end
  end

  def downtime
    Time.utc - @exited_at
  end

  def uptime : Time::Span
    Time.utc - @started_at
  end

  @[JSON::Field(key: "Labels")]
  getter _labels : Hash(String, String)?

  def labels
    @_labels ||= Hash(String, String).new
  end

  def pod_hash : String
    self.labels["pod_hash"]? || ""
  end

  @[JSON::Field(key: "Labels")]
  getter _labels : Hash(String, String)?

  struct Port
    include JSON::Serializable
    @[JSON::Field(key: "host_port")]
    getter host_port : Int32
    @[JSON::Field(key: "container_port")]
    getter container_port : Int32
  end

  @[JSON::Field(key: "Ports")]
  getter _ports : Array(Port)?

  def labels
    @_labels ||= Hash(String, String).new
  end

  def ports
    @_ports ||= Array(Port).new
  end
end

class Podman::Container::Inspect
  include JSON::Serializable
  @[JSON::Field(key: "Id")]
  getter id : String

  struct Config
    include JSON::Serializable
    @[JSON::Field(key: "CreateCommand")]
    getter create_command : Array(String)

    @[JSON::Field(key: "Secrets")]
    getter secrets = Array(SecretConfig).new
  end

  struct SecretConfig
    include JSON::Serializable
    @[JSON::Field(key: "Name")]
    getter name : String
  end

  @[JSON::Field(key: "Config")]
  getter config : Config
end
