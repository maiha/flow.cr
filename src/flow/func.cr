module Flow::Func(T,U)
  include Recv(T)
  include Send(U)
end
