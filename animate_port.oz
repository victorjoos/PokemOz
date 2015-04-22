%declare
%%%%%%% TRAINER ON MAP %%%%%%

% Commands sent to this port are guaranteed to change the state of
% the trainer (to avoid useless animation)
% This isn't redundant bc it creates a separate thread for the
% animation.
%@pre:  Canvash = Canvas Handle where the images are drawn
%       X0,Y0   = Initial Coordinates
%       Speed   = Speed of the trainer
%       Name    = Name of the drawings template
%@post: Returns a PortObject capable of drawing an animation
STATES = states("_walk1" "_still" "_walk2" "_still")
fun{AnimateTrainer X0 Y0 Speed Name}
   Canvash = CANVAS.map
   proc{Animate Dir DT DX Ind Mod DMod} Sup Mod2 in
      if Mod \= 0 then Sup = DMod Mod2=Mod-DMod else Sup = 0 Mod2=0 end
      if Ind < 8 then
	 Next = ((Ind) mod 4)+1
      in
	 {Delay DT}
	 {TagIm set(image:{LoadImage [Name "_" Dir STATES.Next]})}
	 if Dir == "up" orelse Dir == "down" then
	    {TagIm move(DX.x     DX.y+Sup)}
	 else
	    {TagIm move(DX.x+Sup DX.y)}
	 end
	 {Animate Dir DT DX Ind+1 Mod2 DMod}
      else
	 skip
      end
   end
   %Tid   = {Timer}
   TagIm = {Canvash newTag($)}
   Anid  = {NewPortObjectMinor
	    proc{$ Msg}
	       case Msg
	       of move(Dir) then
		  Numb = 8
		  Dir2 = {AtomToString Dir}
		  DT    = ({DELAY.get}*Speed) div Numb
		  DX    = {GETDIR Dir}
		  Delta = delta(x:(DX.x*67) div Numb y:(DX.y*67) div Numb)
		  Mod
		  if DX.x == 0 then Mod = (DX.y*67) mod Numb
		  else              Mod = (DX.x*67) mod Numb end
		  DMod  = {GETDIRSIDE Dir} 
	       in
		  {Animate Dir2 DT Delta 0 Mod DMod}
	       [] turn(Dir) then Dir2 = {AtomToString Dir} in
		  {TagIm set(image:{LoadImage [Name "_" Dir2 "_still"]})}
	       end
	    end}
in
   {Canvash create(image image:{LoadImage [Name "_up" "_still"]}
		   X0*67+33 Y0*67+33 tags:TagIm)}
   Anid
end


%%%%%%% FIGHT SCENE %%%%%%%
% Intern
proc{AllTagsToList AllTags L1 L2}
   case AllTags
   of tags(plateau:plateau(disk(D1 D2) pokemoz(P1 P2))
	   attrib:attrib(text(T1 T2) bars(bar(act:Ba1 Bb1)
					  bar(act:Ba2 Bb2)))
	   others:_) then
      L1 = [D1 P1 T1 Ba1 Bb1]
      L2 = [D2 P2 T2 Ba2 Bb2]
   end
end
%Intern
fun{GetMove Dx} Cst = 20 in
   if     Dx ==  1 then proc{$ Tag} {Tag move( Cst 0)} end
   elseif Dx == ~1 then proc{$ Tag} {Tag move(~Cst 0)} end end
end
%Intern
proc{Apply L F}
   case L of nil then skip
   [] H|T then
      {F H}
      {Apply T F}
   end
end
%Intern
proc{MoveFight LTags Dx}
   {Apply LTags {GetMove Dx}}
end
%Intern
proc{MoveBack Tag Diff} %Diff = 1 for player, ~1 for adv
   DT = {DELAY.get} div 2
   Cst = 10
   Dx = ~Diff*Cst
   Dy =  Diff*Cst
in
   for _ in 1..10 do
      {Tag move(Dx Dy)}
      {Delay DT}
   end
end
%Intern
proc{MoveForward Tag Diff}
   DT = {DELAY.get} div 2
   Cst = 25
   Dx =  Diff*Cst
   Dy = ~Diff*Cst
in
   for _ in 1..4 do
      {Tag move(Dx Dy)}
      {Delay DT}
   end
end
%Intern
proc{MoveDamage Tag Diff NTag Ty}%NTag will be deleted
   DT  = {DELAY.get} div 2
   Dx  = dx(5  ~25  15  15 ~10)
   Dy  = dy(20  10 ~15 ~5  ~10)
   Type = {AtomToString Ty}
in
   for I in 1..5 do
      {Tag move(Diff*Dx.I Diff*Dy.I)}
      if I\=1 then
	 {NTag set(image:{LoadImage [ Type "_" {IntToString I}]})}
      end
      {Delay DT}
   end
   if NTag\=nil then {NTag delete} end
end
%Intern
proc{ChangeBar Tag He X0 Y0}
   {Show He}
   W = 100
   H = 10
   Size = (W*He.act) div He.max
   CanvasH = CANVAS.fight
   Color
   Divi = {IntToFloat W} / {IntToFloat Size}
   if Divi < 0.2 then Color = red
   elseif Divi < 0.5 then Color = yellow
   else Color = green end
in
   {Tag delete}
   {CanvasH create(rectangle X0 Y0 X0+Size Y0+H fill:Color tags:Tag)}
end
%Extern
fun{DrawFight Canvas PlayL NpcL B}
   AllTags
   LTagsNpc
   LTagsPlay
   FirstPlay = {Send PlayL getFirst($)}
   FirstNpc  = {Send NpcL  getFirst($)}
   Text = proc{$ X} {TAGS.fight2 set(text:X)} end
   Fid={NewPortObjectKillable
	state(player:FirstPlay
	       enemy:FirstNpc)
	fun{$ Msg state(player:Play enemy:Npc)}
	   case Msg
	   of exit(B) then  DT = {DELAY.get} div 4 in
	      thread
		 {Delay {DELAY.get}*3}
		%TODO: set Text!!
	      end
	      for _ in 1..25 do
		 {MoveFight LTagsNpc  ~1}
		 {MoveFight LTagsPlay  1}
		 {Delay DT}
	      end
	      {Apply LTagsNpc  proc{$ T} {T delete} end}
	      {Apply LTagsPlay proc{$ T} {T delete} end}
	      {TAGS.fight2 delete}
	      B = unit
	      state(killed)
	   [] attack(P B) then NTag = AllTags.others.1 in
	      case P
	      of npc then
		 PlayHe = {Send Play.pid getHealth($)}
	      in
		 {Delay 200}
		 {Text "The enemy attacked..."}
		 {MoveBack AllTags.plateau.2.2 ~1}
		 thread
		    {Delay {DELAY.get}}
		    {Text "...and HIT!"}
		 end
		 {MoveForward AllTags.plateau.2.2 ~1}
		 {Canvas create(image image:{LoadImage ["grass_1"]} tags:NTag
				125 143)}
		 {MoveDamage  AllTags.plateau.2.1  1 NTag grass}
		 {ChangeBar AllTags.attrib.2.1.act
		  PlayHe 270 165}
		 thread
		    if PlayHe.act \= 0 then
		       {Delay {DELAY.get}*6}
		       {Text "Choose your action"}
		    end
		 end
	      [] player then
		 NpcHe = {Send Npc.pid getHealth($)}
	      in
		 %Show attack
		 {Text "You attacked..."}
		 {MoveBack    AllTags.plateau.2.1  1}
		 thread
		    {Delay {DELAY.get}}
		    {Text "...and HIT!"}
		 end
		 {MoveForward AllTags.plateau.2.1  1}
		 {Canvas create(image image:{LoadImage ["grass_1"]} tags:NTag
				345 45)}
		 {MoveDamage  AllTags.plateau.2.2 ~1 NTag grass}
		 %Show damage taken on enemy health bar
		 {ChangeBar AllTags.attrib.2.2.act
		  NpcHe 110 35}
	      end

	      B = unit
	      state(player:Play enemy:Npc)

	   [] attackFail(P B) then
	      case P
	      of npc then
		 {Delay 200}
		 {Text "The enemy attacked..."}
		 {MoveBack    AllTags.plateau.2.2 ~1}
		 thread
		    {Delay {DELAY.get}}
		    {Text "...and missed!"}
		 end
		 {MoveForward AllTags.plateau.2.2 ~1}
		 thread
		    {Delay {DELAY.get}*6}
		    {Text "Choose your action"}
		 end
	      [] player then
		 {Text "You attacked..."}
		 {MoveBack    AllTags.plateau.2.1  1}
		 thread
		    {Delay {DELAY.get}}
		    {Text "...and missed!"}
		 end
		 {MoveForward AllTags.plateau.2.1  1}
	      end

	      B = unit	      
	      state(player:Play enemy:Npc)
	   end
	end}
in
   thread
      AllTags={FightScene FirstPlay FirstNpc}
      {AllTagsToList AllTags LTagsNpc LTagsPlay}
      local DT = {DELAY.get} div 4 in
	 for _ in 1..25 do 
	    {MoveFight LTagsNpc  ~1}
	    {MoveFight LTagsPlay  1}
	    {Delay DT}
	 end
      end

      B=unit
   end
   Fid
end