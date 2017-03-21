module Flow::Send(T)
  include Schedule

  delegate send, to: dst
  property! dst : Queue(T)?
    
  def >>(q : Queue(T))
    self.dst = q
  end
end
