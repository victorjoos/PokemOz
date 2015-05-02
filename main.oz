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
   %Moved to ReadMap
   %MAXX = 7
   %MAXY = 7

   proc{BindEvents Input}
         Canvash = CANVAS.map
         fun{GenerateMoveProc Dir}
            proc{$}
         	   {Send PLAYER.pid move(Dir)}
            end
         end
      in
         if Input == keys then
            {Canvash bind(event:"<Up>" action:{GenerateMoveProc up})}
            {Canvash bind(event:"<Left>" action:{GenerateMoveProc left})}
            {Canvash bind(event:"<Right>" action:{GenerateMoveProc right})}
            {Canvash bind(event:"<Down>" action:{GenerateMoveProc down})}
            {Canvash bind(event:"<e>" action:proc{$}
                                                 thread {DrawPokeList status} end
                                                 {Send MAINPO set(pokelist)}
                                              end)}
         else skip
         end
   end
   proc{SetSpeed X}
      SPEED = X
   end
   proc{SetDelay X}
      Delid = {NewPortObject X fun{$ Msg State}
				  case Msg
				  of set(Y) then {Show set(Y)} Y
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
   Args = {Application.getArgs record('speed'(single char:&s type:int default:5)
				      'delay'(single char:&d type:int default:50)
				      'probability'(single char:&p type:int default:30)
				      'map'(single char:&m type:string default:"Map.txt"))}
in
   {Window show}
   MAINPO = {MAIN WIDGETS PLACEHOLDER Args.map HANDLES}


%%%%%% Binding the necessary Active Input

   {BindEvents keys}
   {SetSpeed Args.speed}
   {SetDelay Args.delay}
   {SetProb  Args.probability}

   %Has to be always bound even when in autofight mode
   {Window bind(event:"<Escape>" action:toplevel#close)}
   {Window bind(event:"<d>" action: proc{$} DelT={DELAY.get} X in
                                       {Show set#delay}
                                       if DelT >= 200 then X=50
                                       elseif DelT >= 150 then X=200
                                       elseif DelT >= 100 then X=150
                                       else X=100 end
                                       {DELAY.set X}
                                    end)}
   %For testing purposes!
   {Window bind(event:"<r>" action:proc{$} {Send PLAYER.poke refill} end)}
   {Window bind(event:"<p>" action:proc{$}
				                          {Send MAINPO set(map)}
				                      end)}
   {Window bind(event:"<o>" action:proc{$}
				                          {Send MAINPO set(fight)}
				                      end)}
end
