% This program will make the library

declare
[QTk]={Module.link ["x-oz://system/wp/QTk.ozf"]}

Lib = {QTk.newImageLibrary}
proc{LoadImage Name Name2}
   try
      {Lib newPhoto(file:Name2 name:{StringToAtom Name})}
   catch _ then {Show 'Error opening gif'}  end 
end

DIRECTORY      = "Images/Gifs/"
EXTENSION      = ".gif"


%%%%%%% Pokemoz %%%%%%%
ALL_NAMES      = pokemoz("Bulbasoz" "Oztirtle" "Charmandoz")
ALL_ATTRIBUTES = attrib("_back" "_front" "_full")

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
%{Show done}

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

%%%%%% Others %%%%%%

OTHERS = others("Fight_disk")
Ow     = {Width OTHERS}
for I in 1..Ow do Name Name2 in
   Name  = OTHERS.I
   Name2 = {Flatten [DIRECTORY Name EXTENSION]}
   {LoadImage Name Name2}
end



{QTk.saveImageLibrary Lib "LibImg.ozf"}
{Show 'Saved lib'}












%Lib = {QTk.loadImageLibrary "LibImg.ozf"}
%fun{LoadImage Name}
%   Name2 = {Flatten Name} % le Flatten est la pour par ex : ["Bulb" "_full"]
									% ca devrait nous permettre de charger les images 
									% en ayant seulement le nom du pokemoz et son etat 
									% attendu!
%in
%   try
%      Img
%      {Lib get(name:{StringToAtom Name2} image:Img)}
%   in
%      Img
%   catch _ then {Show 'Error loading image'} nil 
%   end
%end

%% This is the startscreen widget
%StartImg1 = {LoadImage "Bulbasoz_full"}
%StartWidget = lr(td(button(image:StartImg1
%			   activebackground:c(0 0 255)
%			   background:c(0 255 0))			   
%		    button(text:"Bulbasoz"
%			   action:proc{$}
%				     {Show 'bulb'}
%				  end)))
