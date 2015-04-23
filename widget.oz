% This file will contain all the widget-containers used in this project
% each time with a brief description of what they do

%declare
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

%%%%%%%%% ALL THE WIDGET HANDLES AND NAMES %%%%%%

WIDGETS = widgets(starters:_ map:_ fight:_ pokelist:_ lost:_ won:_)
CANVAS  =  canvas(starters:_ map:_ fight:_ fight2:_)
BUTTONS = buttons(starters:'3'(bulbasoz:_ charmandoz:_ oztirtle:_)
		  fight:'4'(run:_ fight:_ capture:_ switch:_))
HANDLES = handles(starters:_ map:_ fight:_ lost:_ won:_)
TAGS    =    tags(           map:_ fight:_ fight2:_)
PLACEHOLDER
%%%%%%%%% STARTWIDGET %%%%%%%%%%%

%creer un record avec couleur + type lies!!
% fun{StarterPokemoz Name}
%    Name2 = (Name.1+32)|Name.2
%    Widg = td(glue:nw
% 	     button( image:{LoadImage [Name "_full"]}
% 		     activebackground:c(0 0 255)
% 		     background:c(0 255 0)
% 		   )
% 	     button( text:Name
% 		     %action:proc{$}
% 		     %	       {Show {StringToAtom Name}#new}
% 		     %	    end
% 		     width:12
% 		     font:{Font type}
% 		     handle:BUTTONS.starters.{StringToAtom Name2}
% 		   )
% 	    )
% in
%    Widg
% end
% StartSpace = 15
% WIDGETS.starters = td( %lrspace(width:50)
% 		      label( init:"Choose your starter PokemOZ"
% 			     font:{Font type(25)})
% 		      lr( tdspace(width:StartSpace)
% 			  {StarterPokemoz "Bulbasoz"}
% 			  tdspace(width:StartSpace)
% 			  {StarterPokemoz "Oztirtle"}
% 			  tdspace(width:StartSpace)
% 			  {StarterPokemoz "Charmandoz"}
% 			  tdspace(width:StartSpace)
% 			)
% 		      handle:HANDLES.starters
% 		    )
%%%%%%% STARTWIDGET2 %%%%%%%

proc{StarterPokemoz}
   Canvash = CANVAS.starters
   Yim=200 Ytx=Yim+75
   {Canvash create(text 235 50 text:"Choose your PokemOz"
		   font:{Font type(25)})}
   Names = all("Bulbasoz" "Charmandoz" "Oztirtle")
   Atoms = all( bulbasoz   charmandoz   oztirtle )
   BgCol    = all(c(42 154 60) c(220 35 35) c(49 71 232))
   BgColSel = all(c(12  83 23) c(172 33  6) c(21 33 121))
   DXX = 150
in
   for I in 1..3 do
      {Show I}
      X=(I-1)*DXX
      Tag    = {Canvash newTag($)}
      Tagbis = {Canvash newTag($)}
   in
      %Drawing
      {Canvash create(rectangle 20+X Yim-65 150+X Yim+95
		      fill:BgCol.I tags:Tagbis)}
      {Canvash create(text text:Names.I font:{Font type(15)}
		      85+X Ytx width:130 tags:Tag fill:white)}
      {Canvash create(image image:{LoadImage [Names.I "_full"]}
		      85+X Yim tags:Tag)}
      %Binding
      {Tag bind(event:"<Enter>" action:proc{$}
					  {Tagbis set(fill:BgColSel.I)}
				       end)}
      {Tag bind(event:"<Leave>" action:proc{$}
					  {Tagbis set(fill:BgCol.I)}
				       end)}
      BUTTONS.starters.(Atoms.I) = Tag
   end
end
WIDGETS.starters = canvas( width:470 height:470 handle:HANDLES.starters
			   bg:white)
thread
   CANVAS.starters = HANDLES.starters
   {StarterPokemoz}
end


%%%%%%% MAPWIDGET %%%%%%%%%%

%@pre:  Draws the map given by the record read in File at once
%        and Canvash is te handle to the canvas
%@post: Returns a list of handles to be able to shift the map
fun{DrawMap Map MaxX MaxY}
   Canvash = CANVAS.map
   ColorGrass = c(38 133 30)
   ColorPath  = c(49 025 05)
   Color = color(0:ColorPath 1:ColorGrass)
   DX = 67 DXn = 66
   Tag={Canvash newTag($)}
   CanvasH = CANVAS.map
   proc{DrawSquare index(X Y)}
      if Y>MaxY then skip
      else NewX NewY 
	 ActX = 1+DX*(X-1)
	 ActY = 1+DX*(Y-1)
      in
	 {CanvasH create(rectangle ActX ActY ActX+DXn ActY+DXn
			 fill:Color.(Map.Y.X)
			 tags:Tag)}
	 if X==MaxX then NewX=1 NewY=Y+1
	 else NewX=X+1 NewY=Y end
	 {DrawSquare index(NewX NewY)}
      end
   end
in
   {DrawSquare index(1 1)}
   Tag
end

%@pre: Shifts the map (decribed by the list of handles)
%       in the direction Dir
proc{ShiftMap Tag Dir}
   skip   
end

WIDGETS.map = td( canvas( height:470 width:470
			  handle:CANVAS.map
			  bg:black
			)
		  handle:HANDLES.map
		)

%%%%%%% FIGHTWIDGET %%%%%%%%
proc{InitFightTags}
   Ch = CANVAS.fight
in
   TAGS.fight = 
   tags(plateau:plateau(disk({Ch newTag($)} {Ch newTag($)})
			pokemoz({Ch newTag($)} {Ch newTag($)}))
	attrib:attrib(text({Ch newTag($)} {Ch newTag($)})
		      bars(bar(act:{Ch newTag($)} {Ch newTag($)})
			   bar(act:{Ch newTag($)} {Ch newTag($)})))
	others:others({Ch newTag($)}))
   TAGS.fight2 = {CANVAS.fight2 newTag($)}
end
proc{DrawBar Act Max X0 Y0 Tag Tag2}
   W = 100
   H = 10
   Size = (W*Act) div Max
   CanvasH = CANVAS.fight
   Color
   Divi = {IntToFloat Size} / {IntToFloat W}
   if Divi < 0.2 then Color = red
   elseif Divi < 0.5 then Color = yellow
   else Color = green end
in
   {CanvasH create(rectangle X0 Y0 X0+W    Y0+H fill:white tags:Tag2)}
   {CanvasH create(rectangle X0 Y0 X0+Size Y0+H fill:Color tags:Tag)}
end
fun{FightScene Play Adv}
   Tags = TAGS.fight
   XST = 500
   CanvasH = CANVAS.fight
   proc{DrawImg}
      Disk  = {LoadImage "Fight_disk"}
      Im_pl = {LoadImage [Play.name "_back" ]}
      Im_ad = {LoadImage [Adv.name  "_front"]}
      TagD1 = Tags.plateau.1.1
      TagD2 = Tags.plateau.1.2
      TagP1 = Tags.plateau.2.1
      TagP2 = Tags.plateau.2.2
   in
      %                                    X     Y
      {CanvasH create(image image:Disk  345-XST  60 tags:TagD2)}
      {CanvasH create(image image:Im_ad 345-XST  45 tags:TagP2)}
      {CanvasH create(image image:Disk  135+XST 210 tags:TagD1)}
      {CanvasH create(image image:Im_pl 125+XST 143 tags:TagP1)}
   end
   proc{DrawAttr}
      Tag1 = Tags.attrib.1.1
      Tag2 = Tags.attrib.1.2
      HPlay = {Send Play.pid getHealth($)}
      HAdv  = {Send  Adv.pid getHealth($)}
      LPlay = {IntToString {Send Play.pid getLvl($)}}
      LAdv  = {IntToString {Send  Adv.pid getLvl($)}}
   in
      {CanvasH create(text 320+XST 150 text:Play.name font:{Font type(16)}
	  	      tags:Tag1)}
      {CanvasH create(text 160-XST  20 text:Adv.name  font:{Font type(16)}
		      tags:Tag2)}
      {CanvasH create(text 320+XST 190 text:{Append "Lvl" LPlay}
		      font:{Font type(15)} tags:Tag1)}
      {CanvasH create(text 160-XST  60 text:{Append "Lvl" LAdv}
		      font:{Font type(15)} tags:Tag2)}
      {DrawBar HPlay.act HPlay.max 270+XST 165
       Tags.attrib.2.1.act Tags.attrib.2.1.1}
      {DrawBar HAdv.act  HAdv.max  110-XST  35
       Tags.attrib.2.2.act Tags.attrib.2.2.1}
   end
in
   %{DrawImg}
  % {DrawAttr}
   {RedrawFight npc    Adv }
   {RedrawFight player Play}
   thread
      {CANVAS.fight2 create(image image:{LoadImage "bg_fight"} 235 45)}
      {CANVAS.fight2 create(text   text:"Choose your action" 235 45
			    font:{Font type(16)} tags:TAGS.fight2)}
   end
     
   Tags
end
proc{RedrawFight Person NewPkm}
   Xst = 500
   Tags = TAGS.fight
   CanvasH = CANVAS.fight
   proc{DrawImg}
      Disk  = {LoadImage "Fight_disk"}
      Img TagP TagD
      Ximg Xdisk Yimg Ydisk
      if Person == player then
	 Img = {LoadImage [NewPkm.name "_back" ]}
	 TagD = Tags.plateau.1.1
	 TagP = Tags.plateau.2.1
	 Ximg = 135+Xst  Xdisk = 125+Xst
	 Yimg = 143      Ydisk = 210
      else
	 Img = {LoadImage [NewPkm.name "_front" ]}
	 TagD = Tags.plateau.1.2
	 TagP = Tags.plateau.2.2
	 Ximg = 345-Xst  Xdisk = 345-Xst
	 Yimg = 45       Ydisk = 60
      end
   in
      {CanvasH create(image image:Disk  Xdisk  Ydisk tags:TagD)}
      {CanvasH create(image image:Img   Ximg  Yimg  tags:TagP)}
   end
   proc{DrawAttr}
      Tag  
      Tag2 
      Tag3 
      HP  = {Send NewPkm.pid getHealth($)}
      LVL = {IntToString {Send NewPkm.pid getLvl($)}}
      Xname Xlvl Xbar 
      Yname Ylvl Ybar
      if Person == player then
	 Xname = 320+Xst Xlvl = 320+Xst Xbar = 270+Xst
	 Yname = 150     Ylvl = 190     Ybar = 165
	 Tag  = Tags.attrib.1.1
	 Tag2 = Tags.attrib.2.1.act
	 Tag3 = Tags.attrib.2.1.1
      else
	 Xname = 160-Xst Xlvl = 160-Xst Xbar = 110-Xst
	 Yname = 20      Ylvl = 60      Ybar = 35
	 Tag = Tags.attrib.1.2
	 Tag2 = Tags.attrib.2.2.act
	 Tag3 = Tags.attrib.2.2.1
      end
   in
      {CanvasH create(text Xname Yname text:NewPkm.name font:{Font type(16)}
	  	      tags:Tag)}
      {CanvasH create(text Xlvl Ylvl text:{Append "Lvl" LVL}
		      font:{Font type(15)} tags:Tag)}
      {DrawBar HP.act HP.max Xbar Ybar Tag2 Tag3}
   end
in
   {DrawImg} {DrawAttr}
end

WIDGETS.fight = td( canvas( height:200 width:470
			    handle:CANVAS.fight
			    bg:white
			  )
		    canvas( height:90  width:470
			    handle:CANVAS.fight2
			  )
		    lr( tdspace(width:5)
			button(text:"FIGHT" font:{Font type(48)} width:6
			       handle:BUTTONS.fight.fight)
			tdspace(width:5)
			button(text:" RUN " font:{Font type(48)} width:6
			       handle:BUTTONS.fight.run)
			tdspace(width:5)
		      )
		    lr( tdspace(width:5)
			button(text:"SWIT." font:{Font type(48)} width:6
			       handle:BUTTONS.fight.switch)
			tdspace(width:5)
			button(text:"CAPT." font:{Font type(48)} width:6
			       handle:BUTTONS.fight.capture)
			tdspace(width:5)
		      )
		    lrspace(width:30)
		    handle:HANDLES.fight
		  )
%%%%%%% PokeList  %%%%%%%%
% Add number of alive pokemoz's to screen, maybe?
%Draws the pokemoz's of a trainer
proc{DrawPoke PlayL}
   Rec = {Send PlayL getAll($)}
   proc{DrawOne Play X Y}%X = [1 2] et Y = [1 2 3]
      %Draw the element
      %bind the event
      skip
   end
   proc{DrawEmpty X Y}
      skip
   end
in
   for X in 1..2 do
      for Y in 1..3 do Play =Rec.((X-1)*2+Y) in
	 skip
      end
   end
   %Draws button
   skip
end
WIDGETS.pokelist = canvas(height:470 width:470 handle:_)
%%%%%%% TOPWIDGET %%%%%%%%%%
TopWidget  = td( placeholder(handle:PLACEHOLDER)
		 geometry:geometry(height:470 width:470)
		 resizable:resizable(width:false height:false)
	       )

