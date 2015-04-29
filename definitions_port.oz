fun{GETDIR Dir}
   case Dir
   of up   then dx(x: 0 y:~1)
   [] down then dx(x: 0 y: 1)
   [] left then dx(x:~1 y: 0)
   else         dx(x: 1 y: 0)
   end
end
fun{GETINVDIR Dir}
   case Dir
   of down  then dx(x: 0 y:~1)
   [] up    then dx(x: 0 y: 1)
   [] right then dx(x:~1 y: 0)
   else          dx(x: 1 y: 0)
   end
end
fun{GETDIRSIDE Dir}
   case Dir
   of up then ~1
   [] left then ~1
   else 1 end
end

%%%%% DEFINITION OF PORTOBJECTS' CREATION %%%%%%
fun {NewPortObject Init Func}
   proc {Loop S State}
      case S of Msg|S2 then
         {Loop S2 {Func Msg State}}
      end
   end
   P S
in
   P={NewPort S}
   thread {Loop S Init} end
   P
   %replace by proc{$ X} {Send P X} end ?
end
fun {NewPortObjectKillable Init Func}
   proc {Loop S State}
      case State of state(killed) then
         {Show 'thread_killed'}
         skip
      else
         case S of Msg|S2 then
            {Loop S2 {Func Msg State}}
         end
      end
   end
   P S
in
   P={NewPort S}
   thread {Loop S Init} end
   P
end
fun {NewPortObjectKillableOnExit Init Func OnExit}
   proc {Loop S State}
      case State of state(killed) then
         {Show 'thread_killed'}
         {OnExit}
      else
         case S of Msg|S2 then
            {Loop S2 {Func Msg State}}
         end
      end
   end
   P S
in
   P={NewPort S}
   thread {Loop S Init} end
   P
end
fun {NewPortObjectMinor Func}
   proc {Loop S}
      case S of Msg|S2 then
         {Func Msg}
         {Loop S2}
      end
   end
   P S
in
   P={NewPort S}
   thread {Loop S} end
   P
end
%@post : Returns a PortID for a timer. The timer can receive a
%        signal and send out
fun{Timer} % a simple timer function
   {NewPortObjectMinor proc{$ Msg}
   case Msg
   of starttimer(Pid T) then
      thread
      {Delay T}
      {Send Pid stoptimer}
   end
[] starttimer(Pid T Sig) then
   thread
   {Delay T}
   {Send Pid Sig}
end
end
end}
end
fun{Waiter}
   {NewPortObjectMinor proc{$ Msg}
                           case Msg of wait(Pid X Sig) then
                              thread
                              {Wait X}
                              {Send Pid Sig}
                           end
                        end
end}
end
%%%%%%% SPECIAL ARROWMOVEMENTS %%%%%%%%%%%
fun{GetArrows MaxX MaxY}
   ArrowId = {NewPortObjectKillable state(1 1)
   fun{$ Msg state(X Y)}
      case Msg
      of up(NewX NewY) then
         if Y==1 then NewX=X NewY=MaxY
         else NewX=X NewY=Y-1 end
         state(NewX NewY)
      [] down(NewX NewY) then
         if Y==MaxY then NewX=X NewY=1
         else NewX=X NewY=Y+1 end
         state(NewX NewY)
      [] right(NewX NewY) then Nx Ny in
         if X==MaxX then Nx=1 Ny=Y+1
         else Nx=X+1 Ny=Y end
         if Ny==MaxY+1 then NewY=1
         else NewY=Ny end
         NewX=Nx
         state(NewX NewY)
      [] left(NewX NewY) then Nx Ny in
         if X==1 then Nx=MaxX Ny=Y-1
         else Nx=X-1 Ny=Y end
         if Ny==0 then NewY=MaxY
         else NewY=Ny end
         NewX=Nx
         state(NewX NewY)
      [] get(XX YY) then XX=X YY=Y state(X Y)
      [] getLast(XX YY B) then
         XX=X YY=Y
         if B==true then state(X Y)
         else state(killed) end
      [] kill then state(killed)
      end
   end}
in
   ArrowId
end
