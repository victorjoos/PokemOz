functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   OS

   PortDefinitions
   PortObject
   Widget
define
   % This file will contain all the thread launches
%%%% The GLOBAL Variables
   Show = System.show

   NewPortObject = PortDefinitions.port
   MAIN = PortObject.main

   TopWidget = Widget.topWidget
   PLACEHOLDER = Widget.placeholder
   HANDLES = Widget.handles
   DrawPokeList = Widget.drawPokeList
   MAINPO = Widget.mainPO
   PLAYER = Widget.player
   WILD = Widget.wild
   LISTAI = Widget.listAI
   WIDGETS = Widget.widgets
   CANVAS = Widget.canvas
   MAPID = Widget.mapID
   SPEED = Widget.speed
   DELAY = Widget.delay
   PROBABILITY = Widget.probability
   MAXX = Widget.maxX
   MAXY = Widget.maxY
   
   MAXX = 7
   MAXY = 7
   
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
%%%%%% Launching the main operations
   Window = {QTk.build TopWidget}
in
   {Window show}
   MAINPO = {MAIN WIDGETS PLACEHOLDER _ HANDLES}


%%%%%% Binding the necessary Active Input
   {Window bind(event:"<Escape>" action:proc{$}
					   {Window close}
					   {Application.exit 0}
					end)}

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
end