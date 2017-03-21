module Flow::Recv(T)
  include Schedule

  property! src : Queue(T)?
  abstract def recv(v : T) : Nil

  def spwan : Nil
    ::spawn do
      loop {
        select
        when buf = src.channel.receive
          recv(buf)
        end
      }
    end
  end
end
