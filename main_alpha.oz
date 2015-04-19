% This file will contain all the thread launches
declare
%%%% The GLOBAL Variables
[QTk]={Module.link ["x-oz://system/wp/QTk.ozf"]}
MAINPO  %The main portobject
PLAYER  %The player's trainer
WILD    %The wild pokemoz thread

WIDGETS %All the widgets' descriptions
CANVAS  %All the canvases' handles
BUTTONS %All the buttons' handles

MAPID

SPEED
DELAY
PROBABILITY
MAXX  = 7
MAXY  = 7

%%%% The IO functions (TODO import from seperate functor)
fun{ReadMap _}%should be replaced by 'Name' afterwards
   map(r(1 1 1 0 0 0 0)
       r(1 1 1 0 0 1 1)
       r(1 1 1 0 0 1 1)
       r(0 0 0 0 0 1 1)
       r(0 0 0 1 1 1 1)
       r(0 0 0 1 1 0 0)
       r(0 0 0 0 0 0 0))
end
fun{ReadEnnemies _}
   %List of Names with their start Coordinates
   nil
end
proc{BindEvents Window Input} %Input = {keys,autofight,
   if Input == keys then
      fun{GenerateMoveProc Dir}
	 proc{$}
	    if {Send MAINPO get($)} == map then
	       {Send PLAYER.pid move(Dir)}
	    else
	       skip
	    end
	 end
      end
   in
      {Window bind(event:"<Up>" action:{GenerateMoveProc up})}
      {Window bind(event:"<Left>" action:{GenerateMoveProc left})}
      {Window bind(event:"<Right>" action:{GenerateMoveProc right})}
      {Window bind(event:"<Down>" action:{GenerateMoveProc down})}
   else skip
   end
end
proc{SetSpeed X}
   SPEED = X
end
proc{SetDelay X}
   Delid = {NewPortObject X fun{$ Msg State}
			       case Msg
			       of set(Y) then Y
			       [] get(Y) then Y=State State end end}
in
   DELAY= delay(get:fun{$} {Send Delid get($)} end
		set:proc{$ X} {Send Delid set(X)} end)
end
proc{SetProb X}
   PROBABILITY = X % [0-100]
end

%%%%% The Imports
\insert 'widget.oz'
\insert 'port_object.oz'


%%%%%% Launching the main operations
Window = {QTk.build TopWidget}
{Window show}
MAINPO = {MAIN starters WIDGETS PLACEHOLDER _ HANDLES}


%%%%%% Binding the necessary Active Input
{Window bind(event:"<Escape>" action:proc{$}
					{Window close}
					{Application.exit 0}
				     end)}
for I in [bulbasoz charmandoz oztirtle] do
   {BUTTONS.starters.I bind(event:"<1>" action:proc{$}
						  {Send MAINPO makeTrainer(I)}
					       end)}
end
{BindEvents Window keys}
{SetSpeed 5}
{SetDelay 50}
{SetProb  65}