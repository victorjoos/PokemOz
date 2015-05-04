functor
import
   PortDefinitions
   Widget
export
   ArtificialPlayer
   GetEnemyAi
define
   DELAY = Widget.delay
   KEYS = Widget.keys
   NewPortObject = PortDefinitions.port
   NewPortObjectMinor = PortDefinitions.mPort

   MAXX = Widget.maxX
   MAXY = Widget.maxY
   MAPREC = Widget.mapRec

   fun {ArtificialPlayer}
      MapPort = proc{$ send(x:X y:Y Sig)} {Send MAPREC.Y.X Sig} end
      KeysPort = KEYS
      %TRAINERADD=1
      %GRASSPENALTY=100
      %DIRBONUS=10
      %RECURSIONLIMIT=1

      % Checks if the coordinates aren't out of bounds
      fun{CheckEdges X Y}
	 if X>0 andthen X=<MAXX andthen
	    Y>0 andthen Y=<MAXY then
	    true
	 else
	    false
	 end
      end
      % Sends a query to each tile to have the position of each
      % trainer on the map (and the direction)
      fun {GetTrainerList X Y}
	 TileState = {MapPort send(x:X y:Y get($))}
	 NewX NewY
      in
	 if X==MAXX andthen Y==MAXY then nil
	 else
	    if X==MAXX then NewX=1 NewY=Y+1
	    else NewX=X+1 NewY=Y end
	    case TileState
	    of occupied(TrainerID) then
	       trainer(x:X y:Y dir:{Send TrainerID.pid getDir($)})|{GetTrainerList NewX NewY}
	    else {GetTrainerList NewX NewY}
	    end
	 end
      end

      fun {Grass X Y}
	 if {MapPort send(x:X y:Y getGround($))}==grass then true else false end
      end
      fun {Neighbours X Y}
	 Up Down Left Right
      in
	 if {CheckEdges X-1 Y} then
	    Left = c(x:X-1 y:Y)|nil else Left=nil end
	 if {CheckEdges X+1 Y} then
	    Right = c(x:X+1 y:Y)|Left else Right=Left end
	 if {CheckEdges X Y-1} then
	    Up = c(x:X y:Y-1)|Right else Up=Right end
	 if {CheckEdges X Y+1} then
	    Down = c(x:X y:Y+1)|Up else Down=Up end
	 Down
      end
      fun {InitRecord Type X Y}
	 MapRec = {MakeTuple 'map' MAXY}
      in
	 for J in 1..MAXY do
	    MapRec.J = {MakeTuple 'r' MAXX}
	    for I in 1..MAXX do
	       if J==Y andthen I==X then
		  if Type==cost then MapRec.J.I = 0
		  else MapRec.J.I=none end
	       else MapRec.J.I = nil end
	    end
	 end
	 MapRec
      end
      fun {PathFinder Frontier CameFrom CostMap}
	 fun {MemberOfMap H X Y}
	    if Y > MAXY then false
	    else NewX NewY in
	       if H == CameFrom.Y.X then true
	       else
		  if X==MAXX then NewX=1 NewY=Y+1
		  else NewX=X+1 NewY=Y end
		  {MemberOfMap H NewX NewY}
	       end
	    end
	 end
	 fun {NewRecord OldAcc H CameFromH}
	    MapRec in
	    MapRec = {MakeTuple 'map' MAXY}
	    for J in 1..MAXY do
	       MapRec.J = {MakeTuple 'r' MAXX}
	       for I in 1..MAXX do
		  if H.x==I andthen H.y==J then MapRec.J.I = CameFromH
		  else MapRec.J.I = OldAcc.J.I end
	       end
	    end
	    MapRec
	 end
	 fun {CalcCost FromCost X Y}
	    AddCost
	    TrainerCost
	 in
	    if {Grass X Y} then AddCost=5 else AddCost=1 end
	    case {MapPort send(x:X y:Y get($))}
	    of occupied(_) then TrainerCost = 10 else TrainerCost=0 end
	    FromCost+AddCost+TrainerCost
	 end
	 fun {Loop From L Acc AccFrom AccCost}
	    case L of nil then Acc#AccFrom#AccCost
	    [] H|T then
	       if {MemberOfMap H 1 1} then {Loop From T Acc AccFrom AccCost}
	       else
		  {Loop From T {Append Acc [H]}
		   {NewRecord AccFrom H c(x:From.x y:From.y)}
		   {NewRecord AccCost H {CalcCost AccCost.(From.y).(From.x) H.x H.y}}}
	       end
	    end
	 end
	 fun {SortFun Cost}
	    fun {$ One Two}
	       OneX=One.x OneY=One.y TwoX=Two.x TwoY=Two.y
	    in
	       Cost.OneY.OneX<Cost.TwoY.TwoX
	    end
	 end
	 LastFrontier
      in
	 case Frontier of nil then error
	 [] c(x:X y:Y)|T then
	    if X==MAXX andthen Y==1 then CameFrom
	    else NeighbourL={Neighbours X Y} NewFrontier NewFrom NewCost in
	       NewFrontier#NewFrom#NewCost =
	       {Loop c(x:X y:Y) NeighbourL nil CameFrom CostMap}
	       LastFrontier = {Sort {Append T NewFrontier} {SortFun NewCost}}
	       {PathFinder LastFrontier NewFrom NewCost}
	    end
	 end
      end
      fun {SearchBest Current FromMap Px Py}
	 X = Current.x
	 Y = Current.y
      in
	 %{Browse Current}
	 if FromMap.Y.X.x==Px andthen FromMap.Y.X.y==Py then Current|nil
	 else Current|{SearchBest FromMap.Y.X FromMap Px Py}
	 end
      end
      fun {CompDir Dx Dy}
	 case Dx#Dy
	 of 0#~1 then up
	 [] 0#1 then down
	 [] ~1#0 then left
	 [] 1#0 then right
	 end
      end

      fun {Intelligence Px Py Pdir Next}
	 Dir = {CompDir Next.x-Px Next.y-Py}
      in
	 Dir
      end

      fun {MakeNewCoordinates pos(x:X y:Y dir:Dir) Move}
	 case Dir
	 of up then if Move==up then pos(x:X y:Y-1 dir:Move)
		    else pos(x:X y:Y dir:Move) end
	 [] down then if Move==down then pos(x:X y:Y+1 dir:Move)
		      else pos(x:X y:Y dir:Move) end
	 [] right then if Move==right then pos(x:X+1 y:Y dir:Move)
		       else pos(x:X y:Y dir:Move) end
	 [] left then if Move==left then pos(x:X-1 y:Y dir:Move)
		      else pos(x:X y:Y dir:Move) end
	 end
      end
      fun {MakePath X Y}
	 {Reverse {SearchBest c(x:MAXX y:1)
		   {PathFinder c(x:X y:Y)|nil
		    {InitRecord map X Y} {InitRecord cost X Y}} X Y}}
      end
      Init = map
      ArtificialPlayerPort = {NewPortObjectMinor
			      proc{$ Msg}
				 case Msg
				 of go(pos:Pos dir:Dir) then
				    Path
				    Next
				    MoveDir
				 in
				    if Pos.x==MAXX andthen Pos.y==1 then skip
				    else
				       Path = {MakePath Pos.x Pos.y}
				       Next = Path.1
				       MoveDir = {Intelligence Pos.x Pos.y Dir Next}
				       if Dir == MoveDir then
					  {Send KeysPort MoveDir}
				       else
					  {Send KeysPort MoveDir}
					  {Send KeysPort MoveDir}
				       end
				    end
				 [] goFight(play:_ npc:_) then
				    {Send KeysPort fight}
				 [] change then
                thread {Delay 1000} {Send KeysPort z} end
				 [] restart then
				    {Send ArtificialPlayerPort go(pos:pos(x:MAXX y:MAXY) dir:up)}
				 end
			      end}
   in
      thread {Delay 500} {Send ArtificialPlayerPort restart} end
      ArtificialPlayerPort
   end

   fun{GetEnemyAi CtrlId Lmoves}
      fun{SendMove Msg} B in
	 case Msg
	 of move(Dir) then
            %{Show sent#move#Lmoves}
	    {Send CtrlId move(Dir $)}
	 [] turn(Dir) then
	    thread {Delay {DELAY.get}} {Send CtrlId turn(Dir $)} end
	 end
      end
      Start
      if Lmoves == nil then Start = blocked
      else Start = free end
      AIid = {NewPortObject state(Lmoves Start)
	      fun{$ Msg state(Lact State)}
		 case Msg
		 of go then
		    if State == free then
		       case Lact
		       of nil then
			  if {SendMove Lmoves.1} then
			     state(Lmoves.2 State)
			  else
			     state(Lmoves blocked)
			  end
		       [] H|T then
			  if {SendMove Lact.1} then
			     state(Lact.2 State)
			  else
			     state(Lact blocked)
			  end
		       end
		    else
		       state(Lact State)
		    end
		 [] block then
		    state(Lact blocked)
		 [] rmBlock then
		    if State==blocked then
		       {Send AIid go}
		    end
		    state(Lact free)
		 end
	      end}
   in
      %Send first move signal, move to controller?
      if Lmoves\=nil then
	 {Send AIid go}
      end
      AIid
   end
end
