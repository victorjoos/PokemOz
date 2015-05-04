functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   OS
   Browser

   PortDefinitions
   PortObject
   Widget
define
   % This file will contain all the thread launches
%%%% The GLOBAL Variables
   Show = System.show
   Browse = Browser.browse

   NewPortObject = PortDefinitions.port
   KeyPort = PortDefinitions.keyPort
   MAIN = PortObject.main

   TopWidget = Widget.topWidget
   PLACEHOLDER = Widget.placeholder
   HANDLES = Widget.handles
   DrawPokeList = Widget.drawPokeList
   MAINPO = Widget.mainPO
   KEYS = Widget.keys
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

   proc{BindEvents Input}
      Canvash = CANVAS.map
      fun{GenerateMoveProc Dir}
         proc{$}
      	   {Send PLAYER.pid move(Dir)}
         end
      end
      fun{GenSig Sig}
         proc{$} {Send KEYS Sig} end
      end
      MapButtons = buttons(up:{GenerateMoveProc up} down:{GenerateMoveProc down}
                  left:{GenerateMoveProc left} right:{GenerateMoveProc right}
                  a:proc{$}
                        {DrawPokeList status} {Send MAINPO set(pokelist)}
                      end)
   in
      KEYS = {KeyPort MapButtons}
      {Window bind(event:"<Up>" action:{GenSig up})}
      {Window bind(event:"<Left>" action:{GenSig left})}
      {Window bind(event:"<Right>" action:{GenSig right})}
      {Window bind(event:"<Down>" action:{GenSig down})}
      {Window bind(event:"<a>" action:{GenSig a})}
      if Input == auto then
         {Window bind(event:"<z>" action:{GenSig z})}
         {Window bind(event:"<Control-Shift-A>" action:{GenSig csa})}
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
				      'map'(single char:&m type:string default:"Map.txt")
				      'npc'(single char:&n type:string default:"Npc.txt")
				      'ai'(single char:&a type:bool default:false)
				      'autorun'(single char:&r type:bool default:false)
				      'autofight'(single char:&f type:bool default:false))}
   AIType
in
   {BindEvents keys}
   {Window show}
   if Args.ai then AIType=auto
   elseif Args.autofight then AIType=autofight
   elseif Args.autorun then AIType=autorun
   else AIType=none end
   MAINPO = {MAIN WIDGETS PLACEHOLDER Args.map Args.npc AIType HANDLES Window}


%%%%%% Binding the necessary Active Input

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
   {Window bind(event:"<t>" action:proc{$}
                           {Send {Send PLAYER.poke getFirst($)}.pid damage(40 _)}
                        end)}
   {Window bind(event:"<e>" action:proc{$}
                           {Send PLAYER.pid reset(_)}
                        end)}
end
