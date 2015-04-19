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

WIDGETS = widgets(starters:_ map:_ fight:_ lost:_ won:_ )
CANVAS  =  canvas(           map:_ fight:_)
BUTTONS = buttons(starters:'3'(bulbasoz:_ charmandoz:_ oztirtle:_)
		  fight:'2'(run:_ fight:_))
HANDLES = handles(starters:_ map:_ fight:_ lost:_ won:_)
TAGS    =    tags(           map:_ fight:_)
PLACEHOLDER
%%%%%%%%% STARTWIDGET %%%%%%%%%%%

%creer un record avec couleur + type lies!!
fun{StarterPokemoz Name}
   Name2 = (Name.1+32)|Name.2
   Widg = td(glue:nw
	     button( image:{LoadImage [Name "_full"]}
		     activebackground:c(0 0 255)
		     background:c(0 255 0)
		   )
	     button( text:Name
		     %action:proc{$}
		     %	       {Show {StringToAtom Name}#new}
		     %	    end
		     width:12
		     font:{Font type}
		     handle:BUTTONS.starters.{StringToAtom Name2}
		   )
	    )
in
   Widg
end
StartSpace = 15
WIDGETS.starters = td( %lrspace(width:50)
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
		      handle:HANDLES.starters
		    )
%%%%%%% STARTWIDGET2 %%%%%%%

% proc{Starter Canvash} Yim=200 Ytx=Yim+75 Tag1 Tag2 Tag3 Tag4 in 
%    {Canvash create(text 235 50 text:"Choose your PokemOz"
% 		   font:{Font type(25)})}
%    Tag1={Canvash newTag($)}
%    Tag2={Canvash newTag($)}
%    Tag3={Canvash newTag($)}
%    Tag4={Canvash newTag($)}
%    {Canvash create(rectangle 20 Yim-65 150 Yim+95 fill:green tags:Tag1)}
   
%    {Canvash create(text text:"Bulbasoz"   font:{Font type} 85  Ytx tags:Tag2)}
%    {Canvash create(text text:"Oztirtle"   font:{Font type} 235 Ytx)}
%    {Canvash create(text text:"Charmandoz" font:{Font type} 385 Ytx)}
%    {Canvash create(image image:{LoadImage "Bulbasoz_full"}   85  Yim tags:Tag3)}
%    {Canvash create(image image:{LoadImage "Oztirtle_full"}   235 Yim)}
%    {Canvash create(image image:{LoadImage "Charmandoz_full"} 385 Yim)}

%    % {Canvash create(rectangle 15 Yim-70 155 Yim+100 tags:Tag1)}


%     {Tag1 bind(event:"<Enter>" action:proc{$}
% 					 {Show 'setYellow'}
% 					 {Tag1 set(fill:yellow)}
% 				      end)}
%    {Tag1 bind(event:"<Leave>" action:proc{$}
% 					{Show 'setGreen'}
% 					{Tag1 set(fill:green)}
% 				     end)}
  
%    {Tag2 bind(event:"<Enter>" action:proc{$}
% 					{Show 'setYellow'}
% 					{Tag1 set(fill:yellow)}
% 				     end)}
%    {Tag2 bind(event:"<Leave>" action:proc{$}
% 					{Show 'setGreen'}
% 					{Tag1 set(fill:green)}
% 				     end)}
%    {Tag3 bind(event:"<Enter>" action:proc{$}
% 					{Show 'setYellow'}
% 					{Tag1 set(fill:yellow)}
% 				     end)}
%    {Tag3 bind(event:"<Leave>" action:proc{$}
% 					{Show 'setGreen'}
% 					{Tag1 set(fill:green)}
% 				     end)}
% end
% STARTH2 CANVASST
% StartWidget2 = canvas( width:470 height:470 handle:CANVASST
% 		       bg:white)



%%%%%%% MAPWIDGET %%%%%%%%%%

%@pre:  Draws the map given by the record read in File at once
%        and Canvash is te handle to the canvas
%@post: Returns a list of handles to be able to shift the map
fun{DrawMap Canvash Map MaxX MaxY}
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
			pokemoz( {Ch newTag($)} {Ch newTag($)}))
	attrib:attrib(text({Ch newTag($)} {Ch newTag($)})
		      bars(bar(act:{Ch newTag($)} {Ch newTag($)})
			   bar(act:{Ch newTag($)} {Ch newTag($)})))
	others:others({Ch newTag($)}))
end
proc{DrawBar Act Max X0 Y0 Tag Tag2}
   W = 100
   H = 10
   Size = (W*Act) div Max
   CanvasH = CANVAS.fight
in
   {CanvasH create(rectangle X0 Y0 X0+W    Y0+H fill:white tags:Tag2)}
   {CanvasH  create(rectangle X0 Y0 X0+Size Y0+H fill:green tags:Tag)}
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
      %                                 X      Y
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
   in
      {CanvasH create(text 320+XST 165 text:Play.name font:{Font type(16)}
		      tags:Tag1)}
      {CanvasH create(text 160-XST  20 text:Adv.name  font:{Font type(16)}
		      tags:Tag2)}
      {DrawBar HPlay.act HPlay.max 270+XST 180
       Tags.attrib.2.1.act Tags.attrib.2.1.1}
      {DrawBar HAdv.act  HAdv.max  110-XST  35
       Tags.attrib.2.2.act Tags.attrib.2.2.1}
   end
in
   {DrawImg}
   {DrawAttr}
   Tags
end

WIDGETS.fight = td( canvas( height:200 width:470
			    handle:CANVAS.fight
			    bg:white
			  )
		    lrspace(width:15)
		    lr( tdspace(width:5)
			button(text:"FIGHT" font:{Font type(48)} width:6
			       handle:BUTTONS.fight.fight)
			tdspace(width:5)
			button(text:" RUN " font:{Font type(48)} width:6
			       handle:BUTTONS.fight.run)
			tdspace(width:5)
		      )
		    lrspace(width:30)
		    handle:HANDLES.fight
		  )

%%%%%%% TOPWIDGET %%%%%%%%%%
TopWidget  = td( placeholder(handle:PLACEHOLDER)
		 geometry:geometry(height:470 width:470)
		 resizable:resizable(width:false height:false)
	       )

