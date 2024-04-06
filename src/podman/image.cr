require "json"

class Podman::Image
  include JSON::Serializable
  @[JSON::Field(key: "Id")]
  getter id : String
  @[JSON::Field(key: "Names")]
  getter names = Array(String).new
  @[JSON::Field(key: "Created", converter: Time::EpochConverter)]
  getter created_at : Time
  @[JSON::Field(key: "Containers")]
  getter containers : Int32

  @[JSON::Field(key: "Names")]
  getter names = Array(String).new

  def name
    @names.first || id.truncated
  end

  def to_s(io)
    if name = @names.first?
      io << name << " (" << @id.truncated << ')'
    else
      io << @id.truncated
    end
    io << ' '
    @created_at.to_s(io)
  end

  def_equals @id
end
