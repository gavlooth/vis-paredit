-- load standard vis module,  providing parts of the Lua API
require('vis')
local l = require('lexer')
local match = lpeg.match
local P, R, S = lpeg.P, lpeg.R, lpeg.S



local balanced_delims =   ('"' *  ( (P("\"") +    (1 -  S('"'))) + lpeg.V(1) )^0 * '"' )

balanced_sexp = P{ balanced_delims +
                   ( "(" * ((1 - S"(){}[]") + lpeg.V(1))^0 * ")") +
                   ("[" * ((1 - S"(){}[]") + lpeg.V(1))^0 * "]") +
                   ( "{" * ((1 - S"(){}[]")  + lpeg.V(1))^0 * "}")}

match_sexp = {["("] = ")",
         [")"] = "(",
         ["["] = "]",
         ["]"] = "[",
         ["{"] = "}",
         ["}"] = "{",
         ["\""]="\"" }

local char_literals = P{"\\" * (S('(){}[]"') + R("az", "AZ")) }

local char_sexp_literals = P{"\\" * S('(){}[]"') }

local white_space_literals = P{ "\newline" + "\space" + "\tab" + "\formfeed" + "\backspace" + "\return" }

balanced_sexp = P{ "(" * ((1 - S"()") + lpeg.V(1))^0 * ")"}

function validate_move (old_pos, new_pos)

end

function basic_sexp_patern (a,b)
  return a *  (l.any - b)^0 * b
end

function search_patern (p)
  local I = lpeg.Cp()
  return (1 - lpeg.P(p))^0 * I * p * I
end

local the_sexp_pattern  =      (balanced_delims +
                                basic_sexp_patern('(',')') +
                                basic_sexp_patern('[',']') +
                                basic_sexp_patern('{','}') + l.graph^0)

function next_sexp (pos)
 local Range = {}
 local text = vis.win.file:content(pos,vis.win.file.size)
 local start, finish = match(search_patern(the_sexp_pattern), text )
 Range.start , Range.finish = start + pos, finish + pos
 return Range
end

function advance_search_step (starting_pos, pos, previus_sexp_pos)
  local sexp_pos = next_sexp(starting_pos)
    if sexp_pos.finish == nil then
      return advance_search_step (starting_pos + 1, pos,  previus_sexp_pos )
    elseif  sexp_pos.finish < pos then
      return  advance_search_step (sexp_pos.finish, pos, sexp_pos  )
    else
      return previus_sexp_pos
  end
end


function move_sexp (current_pos, target_pos)
  local file, cursor_char = vis.win.file, vis.win.file:content(current_pos,1)
  if  match_sexp[cursor_char] ~= nil then
    file:insert(target_pos,  cursor_char)
    if current_pos > target_pos then
      file:delete(current_pos + 1, 1)
      vis.win.selection.pos = target_pos
    elseif current_pos < target_pos then
      file:delete(current_pos, 1)
      vis.win.selection.pos = target_pos - 1
    end
  end
end



---function advance_sexp_search (start_pos, end_pos)
---  print(start_pos)
---  local start , finish = vis.win.file:match_at(the_sexp_pattern, start_pos)
---  if finish == nil then
---    return advance_sexp_search (start_pos + 1, end_pos )
---  elseif  finish < end_pos then
---    print(finish)
---    return advance_sexp_search (finish, end_pos)
---  else return {start = start, finish = finish}
---  end
---end


function balance_sexp (key)
 if key == '(' then
  return function (_) vis:insert('()') return 0 end
 elseif key == '[' then
  return function (_) vis:insert('[]') return 0 end
 elseif key == '{' then
  return function (_) vis:insert('{}') return 0 end
 elseif key == '"' then
  return function (_) vis:insert('""') return 0 end
 end
end

function slurp_sexp_forward ()
 local file, pos = vis.win.file,  vis.win.selection.pos
 local the_word =    (l.space + S('\n'))^0 *  the_sexp_pattern
 local start_pos, end_pos = file:match_at(the_word, pos + 1)
 move_sexp(pos, end_pos)
end

function slurp_sexp_backwards ()
 local file, pos = vis.win.file,  vis.win.selection.pos
 local sexp_range = advance_search_step(0, pos)
--  vis:info(tostring(sexp_range.start) .. )
 move_sexp(pos, sexp_range.start - 1)
end


 vis:map(vis.modes.NORMAL,  '<Space>h', slurp_sexp_backwards)
   vis.events.subscribe(vis.events.INIT, function()
   vis:map(vis.modes.INSERT, "(", balance_sexp("(") )
   vis:map(vis.modes.INSERT, "[", balance_sexp("[") )
   vis:map(vis.modes.INSERT, "{", balance_sexp("{") )
   vis:map(vis.modes.INSERT, '"', balance_sexp('"') )
   vis:map(vis.modes.NORMAL,  '<Space>l', slurp_sexp_forward)
   vis:map(vis.modes.NORMAL,  '<Space>h',  slurp_sexp_backwards  )
 end)


