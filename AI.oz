fun {ArtificialPlayer Coords MapPort PlayerPort}
   TRAINERADD=1
   GRASSPENALTY=100
   DIRBONUS=10
   RECURSIONLIMIT=1
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
      TileState = {Send MapPort send(x:X y:Y get($))}
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
   % Takes the current position of a trainer and moves it
   % or turns it along all directions (no staying in place)
   fun {NewTrainerPositions trainer(x:X y:Y dir:Dir)}
      case Dir
      of up then
	 if {CheckEdges X Y-1} then
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X y:Y-1 dir:Dir)
	     trainer(x:X y:Y dir:down)
	     trainer(x:X y:Y dir:left)
	     trainer(x:X y:Y dir:right)]
	 else
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X y:Y dir:down)
	     trainer(x:X y:Y dir:left)
	     trainer(x:X y:Y dir:right)]
	 end
      [] down then
	 if {CheckEdges X Y+1} then
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X y:Y+1 dir:Dir)
	     trainer(x:X y:Y dir:up)
	     trainer(x:X y:Y dir:left)
	     trainer(x:X y:Y dir:right)]
	 else
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X y:Y dir:up)
	     trainer(x:X y:Y dir:left)
	     trainer(x:X y:Y dir:right)]
	 end
      [] right then
	 if {CheckEdges X+1 Y} then
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X+1 y:Y dir:Dir)
	     trainer(x:X y:Y dir:down)
	     trainer(x:X y:Y dir:left)
	     trainer(x:X y:Y dir:up)]
	 else
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X y:Y dir:down)
	     trainer(x:X y:Y dir:left)
	     trainer(x:X y:Y dir:up)]
	 end
      [] left then
	 if {CheckEdges X-1 Y} then
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X-1 y:Y dir:Dir)
	     trainer(x:X y:Y dir:down)
	     trainer(x:X y:Y dir:up)
	     trainer(x:X y:Y dir:right)]
	 else
	    [trainer(x:X y:Y dir:Dir)
	     trainer(x:X y:Y dir:down)
	     trainer(x:X y:Y dir:up)
	     trainer(x:X y:Y dir:right)]
	 end
      end
   end
   % Determines the score of a position (higher is worse) :
   % - For each trainer facing the player : (+2)
   % - For each GRASS Tile : (+5) (In function MoveTree)
   fun {CalculateScore X Y TrainerPositions Score}
      NextScore
   in
      case TrainerPositions of nil then Score
      [] trainer(x:Tx y:Ty dir:Tdir)|T then
	 case Tdir
	 of up then if Y==Ty-1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 [] down then if Y==Ty+1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 [] right then if X==Tx+1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 [] left then if X==Tx-1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 end
	 {CalculateScore X Y T NextScore}
      end
   end
   % Takes each possible current trainer position
   % and updates it using {NewTrainerPositions} to calculate
   % ALL the possible positions of each trainer.
   fun {MakeNewTrainerList OldTrainerPos NewPos}
      case OldTrainerPos of nil then {Flatten NewPos}
      [] H|T then {MakeNewTrainerList T {NewTrainerPositions H}|NewPos}
      end
   end
   % Creates a move tree for a *MINIMAX* approach, and using
   % the following heuristics :
   % - It's better to stay on the road
   % - Avoid trainer interactions
   % - Get closer to our goal (the end tile)
   %fun {AvoidGrass Px Py Pdir TrainerPositions Dir#Number}
   %    Ground = {Send MapPort send(x:Px y:Py getGround($))}
   % in
   %    if Ground == grass then move(leaf)
   %    else
   % 	 if Px==MAXX andthen Py==1 then move(destination)
   % 	 else
   % 	    case Pdir
   % 	    of up then move(
   % 			  up:{AvoidGrass Px Py-1 Pdir TrainerPositions}
   % 			  down:{AvoidGrass Px Py down TrainerPositions}
   % 			  left:{AvoidGrass Px Py left TrainerPositions}
   % 			  right:{AvoidGrass Px Py right TrainerPositions})
   % 	    [] down then move(
   % 			    up:{AvoidGrass Px Py up TrainerPositions}
   % 			    down:{AvoidGrass Px Py+1 down TrainerPositions}
   % 			    left:{AvoidGrass Px Py left TrainerPositions}
   % 			    right:{AvoidGrass Px Py right TrainerPositions})
   % 	    [] left then move(
   % 			    up:{AvoidGrass Px Py up TrainerPositions}
   % 			    down:{AvoidGrass Px Py down TrainerPositions}
   % 			    left:{AvoidGrass Px-1 Py left TrainerPositions}
   % 			    right:{AvoidGrass Px Py right TrainerPositions})
   % 	    [] right then move(
   % 			     up:{AvoidGrass Px Py up TrainerPositions}
   % 			     down:{AvoidGrass Px Py down TrainerPositions}
   % 			     left:{AvoidGrass Px Py left TrainerPositions}
   % 			     right:{AvoidGrass Px+1 Py right TrainerPositions})
   % 	    end
   % 	 end
   %    end
   % end

   % TODO(victor) : check this code !!!!!!!!!!!!!!!!! Fuck up here !!!!!!
   fun {MinD Up Down Left Right}
      Nup Ndown Nleft Nright
      MaxVal = {Max Up {Max Down {Max Left Right}}}+1
   in
      if Up<0 andthen Down<0 andthen Right<0 andthen Left<0 then ~1
      else 
	 if Up < 0 then Nup = MaxVal else Nup = Up end
	 if Down < 0 then Ndown = MaxVal else Ndown = Down end
	 if Left < 0 then Nleft = MaxVal else Nleft = Left end
	 if Right < 0 then Nright = MaxVal else Nright = Right end
	 {Min Nup {Min Ndown {Min Nleft Nright}}}
      end
   end
		  
   fun {MoveTree Px Py Pdir TrainerPositions RecursionDepth ScoreSum}
      Ground
      if {CheckEdges Px Py} then 
	 Ground = {Send MapPort send(x:Px y:Py getGround($))}
      else
	 Ground = road
      end
      NewTrainerPos = {MakeNewTrainerList TrainerPositions nil}
      BaseScore
      FinalScore
      Up Down Right Left
   in
      if Px==MAXX andthen Py==1 then BaseScore=2000
      elseif Ground==grass then BaseScore=GRASSPENALTY+(Px-1)+(MAXY-Py)
      else BaseScore={Abs MAXX-Px}+{Abs 1-Py} end
      % {Browse Pdir#BaseScore}
      FinalScore={CalculateScore Px Py TrainerPositions BaseScore}
      if RecursionDepth>RECURSIONLIMIT then ScoreSum+FinalScore
      else
	 case Pdir
	 of up then
	    if {CheckEdges Px Py-1} then
	       {MinD {MoveTree Px Py-1 up NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py down NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py right NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py left NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}}
	    else
	       ~1
	    end
	 [] down then
	    if {CheckEdges Px Py+1} then
	       {MinD {MoveTree Px Py up NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py+1 down NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py right NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py left NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}}
	    else
	       ~1
	    end
	 [] right then
	    if {CheckEdges Px+1 Py} then
	       {MinD {MoveTree Px Py up NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py down NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px+1 Py right NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py left NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}}
	    else
	       ~1
	    end
	 [] left then
	    if {CheckEdges Px-1 Py} then
	       {MinD {MoveTree Px Py up NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py down NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px Py right NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}
		{MoveTree Px+1 Py left NewTrainerPos RecursionDepth+1 ScoreSum+FinalScore}}
	    else
	       ~1
	    end
	 end
      end
   end
   fun {ListMoveTree Tree}
      case Tree of move(leaf value:Value) then Value|nil
      [] move(value:Value up:Up down:Down left:Left right:Right) then
	 Value|{ListMoveTree Up}|{ListMoveTree Down}|{ListMoveTree Right}|{ListMoveTree Left}
      end
   end
   fun {Sum MoveL TotalSum}
      case MoveL of nil then TotalSum
      [] H|T then {Sum T TotalSum+H}
      end
   end
   fun {CheckDir Dir MoveDir}
      if Dir==MoveDir then 1
      else 0 end
   end
   fun {MinDir dir(X DirX) dir(Y DirY)}
      if X<0 then dir(Y DirY)
      else
	 if (X =< Y) then dir(X DirX) else dir(Y DirY) end
      end
   end
   % Uses the move tree to determine the best move.
   % fun {Intelligence Px Py Pdir}
   %    TrainerList = {GetTrainerList 1 1} % Get all the trainers in a *flat* list
   %    Tree = {MoveTree Px Py Pdir TrainerList 0}
   %    Up Down Right Left
   %    Bdir
   % in
   %    {Browse Tree}
   %    Up = {Sum {Flatten {ListMoveTree Tree.up}} 0}-{CheckDir Pdir up}*DIRBONUS
   %    Down = {Sum {Flatten {ListMoveTree Tree.down}} 0}-{CheckDir Pdir down}*DIRBONUS
   %    Right = {Sum {Flatten {ListMoveTree Tree.right}} 0}-{CheckDir Pdir right}*DIRBONUS
   %    Left = {Sum {Flatten {ListMoveTree Tree.left}} 0}-{CheckDir Pdir left}*DIRBONUS
   %    {Show Up#Down#Right#Left}
   %    dir(_ Bdir) = {MinDir dir(Up up) {MinDir dir(Down down) {MinDir dir(Right right) dir(Left left)}}}
   %    Bdir
   % end
   fun {Intelligence Px Py Pdir}
      TrainerList = {GetTrainerList 1 1} % Get all the trainers in a *flat* list
      Up Down Right Left
      Bdir
   in
      case Pdir
      of up then
	 if {CheckEdges Px Py-1} then 
	   thread Up={MoveTree Px Py-1 up TrainerList 0 0} end
	 else Up=~1 end
	 thread Down={MoveTree Px Py down TrainerList 0 0} end
	 thread Right={MoveTree Px Py right TrainerList 0 0} end
	 thread Left={MoveTree Px Py left TrainerList 0 0} end
      [] down then
	 thread Up={MoveTree Px Py up TrainerList 0 0} end
	 if {CheckEdges Px Py+1} then
	    thread Down={MoveTree Px Py+1 down TrainerList 0 0} end
	 else Down=~1 end
	 thread Right={MoveTree Px Py right TrainerList 0 0} end
	 thread Left={MoveTree Px Py left TrainerList 0 0} end
      [] right then
	 thread Up={MoveTree Px Py up TrainerList 0 0} end
	 thread Down={MoveTree Px Py down TrainerList 0 0} end
	 if {CheckEdges Px+1 Py} then
	    thread Right={MoveTree Px+1 Py right TrainerList 0 0} end
	 else Right=~1 end
	 thread Left={MoveTree Px Py left TrainerList 0 0} end
      [] left then
	 thread Up={MoveTree Px Py up TrainerList 0 0} end
	 thread Down={MoveTree Px Py down TrainerList 0 0} end
	 thread Right={MoveTree Px Py right TrainerList 0 0} end
	 if {CheckEdges Px-1 Py} then
	    thread Left={MoveTree Px-1 Py left TrainerList 0 0} end
	 else Left=~1 end
      end
      
      {Show Up+Down+Left+Right#Up#Down#Left#Right}
      dir(_ Bdir) = {MinDir dir(Up up) {MinDir dir(Down down) {MinDir dir(Right right) dir(Left left)}}}
      Bdir
   end
   fun {MakeNewCoordinates pos(x:X y:Y dir:Dir) Move}
      case Dir
      of up then if Move==up then pos(x:X y:Y-1 dir:Move) else pos(x:X y:Y dir:Move) end
      [] down then if Move==down then pos(x:X y:Y+1 dir:Move) else pos(x:X y:Y dir:Move) end
      [] right then if Move==right then pos(x:X+1 y:Y dir:Move) else pos(x:X y:Y dir:Move) end
      [] left then if Move==left then pos(x:X-1 y:Y dir:Move) else pos(x:X y:Y dir:Move) end
      end	    
   end
   Init = state(Coords dir:up)
   ArtificialPlayerPort = {NewPortObject Init
			   fun{$ Msg state(Pos dir:Dir)}
			      {Show aiMsg#Msg}
			      case Msg
			      of getMove(X) then
				 X=Dir
				 state(Pos dir:Dir)
			      [] getPos(X) then
				 X=Pos
				 state(Pos dir:Dir)
			      [] move then
				 Move = {Intelligence Pos.x Pos.y Dir}
				 NewCoord
			      in
				 {Show move#Move}
				 {Send PlayerPort move(Move)}
				 NewCoord = {MakeNewCoordinates pos(x:Pos.x y:Pos.y dir:Dir) Move}
				 state(pos(x:NewCoord.x y:NewCoord.y) dir:NewCoord.dir)
			      [] fight(PlayerH TrainerH PlayerLvl TrainerLvl) then
				 if PlayerLvl>TrainerLvl andthen PlayerH>5 then fight
				 elseif PlayerLvl==TrainerLvl andthen PlayerH>10 then fight
				 elseif PlayerLvl<TrainerLvl andthen PlayerH+10>TrainerH then fight
				 else run
				 end
			      end
			   end}
in
   ArtificialPlayerPort
end

fun{GetEnemyAi CtrlId Lmoves DelayTime}
   fun{SendMove Msg} B in
      case Msg
      of move(Dir) then
         {Send CtrlId move(Dir $)}
      [] turn(Dir) then
         thread {Delay 5000} {Send CtrlId turn(Dir $)} end
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
                              state(Lmoves State)
                           end
                        [] H|T then
                           if {SendMove Lact.1} then
                              state(Lact.2 State)
                           else
                              state(Lact State)
                           end
			end
                     else
                        state(Lact State)
                     end
                  [] rmBlock then
                     state(Lact free)
                  end
               end}
in
   %Send first move signal, move to controller?
   {Browse Lmoves#l}
   if Lmoves\=nil then
      thread
         %{Delay DelayTime}
         {Browse sending}
         {Send AIid go}
         {Browse sent}
      end
   end
   AIid
end