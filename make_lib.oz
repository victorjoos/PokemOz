% This program will make the library
functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
define
   Show = System.show

   Lib = {QTk.newImageLibrary}
   proc{LoadImage Name Name2}
      try
	 {Lib newPhoto(file:Name2 name:{StringToAtom Name})}
      catch _ then {Show 'Error opening gif'#{StringToAtom Name2}} end 
   end
   DIRECTORY      = "Images/Gifs/"
   EXTENSION      = ".gif"

%%%%%%% Pokemoz %%%%%%%
   ALL_NAMES      = pokemoz("Bulbasoz" "Oztirtle" "Charmandoz" "Ivysoz" "Venusoz"
			    "Charmeleoz" "Charozard" "Wartoztle" "Blastoz" "Ozweed"
			    "Kakunoz" "Ozdrill" "Pidgeoz" "Pidgeozoz" "Ozpidgeoz"
			    "Rozzozoz" "Roticoz" "Ozachu" "Ozmouse" "Vulpoz" "9xOz"
			    "Zoizoz" "Grozoizoz" "Coincwoz" "Goldoz" "Machoz" "Machozman"
			    "Ozchamp" "Ozcool" "Ozcruel" "Oz2_0" "Magiciendoz" "Pytagyroz")
   ALL_ATTRIBUTES = attrib("_back" "_front" )%"_small")

   ANw = {Width ALL_NAMES}
   AAw = {Width ALL_ATTRIBUTES}

% Loading all PokemOZ images
   for I in 1..ANw do
      for J in 1..AAw do Name Name2 in
	 Name  = {Flatten [ALL_NAMES.I ALL_ATTRIBUTES.J]}
	 Name2 = {Flatten [DIRECTORY Name EXTENSION]}
	 {LoadImage Name Name2}
      end
   end

%%%%%%%% Trainers %%%%%%
   TRAINERS = trainers("Red")
   TRAINERS_DIR = directions("_down"  "_left"  "_right" "_up")
   TRAINERS_ATT = attributes("_still" "_walk1" "_walk2")
   Trw = {Width TRAINERS}
   Tdw = {Width TRAINERS_DIR}
   Taw = {Width TRAINERS_ATT}

   for I in 1..Trw do
      for J in 1..Tdw do
	 for K in 1..Taw do Name Name2 in
	    Name  = {Flatten [TRAINERS.I TRAINERS_DIR.J TRAINERS_ATT.K]}
	    Name2 = {Flatten [DIRECTORY TRAINERS.I "/" Name EXTENSION]}
	    {LoadImage Name Name2}
	 end
      end
   end

%%%%% FIGHT %%%%%%%%
   TYPES = types("grass" "water" "fire")
   Wty = {Width TYPES}
   DIRTYPES = "Attacks/"
   for J in 1..Wty do
      for I in 1..5 do Name Name2 in
	 Name  = {Flatten [TYPES.J "_" {IntToString I}]}
	 Name2 = {Flatten [DIRECTORY DIRTYPES
			   Name EXTENSION]}
	 {LoadImage Name Name2}
      end
   end

%%%%%% Others %%%%%%
   
   OTHERS = others("Fight_disk" "bg_fight" "bg_arena" "bg_starters" "Bulbasoz_full" "Oztirtle_full"
		   "Charmandoz_full" "leader" "ball_1" "ball_2" "ball_3" "ball_4" "ball_dead" "ball_full"
		   "run_button" "fight_button" "switch_button" "capture_button"
		   "continue" "start_continue" "win_continue" "lost_screen"
		   "start_screen" "won_screen" "ground_tile" "grass_tile" "ground_tile_1" "grass_tile_1"
		  "ground_tile_2" "grass_tile_2" "ground_tile_3" "grass_tile_3")  
   Ow     = {Width OTHERS}
   for I in 1..Ow do Name Name2 in
      Name  = OTHERS.I
      Name2 = {Flatten [DIRECTORY Name EXTENSION]}
      {LoadImage Name Name2}
   end
   LOL = lol(b:a)
in
   {QTk.saveImageLibrary Lib "LibImg.ozf"}
   {QTk.flush}
   {System.gcDo}
   {Show 'Saved lib'}
   %{Show LOL.a}
   %LOL.b = c
   %{System.exit 0}
   {Application.exit 0}
end