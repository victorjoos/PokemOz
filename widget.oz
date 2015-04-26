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
proc{BindToList LTags LEvent Proc}
   proc{Help LTags Event}
      case LTags of nil then skip
      [] H|T then {H bind(event:Event action:Proc)} {Help T Event}
      end
   end
in
   case LEvent of nil then skip
   [] H|T then {Help LTags H} {BindToList LTags T Proc}
   end
end

%%%%%%%%% ALL THE WIDGET HANDLES AND NAMES %%%%%%

WIDGETS = widgets(starters:_ map:_ fight:_ pokelist:_ lost:_ won:_)
CANVAS  =  canvas(starters:_ map:_ fight:_ fight2:_ pokelist:_)
BUTTONS = buttons(starters:'3'(bulbasoz:_ charmandoz:_ oztirtle:_)
		  fight:'4'(run:_ fight:_ capture:_ switch:_))
HANDLES = handles(starters:_ map:_ fight:_ pokelist:_ lost:_ won:_)
TAGS    =    tags(           map:_ fight:_ fight2:_ pokelist:_)
PLACEHOLDER
%%%%%%% STARTWIDGET %%%%%%%

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
   Arrows = {GetArrows 3 1}
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
      BUTTONS.starters.(Atoms.I) = Tagbis
   end

   {Canvash getFocus(force:true)}
   local
      Buttons = BUTTONS.starters
      fun{GenProc Dir}
	 proc{$}
	    OldX = {Send Arrows get($ _)}
	    NewX = {Send Arrows Dir($ _)}
	 in
	    {Buttons.(Atoms.OldX) set(fill:BgCol.OldX)}
	    {Buttons.(Atoms.NewX) set(fill:BgColSel.NewX)}
	 end
      end
   in
      {Buttons.(Atoms.1) set(fill:BgColSel.1)}
      {Canvash bind(event:"<Up>" action:{GenProc right})}
      {Canvash bind(event:"<Left>" action:{GenProc left})}
      {Canvash bind(event:"<Right>" action:{GenProc right})}
      {Canvash bind(event:"<Down>" action:{GenProc left})}
      {Canvash bind(event:"<a>" action:proc{$}
					  Starter =
					  Atoms.{Send Arrows get($ _)}
				       in
					  {Send Arrows kill}
					  {Send MAINPO makeTrainer(Starter)}
				       end)}
   end
end
WIDGETS.starters = canvas( width:470 height:470 handle:HANDLES.starters
			   bg:white)
thread CANVAS.starters = HANDLES.starters end


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
	others:others({Ch newTag($)})
	ball:{Ch newTag($)})
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
in
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
%Draws the pokemoz's of a trainer in the list
proc{InitPokeTags}
   Canvash = CANVAS.pokelist
in
   TAGS.pokelist = tags(1:tags(1:_ 2:_)
			2:tags(1:_ 2:_)
			3:tags(1:_ 2:_)
			back:tags({Canvash newTag($)}
				  bis:{Canvash newTag($)}))
    for X in 1..2 do
       for Y in 1..3 do Tag = TAGS.pokelist.Y.X in
	  Tag = tags({Canvash newTag($)} bis:{Canvash newTag($)})
       end
    end   
end
proc{DeletePokelistTags}
    Tag = TAGS.pokelist.back
   {Tag.1 delete} {Tag.bis delete}
in
    for X in 1..2 do
       for Y in 1..3 do Tag = TAGS.pokelist.Y.X in
	  {Tag.1 delete} {Tag.bis delete}
       end
    end
end

proc{DrawPokeList Event}% Event = status or fight(X) or dead(X)
   %For binding
   Arrows = {GetArrows 3 3}
   Buttons = all(1:x(1:button(onclick:_ onselect:_ ondeselect:_)
		     2:button(onclick:_ onselect:_ ondeselect:_)
		     3:button(onclick:_ onselect:_ ondeselect:_))
		 2:x(1:button(onclick:_ onselect:_ ondeselect:_)
		     2:button(onclick:_ onselect:_ ondeselect:_)
		     3:button(onclick:_ onselect:_ ondeselect:_))
		 3:x(1:button(onclick:_ onselect:_ ondeselect:_)
		     2:button(onclick:_ onselect:_ ondeselect:_)
		     3:button(onclick:_ onselect:_ ondeselect:_)))
   
   PlayL = PLAYER.poke
   First = {Send PlayL getFirst($)}
   Rec = {Send PlayL getAll($)}
   Canvash = CANVAS.pokelist
   AllTags = TAGS.pokelist
   BgCol    = all(grass:c(42 154 60) fire:c(220 35 35) water:c(49 71 232))
   BgColSel = all(grass:c(12  83 23) fire:c(172 33  6) water:c(21 33 121))
   proc{DrawMiniBar X Y Div Color Tag} %Div=_(act:act max:max)
      DX = 90
      DY = 15
      DDX = (Div.act*DX) div (Div.max)
   in
      {Canvash create(rectangle X Y X+DX  Y+DY tags:Tag)}
      {Canvash create(rectangle X Y X+DDX Y+DY fill:Color tags:Tag)}
   end
   proc{DrawOne X Y Play}%X = [1 2] et Y = [1 2 3]
      XX = 10+(X-1)*190
      YY = 20+(Y-1)*150
      Tag = AllTags.Y.X.1
      Tagbis = AllTags.Y.X.bis
      Color = c(BgCol.(Play.type) BgColSel.(Play.type))
   in
      %Draw the element
      {Canvash create(rectangle XX YY XX+180 YY+130 fill:Color.1
		      tags:Tagbis)}
      {Canvash create(image image:{LoadImage [Play.name "_front"]}
		      XX+40 YY+80 tags:Tag)}
      if Play == First then
	 {Canvash create(image image:{LoadImage "leader"}
			 XX+65 YY+100 tags:Tag)}
      end
      {Canvash create(text text:{Flatten [Play.name " Lvl "
					  {IntToString
					   {Send Play.pid getLvl($)}}]}
		      XX+90 YY+15 fill:white font:{Font type(15)} tags:Tag)}
      {Canvash create(text text:"HEALTH" XX+130 YY+42
		      fill:white font:{Font type(16)} tags:Tag)}
      {DrawMiniBar XX+85 YY+58 {Send Play.pid getHealth($)} red Tag}
      {Canvash create(text text:"EXP" XX+130 YY+85
		      fill:white font:{Font type(16)} tags:Tag)}
      {DrawMiniBar XX+85 YY+100 {Send Play.pid getExp($)} yellow Tag}
      %bind the events
      Buttons.Y.X.ondeselect = proc{$} {Tagbis set(fill:Color.1)} end
      Buttons.Y.X.onselect   = proc{$} {Tagbis set(fill:Color.2)} end
      Buttons.Y.X.onclick    = proc{$}
				  if Event == status then 
				     B={Send PlayL
					switchFirst((Y-1)*2+X $)}
				     {Wait B}
				  in
				     {Send MAINPO set(map)}
				  else
				     if {Send Play.pid getHealth($)}.act
					> 0 then
					Event.1 = Play
					{DeletePokelistTags}
					{Send MAINPO set(fight)}
				     else
					Event.1 = none
				     end
				  end
			       end
   end
   proc{DrawEmpty X Y}
      XX = 10+(X-1)*190
      YY = 20+(Y-1)*150
      Tagbis = AllTags.Y.X.bis
      Color = c(black c(74 74 82))
   in
      {Canvash create(rectangle XX YY XX+180 YY+130 fill:Color.1
		      tags:Tagbis)}
      {Canvash create(text text:"EMPTY" XX+90 YY+65
		      fill:white font:{Font type(20)})}
      Buttons.Y.X.ondeselect = proc{$} {Tagbis set(fill:Color.1)} end
      Buttons.Y.X.onselect   = proc{$} {Tagbis set(fill:Color.2)} end
      Buttons.Y.X.onclick    = proc{$} skip end
   end
in
   for X in 1..2 do
      for Y in 1..3 do Play = Rec.((Y-1)*2+X) in
	 if Play\=none then
	    {DrawOne X Y Play}
	 else
	    {DrawEmpty X Y}
	 end
      end
   end
   local
      Tag = AllTags.back.1
      Tagbis = AllTags.back.bis
      Color = c(black blue)
   in
      {Canvash create(rectangle 390 20 460 450 fill:Color.1 tags:Tagbis)}
      {Canvash create(text text:"BACK" 425 235 fill:white width:50
		      font:{Font type(50)} tags:Tag)}
      for I in 1..3 do
	 Buttons.I.3.ondeselect = proc{$} {Tagbis set(fill:Color.1)} end
	 Buttons.I.3.onselect   = proc{$} {Tagbis set(fill:Color.2)} end
	 Buttons.I.3.onclick    = proc{$}
				     {DeletePokelistTags}
				     if Event == status then
					{Send MAINPO set(map)}
				     else
					if {Label Event} == fight then
					   Event.1 = none
					else
					   Event.1 = auto
					end
					{Send MAINPO set(fight)}
				     end
				  end
      end
      local
	 fun{GenProc Dir}
	    proc{$}
	       get(OldX OldY) = {Send Arrows $}
	       Dir(NewX NewY) = {Send Arrows $}
	    in
	       {Buttons.OldY.OldX.ondeselect}
	       {Buttons.NewY.NewX.onselect}
	    end
	 end
	 proc{EnterCall}
	    getLast(X Y B) = {Send Arrows $}
	    if X<3 then
	       if Rec.((Y-1)*2+X) \= none then B=false
	       else B=true end
	    else B=true end
	 in
	    {Buttons.Y.X.onclick}
	 end
      in
	 {Buttons.1.1.onselect}
	 {Canvash bind(event:"<Up>" action:{GenProc up})}
	 {Canvash bind(event:"<Left>" action:{GenProc left})}
	 {Canvash bind(event:"<Right>" action:{GenProc right})}
	 {Canvash bind(event:"<Down>" action:{GenProc down})}
	 {Canvash bind(event:"<a>" action:EnterCall)}
      end
   end
   {Canvash getFocus(force:true)}
end
WIDGETS.pokelist = canvas(height:470 width:470 handle:HANDLES.pokelist
			  bg:white)
thread CANVAS.pokelist = HANDLES.pokelist end
%%%%%%% TOPWIDGET %%%%%%%%%%
TopWidget  = td( placeholder(handle:PLACEHOLDER)
		 geometry:geometry(height:470 width:470 x:600 y:200)
		 resizable:resizable(width:false height:false)
	       )

