declare


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
fun{AnimateTrainer Canvash X0 Y0 Speed Name}
   proc{Animate Dir DT DX Ind Mod DMod} Sup Mod2 in
      if Mod \= 0 then Sup = DMod Mod2=Mod-DMod else Sup = 0 Mod2=0 end
      if Ind < 8 then
	 Next = ((Ind) mod 4)+1
      in
	 {Show Next}
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
   Tid   = {Timer}
   TagIm = {Canvash newTag($)}
   Anid  = {NewPortObjectMinor
	    proc{$ Msg}
	       case Msg
	       of move(Dir) then
		  Numb = 8
		  Dir2 = {AtomToString Dir}
		  DT    = (DELAY*Speed) div Numb
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
					  bar(act:Ba2 Bb2)))) then
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
proc{MoveFight LTags Dx}
   {Apply LTags {GetMove Dx}}
end
fun{DrawFight Canvas Play Adv B}
   AllTags
   LTagsAdv
   LTagsPlay
   Fid={NewPortObjectKillable state(alive)
	fun{$ Msg State}
	   case Msg
	   of exit then
	      for _ in 1..25 do DT = 1000 div 40 in
		 {QTk.flush} 
		 {MoveFight LTagsAdv  ~1}
		 {MoveFight LTagsPlay  1}
		 {Delay DT}
	      end
	      state(killed)
	   [] attack(P B) then
	      case P
	      of pnj then
		 skip
	      [] player then
		 skip
	      end
	      B = unit
	      State
	   end
	end}
in
   thread
      AllTags={FightScene Canvas Play Adv}
      {AllTagsToList AllTags LTagsAdv LTagsPlay}
      for _ in 1..25 do DT = 1000 div 40 in
	 {QTk.flush} 
	 {MoveFight LTagsAdv  ~1}
	 {MoveFight LTagsPlay  1}
	 {Delay DT}
      end
      B=unit
   end
   Fid
end