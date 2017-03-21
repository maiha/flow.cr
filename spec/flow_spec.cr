require "./spec_helper"

private class Feeder
  include Flow::Send(Int32)
end

private class EvenFilter
  include Flow::Func(Int32, Int32)
  def recv(v : Int32)
    send(v) if v.even?
  end
end

private class Succ
  include Flow::Func(Int32, Int32)
  def recv(n : Int32)
    send(n + 1)
  end
end

describe Flow do
  it "(README)" do
    q1 = Flow::Queue(Int32).new # tmp
    q2 = Flow::Queue(Int32).new # dst

    succ = Succ.new

    q1 >> succ >> q2

    spawn {
      q1.send(1)
      q1.send(2)
    }
    sleep 0.5
    q2.to_a.should eq([2,3])
  end
  
  it "works with feeder(send)" do
    q1 = Flow::Queue(Int32).new
    q2 = Flow::Queue(Int32).new
    
    feed = Feeder.new
    even = EvenFilter.new
    
    feed >> q1 >> even >> q2
    (1..5).each{|i| feed.send(i)}

    sleep 0.5
    q2.size.should eq(2)
  end
end
