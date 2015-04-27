% This file will contain all the widget-containers used in this project
% each time with a brief description of what they do

declare
% This function will load a given image from the library and return it
% @pre: Name is a list of strings for a valid image:
%            ex: ["Bulboz" "_back"]
% @post: Returns a QTk image handler (nil in case of failure)
Lib = {QTk.loadImageLibrary "../LibImg.ozf"}
fun{LoadImage Name}
   Name2 = {Flatten Name}
in
   {Show {StringToAtom Name2}}
   try
      Img
      {Lib get(name:{StringToAtom Name2} image:Img)}
   in
      Img
   catch _ then {Show 'Error loading image'} nil 
   end
end
fun{Font Id} FONT=helvetica in
   case Id
   of none then
      {QTk.newFont font( family:FONT)}
   [] size(Size) then
      {QTk.newFont font( family:FONT size:Size)}
   [] type then
      {QTk.newFont font( family:FONT weight:bold)}
   [] type(Size) then
      {QTk.newFont font( family:FONT size:Size weight:bold)}
   else {Show 'Error on FONT!!'} {QTk.newFont font( family:FONT)}
   end
end

%%%%%%%%% ALL THE WIDGET HANDLES AND NAMES %%%%%%

MAPWIDGET
MAPCANVAS
% BUTTONS = buttons(starters:'3'(bulbasoz:_ charmandoz:_ oztirtle:_)
%		  fight:'4'(run:_ fight:_ capture:_ switch:_))
MAPHANDLES
MAPTAGS
PLACEHOLDER

%%%%%%% MAPWIDGET %%%%%%%%%%
proc{RedrawSquare Handle Ground}
   ColorGrass = c(38 133 30)
   ColorPath = c(49 025 05)
in
   if Ground==grass then {Handle set(fill:ColorGrass)}
   else {Handle set(fill:ColorPath)} end
end
proc{DrawTrainer Handle Dir}
   if Dir \= empty then
      {Handle 'raise'}
      {Handle set(image:{LoadImage ["Red_" {AtomToString Dir} "_still"]})}
   else {Handle lower} end
end
%@pre:  Draws the map given by the record read in File at once
%        and Canvash is te handle to the canvas
%@post: Returns a list of handles to be able to shift the map
fun{DrawMap Canvash Map MaxX MaxY}
   ColorGrass = c(38 133 30)
   ColorPath  = c(49 025 05)
   Color = color(0:ColorPath 1:ColorGrass)
   DX = 67 DXn = 66
   Tag={Canvash newTag($)}
   CanvasH = MAPCANVAS
   Handles = {MakeTuple 'maph' MAXY}
   TrainerHandles = {MakeTuple 'trainerh' MAXY}
   proc{DrawSquare index(X Y) MapHandles TrainerHandles}
      if Y>MaxY then skip
      else NewX NewY
	 ActX = 1+DX*(X-1)
	 ActY = 1+DX*(Y-1)
	 Handle
      in
	 {CanvasH create(rectangle ActX ActY ActX+DXn ActY+DXn
			 fill:ColorPath
			 tags:Tag handle:MapHandles.Y.X)}
	 {CanvasH create(image ActX+33 ActY+33
			 handle:TrainerHandles.Y.X)}
	 if X==MaxX then NewX=1 NewY=Y+1
	 else NewX=X+1 NewY=Y end
	 {DrawSquare index(NewX NewY) MapHandles TrainerHandles}
      end
   end
in
   for I in 1..MAXY do
      Handles.I = {MakeTuple 'maph' MAXX}
      TrainerHandles.I = {MakeTuple 'trainerh' MAXX} end
   {DrawSquare index(1 1) Handles TrainerHandles}
   tags(tag:Tag handles:Handles trainer:TrainerHandles)
end

%@pre: Shifts the map (decribed by the list of handles)
%       in the direction Dir
proc{ShiftMap Tag Dir}
   skip   
end

MAPWIDGET = td( canvas( height:470 width:470
			  handle:MAPCANVAS
			  bg:black
			)
		  handle:MAPHANDLES
		)

%%%%%%% TOPWIDGET %%%%%%%%%%
TopWidget  = td( canvas( height:470 width:470
			 handle:MAPCANVAS
			 bg:black
		       )
		 geometry:geometry(height:470 width:470)
		 resizable:resizable(width:false height:false)
	       )