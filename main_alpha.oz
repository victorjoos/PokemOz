% This file will contain all the thread launches
declare
%%%% The GLOBAL Variables
%[QTk]={Module.link ['/etinfo/users/2014/vanderschuea/Downloads/Mozart/mozart/cache/x-oz/system/wp/QTk.ozf']}
[QTk]={Module.link ["x-oz://system/wp/QTk.ozf"]}

MAINPO  %The main portobject
PLAYER  %The player's trainer
WILD    %The wild pokemoz thread
LISTAI  %List of all the enenmy ai's

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
proc{BindEvents Window Input} %Input = {keys,autofight,..}
   if Input == keys then
      fun{GenerateMoveProc Dir}
      	 proc{$}
      	    if {Send MAINPO get($)} == map then
                {Show 'sent move'}
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
{OS.srand 0}
%%%%% The Imports
\insert 'definitions_port.oz'
\insert 'widget.oz'
\insert 'AI.oz'
\insert 'port_object.oz'

%%%%%% Launching the main operations
Window = {QTk.build TopWidget}
{Window show}
MAINPO = {MAIN WIDGETS PLACEHOLDER _ HANDLES}


%%%%%% Binding the necessary Active Input
{Window bind(event:"<Escape>" action:proc{$}
					{Window close}
					{Application.exit 0}
				     end)}

{BindEvents Window keys}
{SetSpeed 5}
{SetDelay 40}
{SetProb  0}
% Just for testing purposes
{Window bind(event:"<3>" action:proc{$}
				   thread {DrawPokeList status} end
				   {Send MAINPO set(pokelist)}
				end)}
{Window bind(event:"<r>" action:proc{$} {Send PLAYER.poke refill} end)}
