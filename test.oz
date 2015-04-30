declare
proc{Seperate L L3}
   case L of nil then L3=nil#nil
   [] poke(Name Lvl)|Tail then N2 Lvl2 in
      L3=(Name|N2)#(Lvl|Lvl2)
      N2#Lvl2 = {Seperate Tail $}
   end
end

{Browse {Seperate [poke("Charmandoz" 5) poke("Charmandoz2" 6) poke("Charmandoz3" 7)] $}}