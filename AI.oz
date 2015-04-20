fun{Player Coords MapPort}
   TRAINERADD=2
   RECURSIONLIMIT=3
   fun{CheckEdges X Y}
      if X>0 andthen X=<MAXX andthen
	 Y>0 andthen Y=<MAXY then
	 true
      else
	 false
      end
   end
   fun {GetTrainerList X Y}
      TileState = {Send MapPort send(x:X y:Y get($))}
      NewX NewY
   in
      if X==MAXX andthen Y==MAXY then nil
      elseif X==MAXX then NewX=1 NewY=Y+1
      else NewX=X+1 NewY=Y end
      case TileState
      of occupied(TrainerID) then trainer(x:X y:Y dir:{Send Y.pid getDir($)})|{GetMapList NewX NewY}
      else {GetMapList NewX NewY}
      end
   end
   fun {NewTrainerPositions pos(x:X y:Y dir:Dir)}
      case Dir
      of up then
	 if {CheckEdges X Y-1} then
	    [pos(x:X y:Y-1 dir:Dir) pos(x:X y:Y dir:down) pos(x:X y:Y dir:left) pos(x:X y:Y dir:right)]
	 else
	    [pos(x:X y:Y dir:Dir) pos(x:X y:Y dir:down) pos(x:X y:Y dir:left) pos(x:X y:Y dir:right)]
	 end
      [] down then
	 if {CheckEdges X Y+1} then
	    [pos(x:X y:Y+1 dir:Dir) pos(x:X y:Y dir:up) pos(x:X y:Y dir:left) pos(x:X y:Y dir:right)]
	 else
	    [pos(x:X y:Y dir:Dir) pos(x:X y:Y dir:up) pos(x:X y:Y dir:left) pos(x:X y:Y dir:right)]
	 end
      [] right then
	 if {CheckEdges X+1 Y} then
	    [pos(x:X+1 y:Y dir:Dir) pos(x:X y:Y dir:down) pos(x:X y:Y dir:left) pos(x:X y:Y dir:up)]
	 then
	    [pos(x:X y:Y dir:Dir) pos(x:X y:Y dir:down) pos(x:X y:Y dir:left) pos(x:X y:Y dir:up)]
	 end
      [] left then
	 if {CheckEdges X-1 Y} then
	    [pos(x:X-1 y:Y dir:Dir) pos(x:X y:Y dir:down) pos(x:X y:Y dir:up) pos(x:X y:Y dir:right)]
	 else
	    [pos(x:X y:Y dir:Dir) pos(x:X y:Y dir:down) pos(x:X y:Y dir:up) pos(x:X y:Y dir:right)]
	 end
      end
   end
   fun {CalculateScore X Y TrainerPositions Score}
      NextScore
   in
      case TrainerPositions of nil then Score
      [] pos(x:Tx y:Ty dir:Tdir)|T then
	 case Dir
	 of up then if Y==Ty-1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 of down then if Y==Ty+1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 of right then if X==Tx+1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 of left then if X==Tx-1 then NextScore=Score+TRAINERADD else NextScore=Score end
	 end
	 {CalculateScore X Y T NextScore}
      end
   end
   fun {MakeNewTrainerList OldTrainerPos NewPos}
      case OldTrainerPos of nil then {Flatten NewPos}
      [] H|T then {NewTrainerPositions H}|{MakeNewTrainerList T}
      end
   end
   fun {MoveTree Px Py Pdir TrainerPositions RecursionDepth}
      Ground = {Send MapPort send(x:Px y:Py getGround($))}
      NewTrainerPos = {MakeNewTrainerList TrainerPositions}
      BaseScore
      FinalScore
      Up Down Right Left
   in
      if Ground==grass then BaseScore=5+(Px-MAXX)+(1-Py) else BaseScore=(Px-MAXX)+(1-Py) end
      FinalScore={CalculateScore Px Py TrainerPos BaseScore}
      if RecursionDepth>RECURSIONLIMIT then move(leaf value:FinalScore)
      else
	 case Pdir
	 of up then
	    if {CheckDir Px Py-1} then
	       Up={MoveTree Px Py-1 up NewTrainerPos RecursionDepth+1}
	    else
	       Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    end
	    Down={MoveTree Px Py down NewTrainerPos RecursionDepth+1}
	    Right={MoveTree Px Py right NewTrainerPos RecursionDepth+1}
	    Left={MoveTree Px Py left NewTrainerPos RecursionDepth+1}
	 [] down then
	    Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    Down={MoveTree Px Py+1 down NewTrainerPos RecursionDepth+1}
	    Right={MoveTree Px Py right NewTrainerPos RecursionDepth+1}
	    Left={MoveTree Px Py left NewTrainerPos RecursionDepth+1}
	 [] right then
	    Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    Down={MoveTree Px Py down NewTrainerPos RecursionDepth+1}
	    Right={MoveTree Px Py+1 right NewTrainerPos RecursionDepth+1}
	    Left={MoveTree Px Py left NewTrainerPos RecursionDepth+1}
	 [] left then
	    Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    Down={MoveTree Px Py down NewTrainerPos RecursionDepth+1}
	    Right={MoveTree Px Py right NewTrainerPos RecursionDepth+1}
	    Left={MoveTree Px Py-1 left NewTrainerPos RecursionDepth+1}
	 end
	 move(value:FinalScore up:Up down:Down right:Right left:Left)
      end
   end
   fun {AI Px Py Pdir}
      TrainerList = {GetTrainerList 1 1} % Get all the trainers in a *flat* list
      Tree = {MoveTree Px Py Pdir TrainerList}
   in
   end
   
   Init = state(C dir:up)
   PlayerPort = {NewPortObject Init
		 fun{$ Msg state(Pos dir:Dir)}
		    case Msg
		    of getMove(X) then
		       X=Dir
		       state(Pos dir:Dir)
		    [] getPos(X) then
		       X=Pos
		       state(Pos dir:Dir)
		    [] move(Move) then
		       
		       state(pos(x:X y:Y) dir:Dir)
		    [] turn(NewDir) then
		       {Send Anid turn(NewDir)}
		       state(Pos dir:NewDir)
		    end	      
		 end}
in
   PlayerPort
end
