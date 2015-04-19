% This file will contain all the portObjects' descriptions and code
%declare
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
%       Ground= {grass,road}
%@post: Returns the Pid of the tile
CreateFight
fun{Tile Init C Mapid Ground}
   proc{SignalArrival Trainer}
      %Signals arrival of someone to cases around
      {Send Mapid send(x:C.x   y:C.y+1 new(up Trainer))}
      {Send Mapid send(x:C.x+1 y:C.y   new(right Trainer))}
      {Send Mapid send(x:C.x-1 y:C.y   new(left Trainer))}
      {Send Mapid send(x:C.x   y:C.y-1 new(down Trainer))}
   end
   Tid   = {Timer}
   Tilid = {NewPortObject Init
	    fun{$ Msg Plop}
	       State = Plop.1 in
	       case Msg
	       of get(X) then
		  X=State
		  state(State)
	       [] comming(T Plid Val) then
		  {Send Tid starttimer(Tilid T arrived(Plid Val))}
		  state(reserved)
	       [] arrived(Plid Val) then
		  Val=unit
		  %if Ground == grass andthen {Label Plid} == player then
		     %Todo: wild pokemoz
		   %  skip
		  %end
		  {SignalArrival Plid}
		  state(occupied(Plid))
	       [] new(Dir Trainer) then
		  case State
		  of occupied(Y) then LblY = {Label Y} in
		     if LblY\={Label Trainer} andthen
			{Send Y.pid getDir($)} == Dir then
			{Show 'I want to fight!!!'}
			if LblY==player then
			   {Show here}
			   {CreateFight Y Trainer}
			else
			   {Show there}
			   {CreateFight Trainer Y}
			end
		     end
		     {Show done}
		     state(State)
		  else
		     % We don't care
		     state(State)
		  end
	       [] left then
		  state(empty)
	       [] init(X) then
		  state(occupied(X))
	       end
	    end}
in
   Tilid
end
%
%@post: Returns the pid of the controller (through which every command
%       to the tiles passes)
fun{MapController Map}
   MapRec
   Ground = ground(0:road 1:grass)
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
	       [] init(x:X y:Y Plid) then
		  {Send MapRec.Y.X init(Plid)}
	       end
	    end}
   
in
   %better to thread drawmap function
   MapRec = {MakeTuple 'mapids' MAXY}
   for J in 1..MAXY do
      MapRec.J = {MakeTuple 'mapids' MAXX}
      for I in 1..MAXX do
	 MapRec.J.I = {Tile state(empty) coord(x:I y:J) Mapid
		       Ground.(Map.J.I)}
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
fun{TrainerController Mapid Trid Speed TrainerObj}
   Wid  = {Waiter}
   Plid = {NewPortObject state(still)
	   fun{$ Msg state(State)}
	      case Msg
	      of endfight then
		 state(still)
	      [] getDir(X) then
		 {Send Trid getDir(X)}
		 state(State)
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
		       Sig  = comming(Speed*DELAY TrainerObj Val)
		    in
		       %Check for boundaries and if the tile is free
		       %then send arriving signal
		       if {Send Mapid checksig(x:NewX y:NewY $ sig:Sig)} then
 			  {Send Trid moveTo(x:NewX y:NewY)}

			  {Send Wid wait(Plid  Val arrived)}
			  {Send Wid wait(Mapid Val
					 send(x:Pos.x y:Pos.y left))}
			  state(moving)
		       else
			  state(still)
		       end
		    else
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
      TrainerLvl = {Send TrainerP.pid getLvl($)}
      EnemyLvl   = {Send   EnemyP.pid getLvl($)}
   in
      case Attacker
      of player then
	 Probability = (6+TrainerLvl-EnemyLvl)*9
	 Rand = ({OS.rand} mod 100)+1 % from 1 to 100
      in
	 if Rand =< Probability then true
	 else false
	 end
      [] npc then
	 Probability = (6+EnemyLvl-TrainerLvl)*9
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
   % fun {Attack Health}
   %    if {AttackSuccessful npc} then
   % 	 Ack
   %    in
   % 	 {Send FightAnim attack(pnj Ack)}
   % 	 {Send WaitAnim wait(FightPort Ack endmove)}
   % 	 {Max Health-TrainerHitted 0}
   %    else Health % TODO : add animation/text description failed attack
   %    end
   % end
   TrainerHitted#EnemyHitted = {CheckDamage TrainerP.type EnemyP.type}
   WaitAnim = {Waiter}
   FightPort = {NewPortObjectKillable
		state(trainer:alive enemy:alive fighting:false)
		fun{$ Msg state(trainer:TState enemy:EState fighting:OK)}
		   case Msg
		   of run then
		      if OK then
			 state(trainer:TState enemy:EState fighting:OK)
		      else
			 if {RunSuccessful} then B in
			    {Send EnemyP.pid refill}
			    %TODO: send signal to set exit text
			    {Send FightAnim  exit(B)}
			    %Sends signal to mainthread to change placeH
			    {Send WaitAnim wait(MAINPO B set(map))}
			    state(killed)
			 else
			    % Send signal to itself for IA turn = automatic
			    % attack
			    {Send FightPort fightIA}
			    state(trainer:TState enemy:EState fighting:true)
			 end
		      end
		   [] fight then
		      if OK then
			 state(trainer:TState enemy:EState fighting:OK)
		      else
			 NEState Ack
		      in
			 if {AttackSuccessful player} then
			    {Show attackChar}
			    {Send EnemyP.pid damage(EnemyHitted NEState)}
			    {Wait NEState}
                            % ^ to avoid concurrency issues (even if they are
			    %   VERY unlikely)
			    {Send FightAnim attack(player Ack)}
			 else
			    {Send FightAnim attackFail(player Ack)}
			    NEState = alive
			 end

			 if NEState == alive then
			    {Send WaitAnim wait(FightPort Ack fightIA)}
			    state(trainer:TState enemy:NEState fighting:OK)
			 else B in
			 %TODO set you won text before exit
			    {Send FightAnim exit(B)}
			 %sends signal to  mainthread
			    {Send WaitAnim wait(MAINPO B set(map))}
			    state(killed)
			 end
		      end
		   [] fightIA then NTState Ack in
		      if {AttackSuccessful npc} then
			 {Send TrainerP.pid damage(TrainerHitted NTState)}
			 {Wait NTState}
                            % ^ to avoid concurrency issues (even if they are
			    %   VERY unlikely)
			 {Send FightAnim attack(pnj Ack)}
		      else
			 {Send FightAnim attackFail(pnj Ack)}
			 NTState = alive
		      end

		      if NTState == alive then
			 {Send WaitAnim wait(FightPort Ack input)}	 
			 state(trainer:NTState enemy:EState fighting:OK)
		      else B in
			 %TODO set 'you lost' frame before exit
			 {Send FightAnim exit(B)}
			 %send signal to waiter to send signal to mainthread
			 %TODO: add 'lost' screen
			 {Send WaitAnim wait(MAINPO B set(map))}
			 state(killed)
		      end
		   [] input then
		      state(trainer:TState enemy:EState fighting:false)
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
%Function that creates a Pokemoz
fun{CreatePokemoz Name Lvl State}%State = {wild,trainer,player}
   Type = {GETTYPE Name}
   HealthMax = 20+(Lvl-5)*2
   ExpMax = EXPER.Lvl
   %Send Kill signal when the wild pokemoz vanishes, trainer is defeated
   %or pokemoz is released back into the wild
   Pokid = {NewPortObjectKillable state(health:h(act:HealthMax max:HealthMax)
					exp:e(act:0 max:ExpMax) lvl:Lvl)
	    fun{$ Msg state(health:He exp:Exp lvl:Lvl)}
	       {Show poke#Msg}
	       % released == kill
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
			if Lvl == NLvl then
			   state(health:He exp:e(act:NExp max:Exp.max)
				 lvl:Lvl)
			else NMaxH = (NLvl-5)*2 + 20 in
			   state(health:he(act:NMaxH max:NMaxH)
				 exp:e(act:NExp max:EXPER.NLvl) lvl:NLvl)
			end			   
		     else % if at maxLvl allready
			state(health:He exp:Exp lvl:Lvl)
		     end
		  else
		     state(health:He exp:e(act:NewExp max:Exp.max)
			   lvl:Lvl)
		  end
	       [] damage(X State) then %State is unbound
		  NHealth ={Max He.act - X 0}
	       in
		  if NHealth == 0 then State = dead
		  else State = alive {Show alive} end
		  state(health:he(act:NHealth max:He.max) exp:Exp lvl:Lvl)
	       [] refill then
		  state(health:he(act:He.max max:He.max) exp:Exp lvl:Lvl)
	       %[] kill then state(killed)
	       end
	    end}%add replenishing function for hospital later on
in
   %pokemoz(name:<String> type:<Atom> pid:<PokemozPID>)
   pokemoz(name:Name type:Type pid:Pokid)
end
% Function that creates a trainer
%@post: returns the id of the PlayerController
fun{CreateTrainer Name X0 Y0 Speed Mapid Canvash Pokemoz Type}
   Trpid
   TrainerObj = Type(poke:Pokemoz pid:Trpid)
   Anid = {AnimateTrainer Canvash X0-1 Y0-1 Speed Name}
   Trid = {Trainer pos(x:X0 y:Y0) Anid}
   Trpid = {TrainerController Mapid Trid Speed TrainerObj}

in
   %trainer(poke:<PokemOz> pid:<TrainerController>) + Todo:add speed to state of trainer?
   TrainerObj
end

% Function that creates a fight
proc{CreateFight Player NPC}
   {Send MAINPO set(fight)}
   CanvasH = CANVAS.fight
   Ack
   Animation = {DrawFight CanvasH Player.poke NPC.poke Ack}
   Fight = {FightController Player.poke NPC.poke Animation}
in
   %Animation = {DrawFight CanvasH Player NPC Ack}
   %Fight = {FightController Player NPC Animation}
   {Wait Ack}
   {BUTTONS.fight.fight bind(event:"<1>" action:
					    proc{$}
					       {Show gotfight}
					       {Send Fight fight}
					    end)}
   {BUTTONS.fight.run bind(event:"<1>" action:
					  proc{$}
					     {Show gotrun}
					     {Send Fight run}
					  end)}
   %Fight
end

%%%%% MAIN THREAD %%%%%%%
% Init = {starters, map, fight, lost, won}
% This function initialises all the handles for the
% placeholder and returns the handle for it's thread
% to change the inside of the placeholder
% @pre: -Frames = a record with all the frame-descriptions in it
%       -Init   = the initial state (<Atom>)
%       -PlaceH = handle of the placeholder
fun{MAIN Init Frames PlaceH MapName Handles}
   Sort =[starters map fight]% lost won]
   %Handles = handles(starters:_ map:_ fight:_ lost:_ won:_)
   Main = {NewPortObjectKillable state(Init false)
	   fun{$ Msg state(Frame I0)}
	      {Show main#Msg}
	      case Msg
	      of set(NewFrame) then
		 if NewFrame == Frame then {Show error#NewFrame}
		    state(Frame I0)
		 else
		    {Show set#NewFrame}
		    {PlaceH set(Handles.NewFrame)}
		    state(NewFrame I0)
		 end
	      [] get(X) then X=Frame state(Frame I0)
	      [] makeTrainer(Name) then
		 if I0 then
		    state(Frame I0)
		 else
		    Name2 = {AtomToString Name}
		    Name3 = (Name2.1-32)|Name2.2
		    Map = {ReadMap MapName}
		    Enemy
		    Pokemoz = {CreatePokemoz Name3 5 player}
		    Pokemoz2 = {CreatePokemoz "Charmandoz" 5 player}
		 in
		    % Initialize the Fight tags
		    thread {InitFightTags} end
		    % Create the Map Environment
		    MAPID = {MapController Map}
		    TAGS.map={DrawMap CANVAS.map Map 7 7}%should NOT EVER
		                                         % be threaded!!!
		    {PlaceH set(Handles.map)}
		    PLAYER = {CreateTrainer "Red" 7 7 SPEED MAPID
			      CANVAS.map Pokemoz player}
		    {Send MAPID init(x:7 y:7 PLAYER)}
		    %TODO:add ennemies to the map
		    Enemy = {CreateTrainer "Red" 6 6 SPEED MAPID
		    	     CANVAS.map Pokemoz2 trainer}
		    {Send MAPID init(x:6 y:6 Enemy)}
		    state(map true)
		 end
	      end
	  end}

in
   for I in Sort do
      {PlaceH set(Frames.I)}
      %{Delay 1000}
   end
   {PlaceH set(Handles.Init)}
   Main %proc{$ X} {Send Main X} end
end