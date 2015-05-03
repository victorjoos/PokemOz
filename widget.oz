functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   PortDefinitions
   Browser
export
   LoadImage
   RedrawFight
   FightScene
   DrawPokeList
   InitFightTags
   InitPokeTags
   InitEvolveTags
   DrawMap
   StarterPokemoz
   DrawLost
   DrawWelcome
   DrawWon
   DrawEvolve

   TopWidget
   placeholder:PLACEHOLDER
   handles:HANDLES

   mainPO: MAINPO % port_object, main
   keys: KEYS % main
   player: PLAYER % port_object, main
   wild: WILD % port_object, main
   listAI: LISTAI % port_object, main

   widgets: WIDGETS % main
   canvas: CANVAS % port, animate_port, main
   tags: TAGS

   mapID: MAPID % main, port_object

   speed: SPEED % main, port_object
   delay: DELAY % main, port, animate
   probability: PROBABILITY % main, port

   maxX: MAXX % main, port, animate, AI
   maxY: MAXY % main, port, animate, AI
define
   % Imports
   Show = System.show
   Browse = Browser.browse
   GetArrows = PortDefinitions.getArrows
   % Exports
   MAINPO PLAYER WILD LISTAI WIDGETS CANVAS MAPID SPEED DELAY PROBABILITY MAXX MAXY KEYS
% This file will contain all the widget-containers used in this project
% each time with a brief description of what they do

%declare
% This function will load a given image from the library and return it
% @pre: Name is a list of strings for a valid image:
%            ex: ["Bulboz" "_back"]
% @post: Returns a QTk image handler (nil in case of failure)
   Lib = {QTk.loadImageLibrary "LibImg.ozf"}
   fun{LoadImage Name}
      Name2 = {Flatten Name}
   in
      try
      Img
      {Lib get(name:{StringToAtom Name2} image:Img)}
   in
      Img
      catch _ then {Show 'Error loading image'} nil end
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

   WIDGETS = widgets(starters:_ map:_ fight:_ pokelist:_ lost:_ won:_ welcome:_
                     evolve:_)
   CANVAS  =  canvas(starters:_ map:_ fight:_ fight2:_ fight3:_ pokelist:_ lost:_
                        won:_ welcome:_ evolve:_)
   HANDLES = handles(starters:_ map:_ fight:_ pokelist:_ lost:_ won:_ welcome:_
                     evolve:_)
   TAGS    =    tags(           map:_ map2:_ fight:_ fight2:_ fight3:_ pokelist:_
				           lost:_ won:_ welcome:_ evolve:_)
   PLACEHOLDER

%%%%%%% STARTWIDGET %%%%%%%

   proc{StarterPokemoz}
      Canvash = CANVAS.starters
      Yim=360 Ytx=Yim+75
       {Canvash create(image image:{LoadImage "bg_starters"} 235 235)}
      Names = all("Bulbasoz" "Charmandoz" "Oztirtle")
      Atoms = all( bulbasoz   charmandoz   oztirtle )
      BgCol    = all(c(42 154 60) c(220 35 35) c(49 71 232))
      BgColSel = all(c(12  83 23) c(172 33  6) c(21 33 121))
      DXX = 150
      Arrows = {GetArrows 3 1}
      Buttons = buttons(bulbasoz:_ charmandoz:_ oztirtle:_)
   in
      for I in 1..3 do
         X=(I-1)*DXX
         Tagbis = {Canvash newTag($)}
      in
      %Drawing
         {Canvash create(rectangle 20+X Yim-65 150+X Yim+95
         	 fill:BgCol.I tags:Tagbis)}
         {Canvash create(text text:Names.I font:{Font type(15)}
         	 85+X Ytx width:130 fill:white)}
         {Canvash create(image image:{LoadImage [Names.I "_full"]}
         	                 85+X Yim )}
         Buttons.(Atoms.I) = Tagbis
      end

      {Canvash getFocus(force:true)}
      local
         fun{GenProc Dir}
            proc{$}
               OldX = {Send Arrows get($ _)}
               NewX = {Send Arrows Dir($ _)}
            in
               {Buttons.(Atoms.OldX) set(fill:BgCol.OldX width:1.0)}
               {Buttons.(Atoms.NewX) set(fill:BgColSel.NewX width:4.0)}
            end
         end
      in
         {Buttons.(Atoms.1) set(fill:BgColSel.1 width:4.0)}
         {Send KEYS set(actions(starters( up:   {GenProc right}
                                          left: {GenProc left}
                                          right:{GenProc right}
                                          down: {GenProc left}
                                          a: proc{$ X}
                        					         Starter = Atoms.{Send Arrows get($ _)}
                  					            in
                  					               {Send Arrows kill}
                  					               {Send MAINPO makeTrainer(Starter)}
                                                X=pending
                           					   end
                                       )
                                 [up down right left a]))}
      end
   end
   WIDGETS.starters = canvas( width:470 height:470 handle:HANDLES.starters
			                     bg:white)
   thread CANVAS.starters = HANDLES.starters end


%%%%%%% MAPWIDGET %%%%%%%%%%

%@pre:  Draws the map given by the record read in File at once
%        and Canvash is te handle to the canvas
%@post: Returns a list of handles to be able to shift the map

   proc{DrawMap Map MaxX MaxY}
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
      TAGS.map = Tag
      TAGS.map2 = {Canvash newTag($)}
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
      	   attrib:attrib( text({Ch newTag($)} {Ch newTag($)})
                           bars(bar(act:{Ch newTag($)} {Ch newTag($)})
                  			     bar(act:{Ch newTag($)} {Ch newTag($)}))
                           balls({Ch newTag($)} {Ch newTag($)}))
      	   others:others({Ch newTag($)})
      	   ball:{Ch newTag($)})
      TAGS.fight2 = {CANVAS.fight2 newTag($)}
      TAGS.fight3 = tags(  fight:all({CANVAS.fight3 newTag($)}
                     				     bis:{CANVAS.fight3 newTag($)})
                     			   run:all({CANVAS.fight3 newTag($)}
                     				   bis:{CANVAS.fight3 newTag($)})
                     			   switch:all({CANVAS.fight3 newTag($)}
                     				      bis:{CANVAS.fight3 newTag($)})
                     			   capture:all({CANVAS.fight3 newTag($)}
                     				       bis:{CANVAS.fight3 newTag($)}))
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
   proc{DrawBalls BallL X0 Y0 Tag Tok}%Tok = ~1 or 1
      Canvash = CANVAS.fight
      Img = img(alive:{LoadImage "ball_full"} dead:{LoadImage "ball_dead"})
      Dx = 23 Dy = 23
      proc{Loop L I}
         X = I mod 3
         Y = I div 3
      in
         case L of nil then skip
         [] H|T then
            {Canvash create(image image:Img.H X0+Tok*Dx*X Y0+Dy*Y tags:Tag)}
            {Loop T I+1}
         end
      end
   in
      {Loop BallL 0}
   end

   fun{FightScene Play Adv PlayList AdvList}
      Arrows = {GetArrows 2 2}
      Buttons = all(   fight:button(onclick:_ onselect:_ ondeselect:_)
		       run:button(onclick:_ onselect:_ ondeselect:_)
		       switch:button(onclick:_ onselect:_ ondeselect:_)
		       capture:button(onclick:_ onselect:_ ondeselect:_)
		       onexit:proc{$} {Send Arrows kill} end)
      Atoms= atoms(  bton(fight run)
		     bton(switch capture))
      proc{DrawButtons}
         Canvash = CANVAS.fight3
         Tags = TAGS.fight3
         Dx = 232
         Dy = 87
         Color = color(   fight:col(black blue)
         run:col(black blue)
         switch:col(black blue)
         capture:col(black blue))
      in
         for Y in 1..2 do
            for X in 1..2 do
               Atm = Atoms.Y.X Name = {AtomToString Atm}
               XX = 2+(X-1)*(Dx+2)
               YY = 1+(Y-1)*(Dy+2)
            in
               {Canvash create(rectangle XX YY XX+Dx YY+Dy tags:Tags.Atm.bis
               fill:Color.Atm.1)}
               {Canvash create(image image:{LoadImage [Name "_button"]}
               XX+(Dx div 2) YY+(Dy div 2) tags:Tags.Atm.1)}
               Buttons.Atm.onselect   = proc{$} {Tags.Atm.bis set(fill:Color.Atm.2 width:4.0)} end
               Buttons.Atm.ondeselect = proc{$} {Tags.Atm.bis set(fill:Color.Atm.1 width:1.0)} end
            end
         end
         local
            fun{GenProc Dir}
               proc{$}
                  get(OldX OldY) = {Send Arrows $}
                  Dir(NewX NewY) = {Send Arrows $}
               in
                  {Buttons.(Atoms.OldY.OldX).ondeselect}
                  {Buttons.(Atoms.NewY.NewX).onselect}
               end
            end
            proc{EnterCall}
               get(X Y) = {Send Arrows $}
            in
               {Buttons.(Atoms.Y.X).onclick}
            end
            NewCanvash = CANVAS.fight
         in
            {Buttons.fight.onselect}
            /*{NewCanvash bind(event:"<Up>" action:{GenProc up})}
            {NewCanvash bind(event:"<Left>" action:{GenProc left})}
            {NewCanvash bind(event:"<Right>" action:{GenProc right})}
            {NewCanvash bind(event:"<Down>" action:{GenProc down})}
            {NewCanvash bind(event:"<a>" action:EnterCall)}*/
            {Send KEYS set(actions(fight( up:{GenProc up}
                                          down:{GenProc down}
                                          left:{GenProc left}
                                          right:{GenProc right}
                                          a:EnterCall
                                          )
                                    [a up down left right]))}
         end
      end
   in
      {CANVAS.fight create(image image:{LoadImage "bg_arena"} 235 190)}
      {RedrawFight npc    Adv  AdvList}
      {RedrawFight player Play PlayList}
      {DrawButtons}
      thread
         {CANVAS.fight2 create(image image:{LoadImage "bg_fight"} 235 45)}
         {CANVAS.fight2 create(text   text:"Choose your action" 235 45
         font:{Font type(16)} tags:TAGS.fight2)}
      end
      Buttons#Arrows
   end
   proc{RedrawFight Person NewPkm BallL}
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
            Yimg = 120      Ydisk = 210
         else
            Img = {LoadImage [NewPkm.name "_front" ]}
            TagD = Tags.plateau.1.2
            TagP = Tags.plateau.2.2
            Ximg = 340-Xst  Xdisk = 345-Xst
            Yimg = 55       Ydisk = 60
        end
      in
         {CanvasH create(image image:Disk  Xdisk  Ydisk tags:TagD)}
         {CanvasH create(image image:Img   Ximg  Yimg  tags:TagP)}
      end
      proc{DrawAttr}
         Tag Tag2 Tag3 Tag4 Tok
         HP  = {Send NewPkm.pid getHealth($)}
         LVL = {IntToString {Send NewPkm.pid getLvl($)}}
         Xname Xlvl Xbar Xballs
         Yname Ylvl Ybar Yballs
         if Person == player then
            Xname = 320+Xst Xlvl = 320+Xst Xbar = 270+Xst Xballs = 402+Xst
            Yname = 150     Ylvl = 190     Ybar = 165     Yballs = 165
            Tag  = Tags.attrib.1.1
            Tag2 = Tags.attrib.2.1.act
            Tag3 = Tags.attrib.2.1.1
            Tag4 = Tags.attrib.3.1
            Tok  = 1
         else
            Xname = 160-Xst Xlvl = 160-Xst Xbar = 110-Xst Xballs = 78-Xst
            Yname = 20      Ylvl = 60      Ybar = 35      Yballs = 35
            Tag = Tags.attrib.1.2
            Tag2 = Tags.attrib.2.2.act
            Tag3 = Tags.attrib.2.2.1
            Tag4 = Tags.attrib.3.2
            Tok  = ~1
         end
      in
         {CanvasH create(text Xname Yname text:NewPkm.name font:{Font type(16)}
                           tags:Tag)}
         {CanvasH create(text Xlvl Ylvl text:{Append "Lvl" LVL}
                           font:{Font type(15)} tags:Tag)}
         {DrawBar HP.act HP.max Xbar Ybar Tag2 Tag3}
         if Person==player orelse {Label NewPkm}\=wild then
            {DrawBalls BallL Xballs Yballs Tag4 Tok}
         end
      end
   in
      {DrawImg} {DrawAttr}
   end

   WIDGETS.fight = td( canvas( height:200 width:470
               			       handle:CANVAS.fight
               			       bg:white
               			     )
               		       canvas( height:87  width:470
               			       handle:CANVAS.fight2
               			       bg:white
               			     )
               		       canvas( height:180 width:470
               			       handle:CANVAS.fight3
               			       bg:white
               			     )
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
      {Show called#pokelist}
      Arrows = {GetArrows 3 3}
      Buttons = all( 1:x(  1:button(onclick:_ csonclick:_ onselect:_ ondeselect:_)
                           2:button(onclick:_ csonclick:_ onselect:_ ondeselect:_)
                           3:button(onclick:_ csonclick:_ onselect:_ ondeselect:_))
                     2:x(  1:button(onclick:_ csonclick:_ onselect:_ ondeselect:_)
                           2:button(onclick:_ csonclick:_ onselect:_ ondeselect:_)
                           3:button(onclick:_ csonclick:_ onselect:_ ondeselect:_))
                     3:x(  1:button(onclick:_ csonclick:_ onselect:_ ondeselect:_)
                           2:button(onclick:_ csonclick:_ onselect:_ ondeselect:_)
                           3:button(onclick:_ csonclick:_ onselect:_ ondeselect:_)))

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
         			     {IntToString {Send Play.pid getLvl($)}}]}
         	 XX+90 YY+15 fill:white font:{Font type(15)} tags:Tag)}
         {Canvash create(text text:"HEALTH" XX+130 YY+42
         	 fill:white font:{Font type(16)} tags:Tag)}
         {DrawMiniBar XX+85 YY+58 {Send Play.pid getHealth($)} red Tag}
         {Canvash create(text text:"EXP" XX+130 YY+85
         	 fill:white font:{Font type(16)} tags:Tag)}
         {DrawMiniBar XX+85 YY+100 {Send Play.pid getExp($)} yellow Tag}
         %bind the events
         Buttons.Y.X.ondeselect =   proc{$} {Tagbis set(fill:Color.1 width:1.0)} end
         Buttons.Y.X.onselect   =   proc{$} {Tagbis set(fill:Color.2 width:4.0)} end
         Buttons.Y.X.csonclick  =   proc{$ Ack}
                                       if Event == status then
                                          B={Send PlayL release((Y-1)*2+X $)}
                                          {Wait B}
                                       in
                                          {Send MAINPO set(map)}
                                          Ack = back
                                       else
                                          Ack = none
                                       end
                                    end
         Buttons.Y.X.onclick    =   proc{$ Ack}
                                       if Event == status then
                                          B={Send PlayL switchFirst((Y-1)*2+X $)}
                                          {Wait B}
                                       in
                                          {Send MAINPO set(map)}
                                          Ack = back
                                       else
                                          if {Send Play.pid getHealth($)}.act
                                          > 0 then
                                             Event.1 = Play
                                             {DeletePokelistTags}
                                             {Send MAINPO set(fight)}
                                             Ack = back
                                          else
                                             Event.1 = none
                                             Ack = none
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
         Buttons.Y.X.ondeselect = proc{$} {Tagbis set(fill:Color.1 width:1.0)} end
         Buttons.Y.X.onselect   = proc{$} {Tagbis set(fill:Color.2 width:4.0)} end
         Buttons.Y.X.onclick    = proc{$ Ack} Ack=none end
         Buttons.Y.X.csonclick  = proc{$ Ack} Ack=none end
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
         Color = c(black c(62 92 203))
      in
         {Canvash create(rectangle 390 20 460 450 fill:Color.1 tags:Tagbis)}
         {Canvash create(text text:"BACK" 425 235 fill:c(227 197 56) width:50
         	 font:{Font type(50)} tags:Tag)}
         for I in 1..3 do
            Buttons.I.3.ondeselect = proc{$} {Tagbis set(fill:Color.1 width:1.0)} end
            Buttons.I.3.onselect   = proc{$} {Tagbis set(fill:Color.2 width:4.0)} end
            Buttons.I.3.csonclick  = proc{$ Ack} Ack=none end
            Buttons.I.3.onclick    = proc{$ Ack}
                                          {DeletePokelistTags}
                                          if Event == status then
                                             {Send MAINPO set(map)}
                                             Ack = back
                                          else
                                             if {Label Event} == fight then
                                                Event.1 = back
                                             else
                                                Event.1 = auto
                                             end
                                             {Send MAINPO set(fight)}
                                             Ack = back
                                          end
                                       end
         end
         local
            fun{GenProc Dir}
               proc{$}
                  get(OldX OldY) = {Send Arrows $}
                  Dir(NewX NewY) = {Send Arrows $}
               in
                  {Show 'moved arrow'}
                  {Buttons.OldY.OldX.ondeselect}
                  {Buttons.NewY.NewX.onselect}
               end
            end
            proc{EnterCall Ack}
               getLast(X Y B) = {Send Arrows $}
               if X<3 then
                  if Rec.((Y-1)*2+X) \= none then B=false
                  else B=true end
               else B=true end
            in
               Ack = {Buttons.Y.X.onclick}
            end
            proc{CSEnterCall Ack}
               getLast(X Y B) = {Send Arrows $}
               if X<3 then
                  if Rec.((Y-1)*2+X) \= none then B=false
                  else B=true end
               else B=true end
            in
               Ack = {Buttons.Y.X.csonclick}
            end
         in
            {Buttons.1.1.onselect}
            {Send KEYS set(actions(pokelist(  up:{GenProc up}
                                             down:{GenProc down}
                                             left:{GenProc left}
                                             right:{GenProc right}
                                             a:EnterCall
                                             z:Buttons.1.3.onclick
                                             csa:CSEnterCall
                                          )
                                    [a z csa up down left right]))}
         end
      end
      {Canvash getFocus(force:true)}
   end
   WIDGETS.pokelist = canvas(height:470 width:470 handle:HANDLES.pokelist
			     bg:white)
   thread CANVAS.pokelist = HANDLES.pokelist end

%%%%%%% LOST SCREEN %%%%%%%
   proc{DrawLost}
      Canvash = CANVAS.lost
      TAGS.lost = {Canvash newTag($)}
   in
      {Canvash create(image image:{LoadImage "lost_screen"} 235 235)}
      {Canvash create(image image:{LoadImage "continue"} 235 235 tags:TAGS.lost)}
   end
   WIDGETS.lost = canvas(height:470 width:470 handle:HANDLES.lost bg:white)
   thread CANVAS.lost = HANDLES.lost end
%%%%%%%% STARTING SCREEN %%%%%%%%%
   proc{DrawWelcome}
      Canvash = CANVAS.welcome
      TAGS.welcome = {Canvash newTag($)}
   in
      {Canvash create(image image:{LoadImage "start_screen"} 235 235)}
      {Canvash create(image image:{LoadImage "start_continue"} 360 350 tags:TAGS.welcome)}
   end
   WIDGETS.welcome = canvas(height:470 width:470 handle:HANDLES.welcome bg:white)
   thread CANVAS.welcome = HANDLES.welcome end

%%%%% WINNING END-SCREEN %%%%%%
   proc{DrawWon}
      Canvash = CANVAS.won
      TAGS.won = {Canvash newTag($)}
   in
      {Canvash create(image image:{LoadImage "won_screen"} 235 235)}
      {Canvash create(image image:{LoadImage "win_continue"} 330 400 tags:TAGS.won)}
   end
   WIDGETS.won = canvas(height:470 width:470 handle:HANDLES.won bg:white)
   thread CANVAS.won = HANDLES.won end

%%%%%%% EVOLUTION %%%%%%%%%
   proc{InitEvolveTags}
      Canvash = CANVAS.evolve
   in
      TAGS.evolve = tags(img:{Canvash newTag($)} text:{Canvash newTag($)})
   end
   fun{DrawEvolve Name1 Name2}
      Canvash = CANVAS.evolve
      Tags = TAGS.evolve
      Img = imgs(0:{LoadImage [Name1 "_front"]} 1:{LoadImage [Name2 "_front"]})
      Text = text( 5:{Flatten ["Your " Name1 " is evolving!"]}
                  10:{Flatten [Name1 " evolved into..."]}
                  15:Name2 )
   in
      {Canvash create(image image:{LoadImage "bg_arena"} 235 190)}
      {Canvash create(image image:{LoadImage "bg_fight"} 235 425)}
      {Canvash create(image image:Img.0 235 190 tags:Tags.img)}
      {Canvash create(text   text:"What is happening!?" 235 425
                        font:{Font type(18)} tags:Tags.text)}
      Img#Text
   end
   WIDGETS.evolve = canvas(height:470 width:470 handle:HANDLES.evolve bg:white)
   thread CANVAS.evolve = HANDLES.evolve end

%%%%%%% TOPWIDGET %%%%%%%%%%
   RET
   TopWidget  = td( placeholder(handle:PLACEHOLDER)
		    geometry:geometry(height:470 width:470 x:200 y:200)
		    resizable:resizable(width:false height:false)
		    %action:proc{$}{Application.exit 0} end
          return:RET
		  )
   thread {Wait RET} {Application.exit 0} end
end
