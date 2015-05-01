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

fun{Tile Init C}
   Tilid = {NewPortObject Init
	    fun{$ Msg state(Ground TrainerDir)}
	       case Msg
	       of getGround(X) then
		  X=Ground
		  state(Ground TrainerDir)
	       [] getDir(X) then
		  X=TrainerDir
		  state(Ground TrainerDir)
	       [] switch then X=C.x Y=C.y in
		  if Ground==grass then
		     {RedrawSquare RECTHANDLES.Y.X road}
		     state(road TrainerDir)
		  else
		     {RedrawSquare RECTHANDLES.Y.X grass}
		     state(grass TrainerDir)
		  end
	       [] setGround(NewGround) then X=C.x Y=C.y in
		  {RedrawSquare RECTHANDLES.Y.X NewGround}
		  state(NewGround TrainerDir)
	       [] addTrainer(Dir) then
		  state(Ground Dir)
	       [] switchTrainer then X=C.x Y=C.y in
		  case TrainerDir
		  of empty then {DrawTrainer TRAINERHANDLES.Y.X up} state(Ground up)
		  [] up then {DrawTrainer TRAINERHANDLES.Y.X right} state(Ground right)
		  [] right then {DrawTrainer TRAINERHANDLES.Y.X down} state(Ground down)
		  [] down then {DrawTrainer TRAINERHANDLES.Y.X left} state(Ground left)
		  [] left then {DrawTrainer TRAINERHANDLES.Y.X empty} state(Ground empty)
		  end
	       end
	    end}
in
   Tilid
end

fun {MapEditor}
   fun{CreateTiles}
      MapRec
   in
   %better to thread drawmap function
      MapRec = {MakeTuple 'mapids' MAXY}
      for J in 1..MAXY do
	 MapRec.J = {MakeTuple 'mapids' MAXX}
	 for I in 1..MAXX do
	    MapRec.J.I = {Tile state(road empty) coord(x:I y:J)}
	 end
      end
      MapRec
   end
   TilesID={CreateTiles}
   MapId = {NewPortObject ground
	    fun{$ Msg State}
	       case Msg
	       of state(X) then X=State State
	       [] save(FileName) then Map={MakeTuple map MAXY} in
		  for J in 1..MAXY do
		     Map.J = {MakeTuple r MAXX}
		     for I in 1..MAXX do Ground={Send TilesID.J.I getGround($)} in
			if Ground==grass
			then Map.J.I = 1 else Map.J.I = 0 end
		     end
		  end
		  {Pickle.save Map FileName}
		  State
	       [] load(FileName) then Map={Pickle.load FileName} in
		  for J in 1..MAXY do
		     for I in 1..MAXX do
			if Map.J.I==1 then {Send TilesID.J.I setGround(grass)}
			else {Send TilesID.J.I setGround(road)}
			end
		     end
		  end
		  State
	       [] switch then
		  if State==ground then trainer
		  else ground end
	       end
	    end
	   }
in
   MapId#TilesID
end
