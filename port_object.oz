% This file will contain all the portObjects' descriptions and code
declare
%%%%% CONSTANTS %%%%%%%%%
SPEED = 5
DELAY = 100
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


%%%%%%% FIGHT PORTOBJECTS %%%%%%%%%%%
fun {FightController TrainerP EnemyP FightAnim}%re-add waiter
   fun {CheckDamage TType EType}
      if TType == EType then 2#2
      else
	 case TType
	 of fire then if EType==grass then 1#3 else 3#1 end
	 [] grass then if EType==fire then 3#1 else 1#3 end
	 [] water then if EType==fire then 1#3 else 3#1 end
	 end
      end
   end
   fun {AttackSuccessful Attacker}
      case Attacker
      of player then
	 Probability = (6+TrainerP.lvl-EnemyP.lvl)*9
	 Rand = ({OS.rand} mod 100)+1 % from 1 to 100
      in
	 if Rand =< Probability then true
	 else false
	 end
      [] npc then
	 Probability = (6+EnemyP.lvl-TrainerP.lvl)*9
	 Rand = ({OS.rand} mod 100)+1 % from 1 to 100
      in
	 if Rand =< Probability then true
	 else false
	 end
      end
   end
   fun {RunSuccessful}
      true % TODO(victor) : add probability
   end
   fun {Attack Health}
      if {AttackSuccessful npc} then
	 Ack
      in
	 {Send FightAnim attack(pnj Ack)}
	 {Send WaitAnimation wait(FightPort Ack endmove)}
	 {Max Health-TrainerHitted 0}
      else Health % TODO : add animation/text description failed attack
      end
   end
   TrainerHitted#EnemyHitted = {CheckDamage TrainerP.type EnemyP.type}
   WaitAnimation = {Waiter}
   FightPort = {NewPortObject
		state(trainerH:TrainerP.health.1 enemyH:EnemyP.health.1 fighting:false)
		fun {$ Msg State}
		   case Msg
		   of run then
		      if State.fighting then state(State)
		      else
			 NewTrH Fighting in
			 if {RunSuccessful} then
			    {Send FightAnim exit}
			    % {Send Trainer endFight}
			    NewTrH = State.trainerH 
			 else NewTrH = {Attack State.trainerH}
			    if NewTrH == State.trainerH then Fighting=false
			    else Fighting=true end
			 end
			 state(trainerH:NewTrH enemyH:State.enemyH fighting:Fighting)
		      end
		   [] fight then
		      if State.fighting then State(state)
		      else
			 NewTrH NewNPCH Fighting
		      in
			 if (State.trainerH == 0) then skip % {Send Trainer endfight}
			 elseif (State.enemyH == 0) then skip % {Send Trainer endfight}
			 else
			    if {AttackSuccessful player} then
			       Ack 
			    in
			       {Show attackChar}
			       {Send FightAnim attack(player Ack)}
			       {Wait Ack}
			    % {Send WaitAnimation wait(FightPort Ack endmove)}
			       NewNPCH = {Max State.enemyH-EnemyHitted 0}
			       NewTrH = {Attack State.trainerH}
			    else
			       NewNPCH = State.enemyH
			       NewTrH = {Attack State.trainerH}
			    end
			 end
			 if NewTrH == State.trainerH then Fighting=false
			 else Fighting=true end
			 state(trainerH:NewTrH enemyH:NewNPCH fighting:Fighting)
		      end
		   [] endmove then
		      state(trainerH:State.trainerH enemyH:State.enemyH fighting:false)
		   end
		end}
in
   FightPort
end

\insert 'animate_port.oz'

%%%%%%% THE EXTERN FUNCTIONS %%%%%%
EXPER = exp(5:5 6:12 7:20 8:30 9:50 10:~0)
fun{GETTYPE Name}
   case Name
   of "Bulbasoz"   then grass
   [] "Charmandoz" then fire
   [] "Oztirtle"   then water
   end
end
proc{GetLevel Exp Lvl Ne Le}
   if Lvl < 10 andthen Exp >= EXPER.Lvl then
      {GetLevel Exp-EXPER.Lvl Lvl+1 Ne Le}
   else
      Ne = Exp Le = Lvl
   end
end
Function that creates a Pokemoz
fun{CreatePokemoz Name Lvl State}%State = {wild,trainer,player}
   Type = {GETTYPE Name}
   HealthMax = 20+(Lvl-5)*2
   ExpMax = EXPER.(Lvl+1)
   %Send Kill signal when the wild pokemoz vanishes, trainer is defeated or pokemoz is released back into the wild
   Pokid = {NewPortObjectKilleable state(health:h(act:HealthMax max:HealthMax) exp:e(act:0 max:ExpMax) lvl:Lvl)
	    fun{$ Msg state(health:He exp:Exp lvl:Lvl)}
	       case Msg
	       of getHealth(X) then
		  X=He
		  state(health:He exp:Exp lvl:Lvl)
	       [] getExp(X) then
		  X=Exp
		  state(health:He exp:Exp lvl:Lvl)
	       [] getLvl(X) then
		  X=Lvl
		  state(health:He exp:Exp lvl:Lvl)
	       [] addExp(AddExp) then %will replenish Health automatically in
                                      %case of evolution
		  NewExp = AddExp+Exp.act
	       in
		  if NewExp >= Exp.max then
		     if Lvl < 10 then NExp NLvl in
			{GetLevel NewExp Lvl NExp NLvl}
		     else
			state(health:He exp:Exp lvl:Lvl)
		     end
		  else
		     state(health:h(act:He.max max:He.max) exp:e(act:RemExp max: ) lvl:Lvl+N)
		  end
	       end
	    end}%add replenishing function for hospital later on
end
% Function that creates a trainer
%@post: returns the id of the PlayerController
fun{CreateTrainer Name X0 Y0 Speed Mapid Canvash}
   Anid = {AnimateTrainer Canvash X0-1 Y0-1 Speed Name}
   Trid = {Trainer pos(x:X0 y:Y0) Anid}
in
   {TrainerController Mapid Trid Speed}
   %Todo trainer(poke:<PokemOz> pid:<TrainerController>) + add speed to state of trainer?
end

% Function that creates a fight
fun{CreateFight Player NPC CanvasH}
   Ack
   Animation = {DrawFight CanvasH Player NPC Ack}
   Fight = {FightController Player NPC Animation}
  % _={FightScene CanvasH Player NPC}
in
   {BFIGHTH bind(event:"<1>" action:
				proc{$}
				   {Show gotfight}
				   {Send Fight fight}
				end)}
   {BRUNH bind(event:"<1>" action:
			      proc{$}
				 {Show gotrun}
				 {Send Fight run}
			      end)}
   Fight
end
