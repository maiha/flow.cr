require "./spec_helper"

record Packet, port : Int32, cmd : String
#   1 | port=6379, name="GET"
#   2 | port=7001, name="AUTH"
#   3 | port=6379, name="PING"

class Feeder
  include Flow::Send(Packet)
end

class Aggregator
  include Flow::Func(Packet, Hash(Int32, Hash(String, Int32)))

  # aggregated output
  #   port=6379, hash={"GET" => 24, "PING" => 1}
  #   port=7001, hash={"AUTH" => 1, "PING" => 2}

  # counters of commands those are grouped by `port`
  property! hash : Hash(Int32, Hash(String, Int32))?
  #   {
  #     6379 => {"GET" => 24, "PING" => 1},
  #     7001 => {"AUTH" => 1, "PING" => 2},
  #   }
  
  def initialize
    reset!
  end

  def recv(pc : Packet)
    sum = hash[pc.port] ||= Hash(String, Int32).new { 0 }
    sum[pc.cmd] += 1
  end

  def flush!
    send(hash) if hash.any?
    reset!
  end

  private def reset!
    @hash = Hash(Int32, Hash(String, Int32)).new
  end
end

private class PacketCapture
  include Flow::Send(Packet)
end

describe "(Aggregation feature)" do
  it "works" do
    q1 = Flow::Queue(Packet).new
    q2 = Flow::Queue(Hash(Int32, Hash(String, Int32))).new
    
    feed = PacketCapture.new
    aggr = Aggregator.new
    
    feed >> q1 >> aggr >> q2

    aggr.schedule(0.5.seconds) { aggr.flush! }
    
    feed.send(Packet.new(6379, "GET"))
    feed.send(Packet.new(6379, "SET"))
    sleep 0.5
    feed.send(Packet.new(6379, "GET"))
    feed.send(Packet.new(7001, "AUTH"))
    feed.send(Packet.new(6379, "GET"))
    sleep 0.5

    sleep 0.5

    q2.size.should eq(2)
    q2[0].should eq({6379 => {"GET" => 1, "SET" => 1}})
    q2[1].should eq({6379 => {"GET" => 2}, 7001 => {"AUTH" => 1}})
  end
end
