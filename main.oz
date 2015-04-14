% This file will contain all the thread launches
declare
[QTk]={Module.link ["x-oz://system/wp/QTk.ozf"]}
\insert 'widget.oz'
\insert 'port_object.oz'
%\insert 'animate_port.oz'

Window = {QTk.build TopWidget}
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
_={DrawMap CANVASH Map 7 7 $}
MAPID  = {MapController}
PLAYER = {CreateTrainer "Red" 6 6 SPEED MAPID CANVASH}
fun{GenerateMoveProc Dir}
   proc{$}
      {Send PLAYER move(Dir)}
   end
end
{Window bind(event:"<Up>" action:{GenerateMoveProc up})}
{Window bind(event:"<Left>" action:{GenerateMoveProc left})}
{Window bind(event:"<Right>" action:{GenerateMoveProc right})}
{Window bind(event:"<Down>" action:{GenerateMoveProc down})}

