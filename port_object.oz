% This file will contain all the portObjects' descriptions and code
%declare
%%%%% CONSTANTS %%%%%%%%%
%SPEED = 5
%DELAY = 100
%MAXX  = 7
%MAXY  = 7

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
GetWildling
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
	    fun{$ Msg state(State)}
	       case Msg
	       of get(X) then
		  X=State
		  state(State)
	       [] getGround(X) then
		  X=Ground
		  state(State)
	       [] coming(T Plid Val) then
		  {Send Tid starttimer(Tilid T arrived(Plid Val))}
		  state(reserved)
	       [] arrived(Plid Val) then
		  Val=unit
		  if Ground == grass andthen {Label Plid} == player then
		     Wild = {GetWildling}
		  in
		     if Wild \= none then
			{CreateFight Plid Wild}
		     end
		  end
		  {SignalArrival Plid}
		  state(occupied(Plid))
	       [] new(Dir Trainer) then
		  case State
		  of occupied(Y) then LblY = {Label Y} in
		     if LblY\={Label Trainer} andthen
			{Send Y.pid getDir($)} == Dir
		     then
			if LblY==player then
			   if {Send Trainer.poke getFirst($)} \= none then
			      {CreateFight Y Trainer}
			   end
			else
			   if {Send Y.poke       getFirst($)} \= none then
			      {CreateFight Trainer Y}
			   end
			end
		     end
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
%%%%%%%% WILD-POKEMOZ  %%%%%%%%
CreatePokemoz CreatePokemozList
fun{RandomName}
   "Bulbasoz"
end
WildlingTrainer
thread WildlingTrainer = wild(poke:{CreatePokemozList nil nil wild}) end
%CreateTrainer Name X0 Y0 Speed Mapid Names Lvls Type}
fun{GetWildling}
   if ({OS.rand} mod 100)+1 =< PROBABILITY then
      Lvl={FloatToInt {Round {Send PLAYER.poke getAverage($)}}}
      R
      Ra = {OS.rand} mod 15
      if Ra < 10 then R = ~1
      elseif Ra < 13 then R = 0
      else R = 1 end
      NLvl = {Max Lvl+R 5}
      Pokemoz={CreatePokemoz {RandomName} {Min NLvl 10} wild}
      Ack
   in
      {Send WildlingTrainer.poke add(Pokemoz Ack)}
      {Wait Ack}
      WildlingTrainer
   else
      none
   end
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
		       ActDel = {DELAY.get} {Show ActDel}
		       Sig  = coming(Speed*ActDel TrainerObj Val)
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
fun{GetDamage PlayType NpcType Hit} % Hit = player or npc
   if PlayType == NpcType then 2
   elseif Hit == player then
      case PlayType
      of fire  then if NpcType==grass then 1 else 3 end
      [] grass then if NpcType==fire  then 3 else 1 end
      [] water then if NpcType==fire  then 1 else 3 end
      end
   else
      case NpcType
      of fire  then if NpcType==grass then 3 else 1 end
      [] grass then if NpcType==fire  then 1 else 3 end
      [] water then if NpcType==fire  then 3 else 1 end
      end
   end
end
fun {AttackSuccessful Play Npc Attacker}
   PlayLvl = {Send Play.pid getLvl($)}
   NpcLvl  = {Send  Npc.pid getLvl($)}
in
   case Attacker
   of player then
      Probability = (6+PlayLvl-NpcLvl)*9
      Rand = ({OS.rand} mod 100)+1 % from 1 to 100
   in
      if Rand =< Probability then true
      else false
      end
   [] npc then
      Probability = (6+NpcLvl-PlayLvl)*9
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
fun {FightController PlayL NpcL FightAnim}%PlayL and NpcL are <PokemozList>
   WaitAnim = {Waiter}
   FightPort = {NewPortObjectKillable
		state(player:{Send PlayL getFirst($)}
		       enemy:{Send NpcL  getFirst($)}
		      fighting:false)
		fun{$ Msg state(player:Play enemy:Npc fighting:OK)}
		   case Msg
		   of run then
		      if OK then
			 state(player:Play enemy:Npc fighting:OK)
		      else
			 if {RunSuccessful} then B in
			    {Send FightAnim  exit(B)}
			    {Send WaitAnim wait(MAINPO B set(map))}
			    if {Label Npc}==wild then
			       {Send WaitAnim wait(NpcL B release(1 _))}
			    end
			    state(killed)
			 else
			    % Send signal to itself for IA turn = automatic
			    % attack
			    {Send FightPort fightIA}
			    state(trainer:Play enemy:Npc fighting:true)
			 end
		      end
		   [] fight then
		      if OK then
			 state(player:Play enemy:Npc fighting:OK)
		      else
			 NEState Ack
		      in
			 if {AttackSuccessful Play Npc player} then
			    Damage = {GetDamage Play.type Npc.type npc}
			 in
			    {Send Npc.pid damage(Damage NEState)}
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
			    state(player:Play enemy:Npc fighting:true)
			 else B in
			    {Send FightAnim exit(B)}
			    {Send WaitAnim wait(MAINPO B set(map))}
			    {Send NpcL releaseAll}
			    state(killed)
			 end
		      end
		   [] fightIA then NTState Ack in
		      if {AttackSuccessful Play Npc npc} then
			 Damage = {GetDamage Play.type Npc.type player}
		      in
			 {Send Play.pid damage(Damage NTState)}
			 {Wait NTState}
                            % ^ to avoid concurrency issues (even if they are
			    %   VERY unlikely)
			 {Send FightAnim attack(npc Ack)}
		      else
			 {Send FightAnim attackFail(npc Ack)}
			 NTState = alive
		      end

		      if NTState == alive then
			 {Send WaitAnim wait(FightPort Ack input)}	 
			 state(player:Play enemy:Npc fighting:OK)
		      else B in
			 {Send FightAnim exit(B)}
			 {Send NpcL refill}
			 %TODO: add 'lost' screen
			 {Send WaitAnim wait(MAINPO B set(map))}
			 if {Label Npc}==wild then
			    {Send WaitAnim wait(Npc.pid B kill)}
			 end
			 state(killed)
		      end
		   [] input then
		      state(player:Play enemy:Npc fighting:false)
		      
		   [] switch(X) then %this signal can only be sent
		                     % by a valid button
		      NewPkm={Send PlayL get($ X)}
		   in
		      if NewPkm == Play then
			 state(player:Play enemy:Npc fighting:OK)
		      else
			 Ack={FightAnim switch(player NewPkm $)}
		      in
			 {Send WaitAnim wait(FightPort Ack fightIA)}
			 state(player:{Send PlayL getFirst($)}
			       enemy:Npc fighting:true)
		      end
		   [] catching then
		      %TODO check if wild or not
		      state(player:Play enemy:Npc fighting:true)
		   end
		end}
in
   % TODO add check on death
   %      add chances of capture
   %      add chances of running
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
fun{CreatePokemoz Name Lvl0 State}
   Type = {GETTYPE Name}
   HealthMax = 20+(Lvl0-5)*2
   ExpMax = EXPER.Lvl0
   %Send Kill signal when the wild pokemoz vanishes, trainer is defeated
   %or pokemoz is released back into the wild
   Pokid = {NewPortObjectKillable state(health:h(act:HealthMax max:HealthMax)
					exp:e(act:0 max:ExpMax) lvl:Lvl0)
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
	       [] kill then state(killed)
	       end
	    end}%add replenishing function for hospital later on
in
   %pokemoz(name:<String> type:<Atom> pid:<PokemozPID>)
   State(name:Name type:Type pid:Pokid)
end
% CreatePokemozList
% @pre : Names: List of strings of the names of the initial pokemoz
%        Lvls : List of the lvls of the pokemozs (must have the same lenght as Names)
%        State: trainer,player,wild
% @post: returns the pid of the pokemozList
proc{GetPokemoz Names Lvl Rec ActInd MaxInd Type}
   case Names
   of nil then MaxInd = ActInd
   []H|T then
      Rec.ActInd = {CreatePokemoz H Lvl.1 Type}
      {GetPokemoz T Lvl.2 Rec ActInd+1 MaxInd Type}
   end
end
proc{AddPokemoz OldRec NewRec Pkm I B}
   if B andthen OldRec.I == none then 
      NewRec.I = Pkm
      if OldRec.first == none then
	 NewRec.first = I
      else
	 NewRec.first = OldRec.first
      end
       {AddPokemoz OldRec NewRec Pkm I+1 false}
   elseif I<7 then
      NewRec.I = OldRec.I
      {AddPokemoz OldRec NewRec Pkm I+1 B}
   else skip
   end
end
proc{RmPokemoz OldRec NewRec Ind IndMax}
   if Ind < IndMax then
      NewRec.Ind = OldRec.Ind
      {RmPokemoz OldRec NewRec Ind+1 IndMax}
   elseif Ind < 6 then
      NewRec.Ind = OldRec.(Ind+1)
      {RmPokemoz OldRec NewRec Ind+1 IndMax}
   else
      NewRec.6 = none
   end
end
fun{CreatePokemozList Names Lvls Type}
   Init = all(1:_ 2:_ 3:_ 4:_ 5:_ 6:_ first:_)
   Q =  {GetPokemoz Names Lvls Init 1 $ Type}
   for I in Q..6 do
      Init.I = none
   end
   if Q \= 0 then Init.first = 1
   else Init.first = none end
   PokeLid = {NewPortObject Init
	      fun{$ Msg State}
		 {Show State}
		 case Msg
		 of add(Pkm B) then
		    if State.6 \= none then
		       B = false
		       State
		    else
		       NewState = all(1:_ 2:_ 3:_ 4:_ 5:_ 6:_ first:_)
		    in
		       {AddPokemoz State NewState Pkm 1 true}
		       B = true
		       {Show NewState}
		       NewState
		    end
		 [] switchFirst(Ind B) then
		    if Ind == State.first then
		       B=unit State
		    else
		       NewState = all(1:State.1 2:State.2 3:State.3
				      4:State.4 5:State.5 6:State.6
				      first:Ind) in
		       B=unit
		       NewState
		    end
		 [] release(Ind B) then
		    if State.Ind == none then B=unit State
		    else
		       NewState = all(1:_ 2:_ 3:_ 4:_ 5:_ 6:_ first:_)
		    in
		       {RmPokemoz State NewState 1 Ind}
		       {Send State.Ind.pid kill}
		       if Ind == State.first then
			  NewState.first = NewState.1
		       else
			  NewState.first = State.first
		       end
		       B=unit
		       NewState
		    end
		 [] get(X Ind) then  X=State.Ind State
		 [] getAll(X) then X=State State
		 [] getFirst(X) then
		    if State.first == none then X = none
		    else X=State.(State.first) end
		    State
		 [] getAverage(X) then
                    %returns the average of the first 3 Pkm
		    if State.2 == none then
		       X = {IntToFloat {Send State.1.pid getLvl($)}}
		    elseif State.3 == none then
		       X = ({IntToFloat {Send State.1.pid getLvl($)}} +
			    {IntToFloat {Send State.2.pid getLvl($)}})/2.0
		    else
		       X = ({IntToFloat {Send State.1.pid getLvl($)}} +
			    {IntToFloat {Send State.2.pid getLvl($)}} +
			    {IntToFloat {Send State.3.pid getLvl($)}})/3.0
		    end
		    State
		 [] refill then
		    for I in 1..6 do
		       if State.I \= none then
			  {Send State.I.pid refill}
		       end
		    end
		    State
		 [] releaseAll then
		    for I in 1..6 do
		       if State.I \= none then
			  {Send State.I.pid kill}
		       end
		    end
		    all(1:none 2:none 3:none 4:none 5:none 6:none first:none)
		 end
	      end}
in
   PokeLid
end
% Function that creates a trainer
%@post: returns the id of the PlayerController
fun{CreateTrainer Name X0 Y0 Speed Mapid Names Lvls Type}
   Pokemoz = {CreatePokemozList Names Lvls Type}
   Trpid
   TrainerObj = Type(poke:Pokemoz pid:Trpid)
   Anid = {AnimateTrainer X0-1 Y0-1 Speed Name}
   Trid = {Trainer pos(x:X0 y:Y0) Anid}
   Trpid = {TrainerController Mapid Trid Speed TrainerObj}
in
   %trainer(poke:<PokemOzList> pid:<TrainerController>)
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
		    TAGS.map={DrawMap Map 7 7}%should NOT EVER
		                                         % be threaded!!!
		    {PlaceH set(Handles.map)}
		    PLAYER = {CreateTrainer "Red" 7 7 SPEED MAPID
			      [Name3] [8] player}
		    {Send MAPID init(x:7 y:7 PLAYER)}
		    %TODO:add ennemies to the map
		    Enemy = {CreateTrainer "Red" 6 6 SPEED MAPID
		    	     ["Charmandoz"] [5] trainer}
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