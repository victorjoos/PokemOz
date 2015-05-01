functor
import
   PortDefinitions
   Widget
export
   trainer:AnimateTrainer
   fight:DrawFight
define
   % Imports
   GETDIR = PortDefinitions.getDir
   GETDIRSIDE = PortDefinitions.getDirSide
   NewPortObjectKillable = PortDefinitions.kPort
   NewPortObjectMinor = PortDefinitions.mPort

   RedrawFight = Widget.redrawFight
   LoadImage = Widget.loadImage
   FightScene = Widget.fightScene
   CANVAS = Widget.canvas
   TAGS = Widget.tags 
   DELAY = Widget.delay
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
		  [] reset then
		     {TagIm delete}
		     {Canvash create(image image:{LoadImage [Name "_up" "_still"]}
				     X0*67+33 Y0*67+33 tags:TagIm)}
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
	      others:_ ball:_) then
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
   proc{MoveDamageComp Tag Diff NTag Ty B}%NTag will be deleted
      DT  = {DELAY.get} div 2
      Dx  = dx(5  ~25  15  15 ~10)
      Dy  = dy(20  10 ~15 ~5  ~10)
      Type = {AtomToString Ty}
   in
      for I in 1..5 do
	 {Tag move(Diff*Dx.I Diff*Dy.I)}
	 if I\=1 andthen B then
	    {NTag set(image:{LoadImage [ Type "_" {IntToString I}]})}
	 end
	 {Delay DT}
      end
      if B then {NTag delete} end
   end
   proc{MoveDamage Tag Diff NTag Ty}%NTag will be deleted
      {MoveDamageComp Tag Diff NTag Ty true}
   end
%Intern
   proc{ChangeBar Tag He X0 Y0}
      W = 100
      H = 10
      Size = (W*He.act) div He.max
      CanvasH = CANVAS.fight
      Color
      Divi = {IntToFloat Size} / {IntToFloat W}
      if Divi =< 0.2 then Color = red
      elseif Divi =< 0.5 then Color = yellow
      else Color = green end
   in
      {Tag delete}
      {CanvasH create(rectangle X0 Y0 X0+Size Y0+H fill:Color tags:Tag)}
   end
%Inter
   proc{MoveBall Tag}
      Canvas = CANVAS.fight
      Dt = {DELAY.get} div 3
      XX = 195
      YY = 190
      Dx = dx( 20  18  15  15  15  15  10 10 10 10 9  6)
      Dy = dy(~30 ~30 ~30 ~30 ~30 ~20 ~10 ~5 5  8  10 12)
      Img= ball("ball_2" "ball_3" "ball_4" "ball_1"
		"ball_2" "ball_3" "ball_4" "ball_1"
		"ball_2" "ball_3" "ball_4" "ball_1")
   in
      {Canvas create(image image:{LoadImage "ball_1"}
		     XX YY tags:Tag)}
      for I in 1..12 do
	 {Delay Dt}
	 {Tag move(Dx.I Dy.I)}
	 {Tag set(image:{LoadImage Img.I})}
      end
   end
%Extern
   fun{DrawFight PlayL NpcL}
      AllTags
      LTagsNpc
      LTagsPlay
      Canvas = CANVAS.fight
      FirstPlay = {Send PlayL getFirst($)}
      FirstNpc  = {Send NpcL  getFirst($)}
      Text = proc{$ X} {TAGS.fight2 set(text:X)} end
      Fid={NewPortObjectKillable
	   state(player:FirstPlay
		 enemy:FirstNpc)
	   fun{$ Msg state(player:Play enemy:Npc)}
	      case Msg
	      of exit(B Msg) then  DT = {DELAY.get} div 4 in
		 {Delay DT*4}
		 {Text Msg}
		 {Delay DT*4}
		 for _ in 1..25 do
		    {MoveFight LTagsNpc   1}
		    {MoveFight LTagsPlay ~1}
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
	      [] switch(Person New B) then NewPlay NewNpc in
		 case Person
		 of player then
		    DT = {DELAY.get} div 4
		 in
		    for _ in 1..25 do
		       {MoveFight LTagsPlay ~1}
		       {Delay DT}
		    end
		    {Apply LTagsPlay proc{$ T} {T delete} end}
            %Switch the images here
		    {RedrawFight player New}
		    for _ in 1..25 do
		       {MoveFight LTagsPlay ~1}
		       {Delay DT}
		    end
		    NewPlay = New NewNpc = Npc
		 [] npc then
		    DT = {DELAY.get} div 3
		 in
		    for _ in 1..25 do
		       {MoveFight LTagsNpc 1}
		       {Delay DT}
		    end
		    {Apply LTagsNpc proc{$ T} {T delete} end}
            %Switch the images here
		    {RedrawFight npc New}
		    for _ in 1..25 do
		       {MoveFight LTagsNpc 1}
		       {Delay DT}
		    end
		    NewPlay = Play NewNpc = New
		 end
		 B=unit
		 state(player:NewPlay enemy:NewNpc)
	      [] illRun then
		 {Text "You can''t run from a Trainer-Battle!"}
		 state(player:Play enemy:Npc)
	      [] failRun then
		 {Text "You couldn''t escape this time!"}
		 state(player:Play enemy:Npc)
	      [] illCatch(Msg) then
		 if Msg == playVsNpc then
		    {Text "Stop trying to steal pokemoz!"}
		    state(player:Play enemy:Npc)
		 else
		    {Text "You''re inventory is FULL!"}
		    state(player:Play enemy:Npc)
		 end
	      [] catched(B) then
		 Tag = AllTags.ball
		 DT = {DELAY.get} div 4
	      in
         %handles the special exit too
		 {MoveBall Tag}
		 {Text {Flatten ["Your OzBall catched a wild " Npc.name "!"]}}
		 {AllTags.plateau.2.2 set(image:{LoadImage [Npc.name "_small"]})}
		 {Delay DT*2}
		 {Apply LTagsNpc.2 proc{$ X} {X delete} end}
		 {Delay DT*4}
		 for _ in 1..25 do
		    {MoveFight LTagsPlay ~1}
		    {MoveFight [LTagsNpc.1 AllTags.ball] 1}
		    {Delay DT}
		 end
		 {Apply LTagsPlay proc{$ T} {T delete} end}
		 {TAGS.fight2 delete}
		 B=unit
		 {AllTags.ball delete} {LTagsNpc.1 delete}
		 state(killed)
	      [] failCatch(B) then Tag = AllTags.ball in
		 {MoveBall Tag}
		 {Text "Your OzBall missed!"}
		 {Tag delete}
		 {MoveDamageComp  AllTags.plateau.2.2 ~1 Tag grass false}
		 B = unit
		 state(player:Play enemy:Npc)
	      end
	   end}
      Btn Arw
   in
      thread
	 if {Label FirstNpc} == wild then
	    {Text "A wild Pokemoz appeared"}
	    {Delay {DELAY.get}*6}
	 end
	 {Text "Choose your action"}
      end
      thread
	 Buttons#Arrows={FightScene FirstPlay FirstNpc}
      in
	 Btn = Buttons Arw = Arrows
	 AllTags = TAGS.fight
	 {AllTagsToList AllTags LTagsPlay LTagsNpc}
	 local DT = {DELAY.get} div 4 in
	    for _ in 1..25 do
	       {MoveFight LTagsNpc   1}
	       {MoveFight LTagsPlay ~1}
	       {Delay DT}
	    end
	 end
      end
      Fid#Btn#Arw
   end
end