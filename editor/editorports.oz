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
	       [] switchTrainer then
		  case TrainerDir of empty then state(Ground up)
		  [] up then state(Ground right)
		  [] right then state(Ground down)
		  [] down then state(Ground left)
		  [] left then state(Ground empty)
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
   MapId = {NewPortObject empty
	    fun{$ Msg State}
	       case Msg
	       of save(FileName) then Map={MakeTuple map MAXY} in
		  for J in 1..MAXY do
		     Map.J = {MakeTuple r MAXX}
		     for I in 1..MAXX do Ground={Send TilesID.J.I getGround($)} in
			if Ground==grass
			then Map.J.I = 1 else Map.J.I = 0 end
		     end
		  end
		  {Pickle.save Map FileName}
		  empty
	       [] load(FileName) then Map={Pickle.load FileName} in
		  for J in 1..MAXY do
		     for I in 1..MAXX do
			if Map.J.I==1 then {Send TilesID.J.I setGround(grass)}
			else {Send TilesID.J.I setGround(road)}
			end
		     end
		  end
		  empty
	       end
	    end
	   }
in
   MapId#TilesID
end
