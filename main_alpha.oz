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
AI
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
fun{ReadEnemies _}
   %List of Names with their start Coordinates
   [npc("Red" delay:500 start:init(x:5 y:5) speed:5
	states:[turn(left) move(left) move(left) turn(right) move(right) move(right)]
   poke:[poke("Charmandoz" 5)])]
end
proc{BindEvents Window Input} %Input = {keys,autofight,..}
   if Input == keys then
      fun{GenerateMoveProc Dir}
      	 proc{$}
      	    if {Send MAINPO get($)} == map then
                {Show 'sent move'}
      	       {Send PLAYER.pid move(Dir)}
      	      % {Send AI move}
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
MAINPO = {MAIN starters WIDGETS PLACEHOLDER _ HANDLES}


%%%%%% Binding the necessary Active Input
{Window bind(event:"<Escape>" action:proc{$}
					{Window close}
					{Application.exit 0}
				     end)}

%AI={ArtificialPlayer pos(x:7 y:7) MAPID PLAYER.pid}
{BindEvents Window keys}
{SetSpeed 5}
{SetDelay 70}
{SetProb  0}% TODO: CORRIGER LA DOUBLE BATTLE ABSOLUMENT!!!!!
            %         => Revoir completement le systeme de declenchement
            %            des combats

% Just for testing purposes
{Window bind(event:"<3>" action:proc{$}
				   thread {DrawPokeList status} end
				   {Send MAINPO set(pokelist)}
				end)}
{Window bind(event:"<r>" action:proc{$} {Send PLAYER.poke refill} end)}
