# NOTE:
# Implementing `Queue(T) < Channel::Buffered(T)` is best.
# But we can't override `self.new` on current crystal.
# So, `Queue` contains `Channel` and delegates to the `queue` as `raw`.
class Flow::Queue(T)
  CAPACITY = 65535

  getter channel
  delegate send, to: channel

  include Enumerable(T)
  delegate each, to: raw

  include Indexable(T)
  delegate unsafe_at, to: raw

  def initialize(capacity = CAPACITY)
    @channel = Channel::Buffered(T).new(capacity)
  end

  def raw
    channel.queue
  end

  def >>(recv : Recv(T)) : Recv(T)
    recv.src = self
    recv.spwan
    return recv
  end
end
