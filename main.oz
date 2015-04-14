% This file will contain all the thread launches
functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   Widget
   PortObject
   AnimatePort
   Application
define
% Function that creates a trainer
%@post: returns the id of the PlayerController
   fun{CreateTrainer Name X0 Y0 Speed Mapid Canvash}
      Anid = {AnimatePort.trainer Canvash X0-1 Y0-1 Speed Name}
      Trid = {PortObject.trainer pos(x:X0 y:Y0) Anid}
   in
      {PortObject.trainerController Mapid Trid Speed}
   end
   
   Window = {QTk.build Widget.topWidget}
   {Window show}
   {Window bind(event:"<Escape>" action:proc{$}
					   {Window close}
					   {Application.exit 0}
					end)}
   Map = map(r(1 1 1 0 0 0 0)
	     r(1 1 1 0 0 1 1)
	     r(1 1 1 0 0 1 1)
	     r(0 0 0 0 0 1 1)
	     r(0 0 0 1 1 1 1)
	     r(0 0 0 1 1 0 0)
	     r(0 0 0 0 0 0 0))
   _={Widget.drawMap Widget.canvasH Map 7 7 $}
   MAPID  = {PortObject.mapController}
   PLAYER = {CreateTrainer "Red" 6 6 PortObject.speed MAPID Widget.canvasH}
   fun{GenerateMoveProc Dir}
      proc{$}
	 {Send PLAYER move(Dir)}
      end
   end
   {Window bind(event:"<Up>" action:{GenerateMoveProc up})}
   {Window bind(event:"<Left>" action:{GenerateMoveProc left})}
   {Window bind(event:"<Right>" action:{GenerateMoveProc right})}
   {Window bind(event:"<Down>" action:{GenerateMoveProc down})}
end