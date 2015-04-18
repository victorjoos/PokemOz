declare
fun{FileIO}
   %% Returns a flat list of the tokens used in
   %% the file.
   fun {ReadMap FileInput}
      case FileInput of nil then nil
      [] H|T then
	 if H==&m then map|{ReadMap T}
	 elseif H==&0 then 0|{ReadMap T}
	 elseif H==&1 then 1|{ReadMap T}
	 elseif H==&r then r|{ReadMap T}
	 elseif H==&) then {ReadMap T}
	 else {ReadMap T}
	 end
      end
   end
   %% Parses a flat list into a tree (map.Y.X)
   fun {ParseMap TokL MapT}
      fun {ParseR TokL RT}
	 case TokL of nil then RT#nil
	 [] r|T then RT#(r|T)
	 [] H|T then
	    NewRT = {Tuple.append RT r(H)}
	 in
	    {ParseR T NewRT}
	 else
	    {Browse TokL} errorR
	 end
      end
   in
      case TokL of nil then MapT
      [] map|T then {ParseMap T map()}
      [] r|T then
	 RT#Next = {ParseR T r()}
	 NewMapT = {Tuple.append MapT map(RT)}
      in
	 {ParseMap Next NewMapT}
      else
	 {Browse TokL} errorMap
      end
   end
   
   FilePort = {NewPortObject state(needed)
	       fun{$ Msg state(State)}
		  case Msg
		  of map(Map) then
		     File = {New Open.file init(name:'map.txt' flags:[read])}
		     MapInput = {File read(list:$ size:all)}
		  in
		     Map = {ParseMap {ReadMap MapInput}}
		  [] trainers(T) then
		     T = [trainer(
			     pokemoz:p(name:"Bulbasoz" type:grass health:h(20 30) lvl:5)
			     sX:5 sY:2 eX:5 eY:2)
			  trainer(
			     pokemoz:p(name:"Oztirtle" type:water health:h(10 21) lvl:6)
			     sX:7 sY:1 eX:5 eY:1)]
		  end
	       end
	      }
end