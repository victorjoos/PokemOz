% This file will contain all the widget-containers used in this project
% each time with a brief description of what they do
functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
export
   LoadImage
   DrawMap
   canvasH: CANVASH
   TopWidget
   ExitWindow
define
   ExitWindow
% This function will load a given image from the library and return it
% @pre: Name is a list of strings for a valid image:
%            ex: ["Bulboz" "_back"]
% @post: Returns a QTk image handler (nil in case of failure)
   Lib = {QTk.loadImageLibrary "LibImg.ozf"}
   {System.show ok}
   fun{LoadImage Name}
      Name2 = {Flatten Name}
   in
      try
	 Img
	 {Lib get(name:{StringToAtom Name2} image:Img)}
      in
	 Img
      catch _ then {System.show 'Error loading image'} nil 
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
      else {System.show 'Error on FONT!!'} {QTk.newFont font( family:FONT)}
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
				  {System.show {StringToAtom Name}#new}
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
					   {System.show 'setYellow'}
					   {Tag1 set(fill:yellow)}
					end)}
      {Tag1 bind(event:"<Leave>" action:proc{$}
					   {System.show 'setGreen'}
					   {Tag1 set(fill:green)}
					end)}
  
      {Tag2 bind(event:"<Enter>" action:proc{$}
					   {System.show 'setYellow'}
					   {Tag1 set(fill:yellow)}
					end)}
      {Tag2 bind(event:"<Leave>" action:proc{$}
					   {System.show 'setGreen'}
					   {Tag1 set(fill:green)}
					end)}
      {Tag3 bind(event:"<Enter>" action:proc{$}
					   {System.show 'setYellow'}
					   {Tag1 set(fill:yellow)}
					end)}
      {Tag3 bind(event:"<Leave>" action:proc{$}
					   {System.show 'setGreen'}
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
   fun{FightScene Canvash}
      fun{DrawImg}
	 nil
      end
      fun{DrawName}
	 nil
      end
   in
      nil
   end
   FIGHTH F_CANVASH
   FightWidget = td( canvas( height:350 width:470
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
		       MapWidget
		       handle:PLACEH)
		    geometry:geometry(height:470 width:470)
		    resizable:resizable(width:false height:false)
		    return:ExitWindow
		  )
end