declare
proc{Get X}
   case X
   of get(I J) then I=1 J =1 end
end

get(X Y) = {Get $}
{Browse X#Y}