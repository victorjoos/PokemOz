fun {ArtificialPlayer Coords MapPort PlayerPort}
   TRAINERADD=2
   RECURSIONLIMIT=4
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
	    [trainer(x:X y:Y-1 dir:Dir) trainer(x:X y:Y dir:down) trainer(x:X y:Y dir:left) trainer(x:X y:Y dir:right)]
	 else
	    [trainer(x:X y:Y dir:Dir) trainer(x:X y:Y dir:down) trainer(x:X y:Y dir:left) trainer(x:X y:Y dir:right)]
	 end
      [] down then
	 if {CheckEdges X Y+1} then
	    [trainer(x:X y:Y+1 dir:Dir) trainer(x:X y:Y dir:up) trainer(x:X y:Y dir:left) trainer(x:X y:Y dir:right)]
	 else
	    [trainer(x:X y:Y dir:Dir) trainer(x:X y:Y dir:up) trainer(x:X y:Y dir:left) trainer(x:X y:Y dir:right)]
	 end
      [] right then
	 if {CheckEdges X+1 Y} then
	    [trainer(x:X+1 y:Y dir:Dir) trainer(x:X y:Y dir:down) trainer(x:X y:Y dir:left) trainer(x:X y:Y dir:up)]
	 else
	    [trainer(x:X y:Y dir:Dir) trainer(x:X y:Y dir:down) trainer(x:X y:Y dir:left) trainer(x:X y:Y dir:up)]
	 end
      [] left then
	 if {CheckEdges X-1 Y} then
	    [trainer(x:X-1 y:Y dir:Dir) trainer(x:X y:Y dir:down) trainer(x:X y:Y dir:up) trainer(x:X y:Y dir:right)]
	 else
	    [trainer(x:X y:Y dir:Dir) trainer(x:X y:Y dir:down) trainer(x:X y:Y dir:up) trainer(x:X y:Y dir:right)]
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
   % Creates a move tree for a MINIMAX approach, and using
   % the following heuristics :
   % - It's better to stay on the road
   % - Avoid trainer interactions
   % - Get closer to our goal (the end tile)
   fun {MoveTree Px Py Pdir TrainerPositions RecursionDepth}
      Ground = {Send MapPort send(x:Px y:Py getGround($))}
      NewTrainerPos = {MakeNewTrainerList TrainerPositions nil}
      BaseScore
      FinalScore
      Up Down Right Left
   in
      if Ground==grass then BaseScore=10+(Px-MAXX)+(1-Py) else BaseScore=(Px-MAXX)+(1-Py) end
      FinalScore={CalculateScore Px Py TrainerPositions BaseScore}
      if RecursionDepth>RECURSIONLIMIT then move(leaf value:FinalScore)
      else
	 case Pdir
	 of up then
	    if {CheckEdges Px Py-1} then
	       Up={MoveTree Px Py-1 up NewTrainerPos RecursionDepth+1}
	    else
	       Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    end
	    Down={MoveTree Px Py down NewTrainerPos RecursionDepth+1}
	    Right={MoveTree Px Py right NewTrainerPos RecursionDepth+1}
	    Left={MoveTree Px Py left NewTrainerPos RecursionDepth+1}
	 [] down then
	    Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    if {CheckEdges Px Py+1} then
	       Down={MoveTree Px Py+1 down NewTrainerPos RecursionDepth+1}
	    else
	       Down={MoveTree Px Py down NewTrainerPos RecursionDepth+1}
	    end
	    Right={MoveTree Px Py right NewTrainerPos RecursionDepth+1}
	    Left={MoveTree Px Py left NewTrainerPos RecursionDepth+1}
	 [] right then
	    Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    Down={MoveTree Px Py down NewTrainerPos RecursionDepth+1}
	    if {CheckEdges Px Py+1} then
	       Right={MoveTree Px Py+1 right NewTrainerPos RecursionDepth+1}
	    else
	       Right={MoveTree Px Py right NewTrainerPos RecursionDepth+1}
	    end
	    Left={MoveTree Px Py left NewTrainerPos RecursionDepth+1}
	 [] left then
	    Up={MoveTree Px Py up NewTrainerPos RecursionDepth+1}
	    Down={MoveTree Px Py down NewTrainerPos RecursionDepth+1}
	    Right={MoveTree Px Py right NewTrainerPos RecursionDepth+1}
	    if {CheckEdges Px Py-1} then
	       Left={MoveTree Px Py-1 left NewTrainerPos RecursionDepth+1}
	    else
	       Left={MoveTree Px Py left NewTrainerPos RecursionDepth+1}
	    end
	 end
	 move(value:FinalScore up:Up down:Down right:Right left:Left)
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
   % Uses the move tree to determine the best move.
   fun {Intelligence Px Py Pdir}
      TrainerList = {GetTrainerList 1 1} % Get all the trainers in a *flat* list
      Tree = {MoveTree Px Py Pdir TrainerList 0}
      Up Down Right Left
   in
      Up = {Sum {Flatten {ListMoveTree Tree.up}} 0}
      Down = {Sum {Flatten {ListMoveTree Tree.down}} 0}
      Right = {Sum {Flatten {ListMoveTree Tree.left}} 0}
      Left = {Sum {Flatten {ListMoveTree Tree.right}} 0}
      {Show Up#Down#Right#Left}
      if Up < Down andthen Up < Right andthen Up < Left then up
      elseif Down < Up andthen Down < Right andthen Down < Left then down
      elseif Right < Down andthen Right < Up andthen Right < Left then right
      else left end
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
			      in
				 {Send PlayerPort move(Move)}
				 state(pos(x:Pos.x y:Pos.y) dir:Dir)
			      [] fight(PlayerH TrainerH PlayerLvl TrainerLvl) then
				 if PlayerLvl>TrainerLvl andthen PlayerH>5 then fight
				 elseif PlayerLvl==TrainerLvl andthen PlayerH>10 then fight
				 elseif PlayerLvl<TrainerLvl andthen PlayerH+10>TrainerH then fight
				 else run
				 end
			      end
			   end}
in
   {Show 'Hello!!'}
   ArtificialPlayerPort
end



%%%%%%%%%%% PART TO ADD!!! %%%%%%%%%

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
%%%%%%%%%%%% END PART TO ADD!!!! %%%%%%%%%
