% This file will contain all the portObjects' descriptions and code
declare
%%%%% CONSTANTS %%%%%%%%%
SPEED = 5
DELAY = 200
MAXX  = 7
MAXY  = 7
fun{GETDIR Dir}
   case Dir
   of up   then dx(x: 0 y:~1)
   [] down then dx(x: 0 y: 1)
   [] left then dx(x:~1 y: 0)
   else         dx(x: 1 y: 0)
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

%%%%%%% MAPRELATED PORTOBJECTS %%%%%%%%%%%%

%@pre:  C     = coord(x:X y:Y) with X and Y integers
%       Init  = state(occupied) or state(empty)
%       Mapid = Pid of the MapControler
%@post: Returns the Pid of the tile
fun{Tile Init C Mapid}
   Tilid
   proc{SignalArrival}
      %Signals arrival of someone to cases around
      % BUT!!! Only Player VS PNJ !!!!
      {Send Mapid send(x:C.x   y:C.y+1 new(up))}
      {Send Mapid send(x:C.x+1 y:C.y   new(right))}
      {Send Mapid send(x:C.x-1 y:C.y   new(left))}
      {Send Mapid send(x:C.x   y:C.y-1 new(down))}
   end
   Tid   = {Timer}
   Tilid = {NewPortObject Init
	    fun{$ Msg state(State)}
	       case Msg
	       of get(X) then
		  X=State
		  state(State)
	       [] comming(T Plid Val) then
		  {Send Tid starttimer(Tilid T arrived(Plid Val))}
		  state(reserved)
	       [] arrived(Plid Val) then
		  Val=unit
		  %TODO wild pokemoz
		  {SignalArrival}
		  state(occupied(Plid))
	       [] new(X) then
		  case State
		  of occupied(Y) then
		     %TODO!!
		     %Si le temps implémenter le 2 Vs 1
		     state(State)
		  else
		     % We don't care
		     state(State)
		  end
	       [] left then
		  state(empty)
	       end
	    end}
in
   Tilid
end
%
%@post: Returns the pid of the controller (through which every command
%       to the tiles passes)
fun{MapController}
   MapRec
   fun{CheckEdges X Y}
      if X>0 andthen X=<MAXX andthen
	 Y>0 andthen Y=<MAXY then
	 true
      else
	 false
      end
   end
   Mapid = {NewPortObjectMinor
	    proc{$ Msg}
	       case Msg
	       of send(x:X y:Y Sig) then
		  if{CheckEdges X Y} then
		     {Send MapRec.Y.X Sig}
		  end
		%plus nécessaire, supprimer a la fin
	       [] check(x:X y:Y B) then
		  if {CheckEdges X Y} andthen
		     {Send MapRec.Y.X get($)}==empty then
		     B=true
		  else
		     B=false
		  end
	       [] checksig(x:X y:Y B sig:Sig) then
		  if {CheckEdges X Y} andthen
		     {Send MapRec.Y.X get($)}==empty then
		     B=true
		     {Send MapRec.Y.X Sig}
		  else
		     B=false
		  end
	       end
	    end}
   
in
   MapRec = {MakeTuple 'mapids' MAXY}
   for J in 1..MAXY do
      MapRec.J = {MakeTuple 'mapids' MAXX}
      for I in 1..MAXX do
	 MapRec.J.I = {Tile state(empty) coord(x:I y:J) Mapid}
      end
   end
   Mapid
end

%%%%%%%%% TRAINER-RELATED PORTOBJECTS %%%%%%%%%
% This portObject will serve as a bridge between the controller
% and the GUI
%@pre : C    = pos(x:X y:Y) the start coordinates (X/Y are integers)
%       Anid = Pid of animation thread
%@post: Returns the Pid of the trainer

fun{Trainer C Anid}
   Init = state(C dir:up)
   Trid = {NewPortObject Init
	   fun{$ Msg state(Pos dir:Dir)}
	      case Msg
	      of getDir(X) then
		 X=Dir
		 state(Pos dir:Dir)
	      [] getPos(X) then
		 X=Pos
		 state(Pos dir:Dir)
	      [] moveTo(x:X y:Y) then
		 {Send Anid move(Dir)}
		 state(pos(x:X y:Y) dir:Dir)
	      [] turn(NewDir) then
		 {Send Anid turn(NewDir)}
		 state(Pos dir:NewDir)
	      end	      
	   end}
in
   Trid
end
%@pre : Mapid = the Pid of the mapControler
%       Trid  = the Pid of the trainer this controller is destined to
%@post: Returns the controler of the trainer
fun{TrainerController Mapid Trid Speed}
   Wid  = {Waiter}
   Plid = {NewPortObject state(still)
	   fun{$ Msg state(State)}
	      {Show Msg}
	      case Msg
	      of endfight then
		 state(still)
	      [] move(NewDir) then
		 if State == still then
		    ActDir = {Send Trid getDir($)}
		 in
		    if ActDir == NewDir then
		       Pos  = {Send Trid getPos($)}
		       Dx   = {GETDIR NewDir}
		       NewX = Pos.x+Dx.x
		       NewY = Pos.y+Dx.y
		       Val %will be bound on arrival
		       Sig  = comming(Speed*DELAY Plid Val)
		    in
		       %Check for boundaries and if the tile is free
		       %then send arriving signal
		       if {Send Mapid checksig(x:NewX y:NewY $ sig:Sig)} then
			  {Show moving}
 			  {Send Trid moveTo(x:NewX y:NewY)}

			  {Send Wid wait(Plid  Val arrived)}
			  {Send Wid wait(Mapid Val
					 send(x:Pos.x y:Pos.y left))}
			  state(moving)
		       else
			  {Show frontier#NewX#NewY}
			  state(still)
		       end
		    else
		       {Show turned}
		       {Send Trid turn(NewDir)}
		       state(still)
		    end
		 else
		    %Neglect info if moving
		    state(State)
		 end
	      [] arrived then
		 %{Send Trid arrived}
		 state(still)
	      end
	   end}
in
   %TODO: -need to check the 'fight' signal
   %      -need to add smth for the AI of other players
   Plid
end
\insert 'animate_port.oz'
% Function that creates a trainer
%@post: returns the id of the PlayerController
fun{CreateTrainer Name X0 Y0 Speed Mapid Canvash}
   Anid = {AnimateTrainer Canvash X0-1 Y0-1 Speed Name}
   Trid = {Trainer pos(x:X0 y:Y0) Anid}
in
   {TrainerController Mapid Trid Speed}
end