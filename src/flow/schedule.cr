module Flow::Schedule
  def schedule(interval : Time::Span, initial_delay_ms : Int32 = 0, &block)
    ::spawn do
      sleep (initial_delay_ms / 1000) if initial_delay_ms > 0
      loop {
        start = Time.now
        block.call
        sleep [interval.seconds - (Time.now - start).milliseconds / 1000.0, 0].max
      }
    end
  end    
end
