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

RECTHANDLES

SPEED
DELAY
PROBABILITY
MAXX  = 7
MAXY  = 7
MapName = 'map.txt'
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

proc{BindEvents MapTiles RectHandles} %Input = {keys,autofight,
   fun{GenerateProc TileId}
      proc{$}
	 {Send TileId switch}
      end
   end
in
   {Show bindingEvents}
   for J in 1..MAXX do
      for I in 1..MAXY do
	 {RectHandles.J.I bind(event:"<1>" action:{GenerateProc MapTiles.J.I})}
      end
   end
end

%%%%% The Imports
\insert 'editorwidget.oz'
\insert 'editorports.oz'

%%%%%% Launching the main operations
Window = {QTk.build TopWidget}
{Window show}
% MAINPO = {MAIN starters WIDGETS PLACEHOLDER _ HANDLES}
Map = {ReadMap MapName}
tags(tag:_ handles:RECTHANDLES) = {DrawMap MAPCANVAS Map MAXX MAXY}

%%%%%% Creates the whole map tiles
MAPID#MAPTILES = {MapEditor}
%%%%%% Binding the necessary Active Input
{Window bind(event:"<Escape>" action:proc{$}
					{Window close}
					{Application.exit 0}
				     end)}
{Window bind(event:"s" action:proc{$}
				 {Send MAPID save('maptest.txt')}
			      end)}
{Window bind(event:"l" action:proc{$}
				 {Send MAPID load('maptest.txt')}
			      end)}
{BindEvents MAPTILES RECTHANDLES}