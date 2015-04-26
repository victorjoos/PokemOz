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
%%%%%%% SPECIAL ARROWMOVEMENTS %%%%%%%%%%%
fun{GetArrows MaxX MaxY}
   ArrowId = {NewPortObjectKillable state(1 1)
	      fun{$ Msg state(X Y)}
		 case Msg
		 of up(NewX NewY) then
		    if Y==1 then NewX=X NewY=MaxY
		    else NewX=X NewY=Y-1 end
		    state(NewX NewY)
		 [] down(NewX NewY) then
		    if Y==MaxY then NewX=X NewY=1
		    else NewX=X NewY=Y+1 end
		    state(NewX NewY)
		 [] right(NewX NewY) then Nx Ny in
		    if X==MaxX then Nx=1 Ny=Y+1
		    else Nx=X+1 Ny=Y end
		    if Ny==MaxY+1 then NewY=1
		    else NewY=Ny end
		    NewX=Nx
		    state(NewX NewY)
		 [] left(NewX NewY) then Nx Ny in
		    if X==1 then Nx=MaxX Ny=Y-1
		    else Nx=X-1 Ny=Y end
		    if Ny==0 then NewY=MaxY
		    else NewY=Ny end
		    NewX=Nx
		    state(NewX NewY)
		 [] get(XX YY) then XX=X YY=Y state(X Y)
		 [] getLast(XX YY B) then
		    XX=X YY=Y
		    if B==true then state(X Y)
		    else state(killed) end
		 [] kill then state(killed)
		 end
	      end}
in
   ArrowId
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
		       ActDel = {DELAY.get}
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
   elseif Hit == npc then
      case PlayType
      of fire  then if NpcType==grass then 3 else 1 end
      [] grass then if NpcType==water then 3 else 1 end
      [] water then if NpcType==grass then 3 else 1 end
      end
   else
      case NpcType
      of fire  then if PlayType==grass then 3 else 1 end
      [] grass then if PlayType==water then 3 else 1 end
      [] water then if PlayType==grass then 3 else 1 end
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
fun{GetNewPokemoz PokeL}
   LivingList = {Send PokeL getAllLiving($)}
   Rand = ({OS.rand} mod {Length LivingList}) + 1
in
   {List.nth LivingList Rand}
end
fun {RunSuccessful Play Npc} % Npc is a WILD pokemoz guaranteed!!
   true % TODO(victor) : add probability
end
fun {CatchSuccessful Play Npc}
   true
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
			 if {Label Npc}\=wild then
			    {Send FightAnim illRun}
			    state(player:Play enemy:Npc fighting:OK)
			 elseif {RunSuccessful Play Npc} then B in
			    {Send FightAnim
			     exit(B "You ran away cowardly...")}
			    {Send WaitAnim wait(MAINPO B set(map))}
			    {Send WaitAnim wait(NpcL B releaseAll)}
			    state(killed)
			 else
			    % Send signal to itself for AI turn = automatic
			    % attack
			    {Send FightAnim failRun}
			    {Send FightPort fightIA}
			    state(trainer:Play enemy:Npc fighting:true)
			 end
		      end
		   [] action(X) then X = OK
		      state(player:Play enemy:Npc fighting:OK)
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
			 elseif {Send NpcL getState($)} == allDead then
			    B
			 in
			    {Send FightAnim exit(B "You WON!")}
			    {Send WaitAnim wait(MAINPO B set(map))}
			    {Send PlayL shareExp({Send NpcL getAllExp($)})}
			    {Send NpcL releaseAll}
			    state(killed)
			 else
			    {Send WaitAnim wait(FightPort Ack switchIA)}
			    state(player:Play enemy:Npc fighting:true)
			 end
		      end
		   [] fightIA then NTState Ack in
		      if {AttackSuccessful Play Npc npc} then
			 Damage = {GetDamage Play.type Npc.type player}
		      in
			 {Send Play.pid damage(Damage NTState)}
			 {Wait NTState}%actually not necessary
			 {Send FightAnim attack(npc Ack)}
		      else
			 {Send FightAnim attackFail(npc Ack)}
			 NTState = alive
		      end

		      if NTState == alive then
			 {Send WaitAnim wait(FightPort Ack input)}	 
			 state(player:Play enemy:Npc fighting:OK)
		      elseif {Send PlayL getState($)} == allDead then
			 B
		      in %TODO : reset Game in HOSPITAL
			 {Send FightAnim exit(B "You LOST!")}
			 {Send NpcL refill}
			 {Send WaitAnim wait(MAINPO B set(map))}
			 if {Label Npc}==wild then
			    {Send WaitAnim wait(NpcL B releaseAll)}
			 end
			 state(killed)
		      else
			 proc{FigureLoop Status} B in
			    thread {DrawPokeList dead(B)} end
			    if Status == first then
			       {Send MAINPO set(pokelist)}
			    end
			    if B\=none andthen B\=auto then
			       {Send FightPort switch(B play)}
			    elseif B == auto then
			       NewPkm = {GetNewPokemoz PlayL}
			    in
			       {Send FightPort switch(NewPkm play)}
			    else
			       {FigureLoop xth}
			    end
			 end
		      in
			 thread {FigureLoop first} end
			 state(player:Play enemy:Npc fighting:true)
		      end
		   [] input then
		      state(player:Play enemy:Npc fighting:false)    
		   [] switch(NewPkm Next) then %this signal can only be sent
		                     % by a valid button
		      if NewPkm == Play then
			 state(player:Play enemy:Npc fighting:OK)
		      else
			 Ack={Send FightAnim switch(player NewPkm $)}
		      in
			 if Next == ia then
			    {Send WaitAnim wait(FightPort Ack fightIA)}
			 else
			    {Send WaitAnim wait(FightPort Ack input)}
			 end
			 state(player:NewPkm enemy:Npc fighting:true)
		      end
		   [] switchIA then
		      NewNpc = {GetNewPokemoz NpcL} Ack
		   in
		      {Send FightAnim switch(npc NewNpc Ack)}
		      {Send WaitAnim wait(FightPort Ack fightIA)}
		      state(player:Play enemy:NewNpc fighting:true)
		   [] catching then
		      if {Label Npc} \= wild then
			 {Send FightAnim illCatch(playVsNpc)}
			 state(player:Play enemy:Npc fighting:OK)
		      elseif {Send PlayL get($ 6)}\=none then
			 {Send FightAnim illCatch(playFull)}
			 state(player:Play enemy:Npc fighting:OK)
		      elseif {CatchSuccessful PlayL Npc} then Ack in
			 {Send NpcL captured}
			 {Send PlayL add(Npc _)}
			 {Send FightAnim catched(Ack)}
			 {Send WaitAnim wait(MAINPO Ack set(map))}
			 state(killed)
		      else Ack in
			 {Send FightAnim failCatch(Ack)}
			 {Send WaitAnim wait(FightPort Ack fightIA)}
			 state(player:Play enemy:Npc fighting:true)
		      end
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
	       [] addExp(AddExp Evolve) then
                  %will replenish Health automatically in
                  %case of evolution and send info in case of
		  %evolution
		  NewExp = AddExp+Exp.act
	       in
		  if NewExp >= Exp.max then
		     if Lvl < 10 then NExp NLvl in
			{GetLevel NewExp Lvl NExp NLvl}
			if Lvl == NLvl then
			   Evolve = none
			   state(health:He exp:e(act:NExp max:Exp.max)
				 lvl:Lvl)
			else NMaxH = (NLvl-5)*2 + 20 in
			   %TODO!!!
			   Evolve = none
			   state(health:he(act:NMaxH max:NMaxH)
				 exp:e(act:NExp max:EXPER.NLvl) lvl:NLvl)
			end			   
		     else % if at maxLvl allready
			Evolve = none
			state(health:He exp:Exp lvl:Lvl)
		     end
		  else
		     Evolve = none
		     state(health:He exp:e(act:NewExp max:Exp.max)
			   lvl:Lvl)
		  end
	       [] damage(X State) then %State is unbound
		  NHealth ={Max He.act - X 0}
	       in
		  if NHealth == 0 then State = dead
		  else State = alive  end
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
fun{GatherExp Rec I Acc}
   if Rec.I == none then Acc
   else
      {GatherExp Rec I+1 Acc+{Send Rec.I.pid getLvl($)}}
   end
end
proc{GetAlive State First Length Ind AccLength Findex List}
   if Ind == 7 then Length = AccLength
   else
      if State.Ind == none then
	 for I in Ind..6 do
	    List.I = false
	 end
	 Length = AccLength
      elseif {Send State.Ind.pid getHealth($)}.act == 0 then
	 if Ind==Findex then First=false end
	 List.Ind = false
	 {GetAlive State First Length Ind+1 AccLength   Findex List}
      else
	 if Ind==Findex then First=true  end
	 List.Ind = true
	 {GetAlive State First Length Ind+1 AccLength+1 Findex List}
      end
   end
end
proc{DispatchExp OldState NewState Ind List Exp Rest}
   if Ind > 6 then skip
   else
      if List.Ind then
	 Evolve ActExp ActRest
	 if Rest > 0 then ActRest = 1
	 else ActRest = 0 end
	 if Ind == OldState.first then
	    ActExp = 2*Exp+ActRest
	 else
	    ActExp = Exp+ActRest
	 end
      in
	 {Send OldState.Ind.pid addExp(ActExp Evolve)}
	 if Evolve == none then
	    NewState.Ind = OldState.Ind
	 else
	    skip
	 end
	 {DispatchExp OldState NewState Ind+1 List Exp Rest-1}
      else
	 NewState.Ind = OldState.Ind
	 {DispatchExp OldState NewState Ind+1 List Exp Rest}
      end
   end
end
fun{GetAllLiving State Ind}
   if Ind==7 then nil
   elseif State.Ind == none then nil
   elseif{Send State.Ind.pid getHealth($)}.act == 0 then
      {GetAllLiving State Ind+1}
   else
      State.Ind|{GetAllLiving State Ind+1}
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
			  NewState.first = 1
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
		 [] getAverage(X) then %TODO : refaire pour faire le MAX
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
		 [] getAllExp(X) then
		    X={GatherExp State 1 0}
		    State
		 [] captured then %only possible with wild pokemoz!
		    all(1:none 2:none 3:none 4:none 5:none 6:none first:none)
		 [] shareExp(TotExp) then
		    {Show totExp#TotExp}
		    NewState = all(1:_ 2:_ 3:_ 4:_ 5:_ 6:_ first:State.first)
		    First %checks if the first one is alive
		    Length %number of alive pokemoz
		    XP Rest List=list(1:_ 2:_ 3:_ 4:_ 5:_ 6:_)
		    {GetAlive State First Length 1 0 State.first List}
		    if First then
		       XP = TotExp div (Length+1)
		       Rest = TotExp mod (Length+1)
		    else
		       XP = TotExp div Length
		       Rest = TotExp mod Length
		    end
		 in
		    {DispatchExp State NewState 1 List XP Rest }
		    NewState
		 [] getAllLiving(X) then
		    X={GetAllLiving State 1}
		    State
		 [] getState(X) then
		    if {Length {GetAllLiving State 1}} == 0 then
		       X=allDead
		    else
		       X=alive
		    end
		    State
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
					       {Send Fight fight}
					    end)}
   {BUTTONS.fight.run bind(event:"<1>" action:
					  proc{$}
					     {Send Fight run}
					  end)}
   {BUTTONS.fight.switch bind(event:"<1>"
			      action:
				 proc{$}
				    B
				 in
				    if {Send Fight action($)} == false then
				       thread {DrawPokeList fight(B)} end
				       {Send MAINPO set(pokelist)}
				       thread
					  if B\=none then
					     {Send Fight switch(B ia)}
					  end
				       end
				    else skip
				    end
				 end)}
   {BUTTONS.fight.capture bind(event:"<1>"
			       action:
				  proc{$}
				     if {Send Fight action($)} == false then
					{Send Fight catching}
				     end
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
   Sort =[starters map fight pokelist]% lost won]
   %Handles = handles(starters:_ map:_ fight:_ lost:_ won:_)
   Main = {NewPortObjectKillable state(Init)
	   fun{$ Msg state(Frame)}
	      case Msg
	      of set(NewFrame) then
		 if NewFrame == Frame then {Show error#NewFrame}
		    state(Frame)
		 else
		    {Show set#NewFrame}
		    {CANVAS.NewFrame getFocus(force:true)}
		    {PlaceH set(Handles.NewFrame)}
		    state(NewFrame)
		 end
	      [] get(X) then X=Frame state(Frame)
	      [] makeTrainer(Name) then
		 if Frame\=starters then
		    state(Frame)
		 else
		    Name2 = {AtomToString Name}
		    Name3 = (Name2.1-32)|Name2.2
		    Map = {ReadMap MapName}
		    Enemy
		 in
		    % Initialize the tags
		    thread {InitFightTags} end
		    thread {InitPokeTags} end
		    % Create the Map Environment
		    MAPID = {MapController Map}
		    TAGS.map={DrawMap Map 7 7}%should NOT EVER
		                              % be threaded!!!
		    {PlaceH set(Handles.map)}
		    {CANVAS.map getFocus(force:true)}
		    PLAYER = {CreateTrainer "Red" 7 7 SPEED MAPID
			      [Name3 "Bulbasoz"] [9 5] player}
		    {Send MAPID init(x:7 y:7 PLAYER)}
		    %TODO:add ennemies to the map
		    Enemy = {CreateTrainer "Red" 6 6 SPEED MAPID
		    	     ["Oztirtle" "Oztirtle"] [5 7] trainer}
		    {Send MAPID init(x:6 y:6 Enemy)}
		    state(map)
		 end
	      end
	  end}

in
   for I in Sort do
      {PlaceH set(Frames.I)}
   end
   {PlaceH set(Handles.Init)}
   {StarterPokemoz}
   Main 
end


