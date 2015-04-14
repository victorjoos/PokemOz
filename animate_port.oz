functor
import
   System
   PortObject
   Widget
export
   Trainer
define

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
   
   fun{Trainer Canvash X0 Y0 Speed Name}
      proc{Animate Dir DT DX Ind Mod DMod} Sup Mod2 in
	 if Mod \= 0 then Sup = DMod Mod2=Mod-DMod else Sup = 0 Mod2=0 end
	 if Ind < 8 then
	    Next = ((Ind) mod 4)+1
	 in
	    {System.show Next}
	    {Delay DT}
	    {TagIm set(image:{Widget.loadImage [Name "_" Dir STATES.Next]})}
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
      Tid   = {PortObject.timer}
      TagIm = {Canvash newTag($)}
      Anid  = {PortObject.newPortObjectMinor
	       proc{$ Msg}
		  case Msg
		  of move(Dir) then
		     Numb = 8
		     Dir2 = {AtomToString Dir}
		     % TODO(victor) : change delay to function var or in a defined global tuple
		     DT    = (PortObject.delay*Speed) div Numb
		     DX    = {PortObject.getDir Dir}
		     Delta = delta(x:(DX.x*67) div Numb y:(DX.y*67) div Numb)
		     Mod
		     if DX.x == 0 then Mod = (DX.y*67) mod Numb
		     else              Mod = (DX.x*67) mod Numb end
		     DMod  = {PortObject.getDirSide Dir} 
		  in
		     {Animate Dir2 DT Delta 0 Mod DMod}
		  [] turn(Dir) then Dir2 = {AtomToString Dir} in
		     {TagIm set(image:{Widget.loadImage [Name "_" Dir2 "_still"]})}
		  end
	       end}
   in
   %TODO : draw initial state
      {Canvash create(image image:{Widget.loadImage [Name "_up" "_still"]}
		      X0*67+33 Y0*67+33 tags:TagIm)}
      Anid
   end
end