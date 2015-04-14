% This file will contain all the widget-containers used in this project
% each time with a brief description of what they do

declare
% This function will load a given image from the library and return it
% @pre: Name is a list of strings for a valid image:
%            ex: ["Bulboz" "_back"]
% @post: Returns a QTk image handler (nil in case of failure)
Lib = {QTk.loadImageLibrary "LibImg.ozf"}
{Show ok}
fun{LoadImage Name}
   Name2 = {Flatten Name}
in
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


%%%%%%%%% STARTWIDGET %%%%%%%%%%%

%creer un record avec couleur + type lies!!
fun{StarterPokemoz Name}
   Widg = td(glue:nw
	     button( image:{LoadImage [Name "_full"]}
		     activebackground:c(0 0 255)
		     background:c(0 255 0)
		   )
	     button( text:Name
		     action:proc{$}
			       {Show {StringToAtom Name}#new}
			    end
		     width:12
		     font:{Font type}
		   )
	    )
   
in
   Widg
end
STARTH
StartSpace = 15
StartWidget = td( %lrspace(width:50)
		  label( init:"Choose your starter PokemOZ"
			 font:{Font type(25)})
		  lr( tdspace(width:StartSpace)
		      {StarterPokemoz "Bulbasoz"}
		      tdspace(width:StartSpace)
		      {StarterPokemoz "Oztirtle"}
		      tdspace(width:StartSpace)
		      {StarterPokemoz "Charmandoz"}
		      tdspace(width:StartSpace)
		    )
		  handle:STARTH
		)
%%%%%%% STARTWIDGET2 %%%%%%%

proc{Starter Canvash} Yim=200 Ytx=Yim+75 Tag1 Tag2 Tag3 Tag4 in 
   {Canvash create(text 235 50 text:"Choose your PokemOz"
		   font:{Font type(25)})}
   Tag1={Canvash newTag($)}
   Tag2={Canvash newTag($)}
   Tag3={Canvash newTag($)}
   Tag4={Canvash newTag($)}
   {Canvash create(rectangle 20 Yim-65 150 Yim+95 fill:green tags:Tag1)}
   
   {Canvash create(text text:"Bulbasoz"   font:{Font type} 85  Ytx tags:Tag2)}
   {Canvash create(text text:"Oztirtle"   font:{Font type} 235 Ytx)}
   {Canvash create(text text:"Charmandoz" font:{Font type} 385 Ytx)}
   {Canvash create(image image:{LoadImage "Bulbasoz_full"}   85  Yim tags:Tag3)}
   {Canvash create(image image:{LoadImage "Oztirtle_full"}   235 Yim)}
   {Canvash create(image image:{LoadImage "Charmandoz_full"} 385 Yim)}

   % {Canvash create(rectangle 15 Yim-70 155 Yim+100 tags:Tag1)}


    {Tag1 bind(event:"<Enter>" action:proc{$}
					 {Show 'setYellow'}
					 {Tag1 set(fill:yellow)}
				      end)}
   {Tag1 bind(event:"<Leave>" action:proc{$}
					{Show 'setGreen'}
					{Tag1 set(fill:green)}
				     end)}
  
   {Tag2 bind(event:"<Enter>" action:proc{$}
					{Show 'setYellow'}
					{Tag1 set(fill:yellow)}
				     end)}
   {Tag2 bind(event:"<Leave>" action:proc{$}
					{Show 'setGreen'}
					{Tag1 set(fill:green)}
				     end)}
   {Tag3 bind(event:"<Enter>" action:proc{$}
					{Show 'setYellow'}
					{Tag1 set(fill:yellow)}
				     end)}
   {Tag3 bind(event:"<Leave>" action:proc{$}
					{Show 'setGreen'}
					{Tag1 set(fill:green)}
				     end)}
end
STARTH2 CANVASST
StartWidget2 = canvas( width:470 height:470 handle:CANVASST
		       bg:white)



%%%%%%% MAPWIDGET %%%%%%%%%%

%@pre:  Draws the map given by the record read in File at once
%        and Canvash is te handle to the canvas
%@post: Returns a list of handles to be able to shift the map
fun{DrawMap Canvash Map MaxX MaxY}
   ColorGrass = c(38 133 30)
   ColorPath  = c(49 025 05)
   Color = color(0:ColorPath 1:ColorGrass)
   DX = 67 DXn = 66
   fun{DrawSquare index(X Y)} 
      if Y>MaxY then nil
      else NewX NewY Tag={Canvash newTag($)}
	 ActX = 1+DX*(X-1)
	 ActY = 1+DX*(Y-1)
      in
	 {Canvash create(rectangle ActX ActY ActX+DXn ActY+DXn
			 fill:Color.(Map.Y.X)
			 tags:Tag)}
	 if X==MaxX then NewX=1 NewY=Y+1
	 else NewX=X+1 NewY=Y end
	 Tag|{DrawSquare index(NewX NewY)}
      end
   end
in
   {DrawSquare index(1 1)}
end

%@pre: Shifts the map (decribed by the list of handles)
%       in the direction Dir
proc{ShiftMap Handles Dir}
   skip   
end
MAPH CANVASH
MapWidget = td( canvas( height:470 width:470
		        handle:CANVASH
		        bg:black
		      )
		handle:MAPH
	      )

%%%%%%% FIGHTWIDGET %%%%%%%%
fun{DrawBar Canvas Act Max X0 Y0}
   Tag ={Canvas newTag($)}
   Tag2={Canvas newTag($)}
   W = 100
   H = 10
   Size = (W*Act) div Max
in
   {Canvas create(rectangle X0 Y0 X0+W    Y0+H fill:white tags:Tag2)}
   {Canvas create(rectangle X0 Y0 X0+Size Y0+H fill:green tags:Tag)}
   rect(Tag Tag2)
end
fun{FightScene Canvash Play Adv }
   fun{DrawImg}
      Disk  = {LoadImage "Fight_disk"}
      Im_pl = {LoadImage [Play.name "_back" ]}
      Im_ad = {LoadImage [Adv.name  "_front"]}
      TagD1 = {Canvash newTag($)}
      TagD2 = {Canvash newTag($)}
      TagP1 = {Canvash newTag($)}
      TagP2 = {Canvash newTag($)}
   in
      %                                   X          Y 
      {Canvash create(image image:Disk  40+95        210 tags:TagD1)}
      {Canvash create(image image:Disk  470-40-85     60 tags:TagD2)}
      {Canvash create(image image:Im_pl 40+85     200-57 tags:TagP1)}
      {Canvash create(image image:Im_ad 470-40-85     45 tags:TagP2)}
      pokemoz(diskPl:TagD1 diskAd:TagD2 player:TagP1 advers:TagP2)
   end
   fun{DrawAttr}
      Tag1 = {Canvash newTag($)}
      Tag2 = {Canvash newTag($)}
      Bar1 Bar2
   in
      {Canvash create(text 320 200-35 text:Play.name font:{Font type(16)}
		      tags:Tag1)}
      {Canvash create(text 160     20 text:Adv.name  font:{Font type(16)}
		      tags:Tag2)}
      Bar1={DrawBar Canvash Play.health.1 Play.health.2 270 200-20}
      Bar2={DrawBar Canvash Adv.health.1  Adv.health.2  110     35}
      tags(text(Tag1 Tag2) bars(Bar1 Bar2))
   end
in
   tags(poke:{DrawImg} attrib:{DrawAttr})
end
FIGHTH F_CANVASH
FightWidget = td( canvas( height:200 width:470
			  handle:F_CANVASH
			  bg:white
			)
		  lrspace(width:15)
		  lr( tdspace(width:5)
		      button(text:"FIGHT" font:{Font type(48)} width:6)
		      tdspace(width:5)
		      button(text:" RUN " font:{Font type(48)} width:6)
		      tdspace(width:5)
		    )
		  lrspace(width:30)
		  handle:FIGHTH
		)

%%%%%%% TOPWIDGET %%%%%%%%%%
PLACEH
TopWidget  = td( placeholder(
		    %MapWidget
		    FightWidget
		    handle:PLACEH)
		 geometry:geometry(height:470 width:470)
		 resizable:resizable(width:false height:false)
	       )

