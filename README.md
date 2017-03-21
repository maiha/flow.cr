# flow.cr [![Build Status](https://travis-ci.org/maiha/flow.cr.svg?branch=master)](https://travis-ci.org/maiha/flow.cr)

Queue based `Channel` friendly data flow library for [Crystal](http://crystal-lang.org/).

- crystal: 0.21.1

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  flow:
    github: maiha/flow.cr
    version: 0.1.0
```

- [Flow::Queue](src/flow/queue.cr) : wrapper to the `Channel` that acts as Indexable
- [Flow::Send](src/flow/send.cr) : sendable to a queue
- [Flow::Recv](src/flow/recv.cr) : receivable from a queue
- [Flow::Func](src/flow/func.cr) : converter between queues

## Usage

### basic

```crystal
require "flow"

class Succ
  include Flow::Func(Int32, Int32)
  def recv(n : Int32)
    send(n + 1)
  end
end

q1 = Flow::Queue(Int32).new # src
q2 = Flow::Queue(Int32).new # dst

succ = Succ.new

q1 >> succ >> q2

spawn {
  q1.send(1)
  q1.send(2)
}
sleep 1
q2.to_a # => [2,3]
```

### aggregate by scheduler

```crystal
class OddFilter
  include Flow::Func(Int32, Int32)

  def recv(n : Int32)
    send(n) if n.odd?
  end
end

record Sum, total : Int32 = 0 do
  include Flow::Func(Int32, Int32)

  def recv(n : Int32)
    total += n
  end

  def flush!
    send(total)
    @total = 0
  end
end

q1 = Flow::Queue(Int32).new # first queue
q2 = Flow::Queue(Int32).new # odd numbers
q3 = Flow::Queue(Int32).new # aggregated

odd = OddFilter.new
sum = Sum.new

q1 >> odd >> q2 >> sum >> q3

sum.schedule(interval: 1.second) { sum.flush! }

# some feeder
spawn {
  q1.send(1)
  q1.send(2)
  q1.send(3)
}

sleep 1
q3.last # => 4 
```

## Contributing

1. Fork it ( https://github.com/maiha/flow.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
