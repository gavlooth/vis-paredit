-- load standard vis module,  providing parts of the Lua API
require('vis')
local l = require('lexer')
local match = lpeg.match
local P, R, S = lpeg.P, lpeg.R, lpeg.S







local str_pattern = ('"' *  ( ( P("\\\"") +    (1 -  S('"'))))^0 * '"' ) ^0


local char_sexp_literals = P{"\\" * S('(){}[]"') }


complete_balanced_sexp =   P{str_pattern  *
                            ("(" * ((2 - S("(){}[]")) * str_pattern + lpeg.V(1))^0 * ")") +
                            ("[" * ((1 - S("(){}[]")) * str_pattern + lpeg.V(1))^0 * "]") +
                            ("{" * ((1 - S("(){}[]")) * str_pattern + lpeg.V(1))^0 * "}")} +
                            ((l.graph -  S("(){}[]\""))^0 * char_sexp_literals^0)
--
match_sexp = {["("] = ")",
              [")"] = "(",
              ["["] = "]",
              ["]"] = "[",
              ["{"] = "}",
              ["}"] = "{",
              ["\""]="\"" }

-- local char_literals = P{"\\" * (S('(){}[]"') + R("az", "AZ")) }

-- local white_space_literals = P{ "\\newline" + "\\space" + "\\tab" + "\\formfeed" + "\\backspace" + "\\return" }



function search_patern (p)
  local I = lpeg.Cp()
  return (1 - lpeg.P(p))^0 * I * p * I
end


function advance_search_step (starting_pos, pos, previus_sexp_pos)
  local sexp_pos = next_sexp(starting_pos)
    if sexp_pos.finish == nil then
      return advance_search_step (starting_pos + 1, pos,  previus_sexp_pos)
    elseif  sexp_pos.finish < pos then
      return  advance_search_step (sexp_pos.finish, pos, sexp_pos  )
    else
      return previus_sexp_pos
  end
end



function match_next_sexp (pos) --pos + 1 ?
 local Range = {}
 local I = lpeg.Cp()
 local text = vis.win.file:content(pos,vis.win.file.size)
 local start, finish = match( S(" \n")^0 * I * complete_balanced_sexp * I, text  )
 Range.start , Range.finish = search_pos + start, search_pos + finish
 return Range
end





function get_previus_sexp (starting_pos, pos, previus_sexp_pos)
  local sexp_pos = match_next_sexp(starting_pos)
    if sexp_pos.finish == nil then
      return get_previus_sexp (starting_pos + 1, pos,  previus_sexp_pos)
    elseif  sexp_pos.finish < pos then
      return  advance_search_step (sexp_pos.finish, pos, sexp_pos  )
    else
      return previus_sexp_pos
  end
end


balanced_sexp = P{ "(" * ((1 - S"()") + lpeg.V(1))^0 * ")"}


function next_sexp (pos)
 local Range = {}
 local text = vis.win.file:content(pos,vis.win.file.size)
 local start, finish = match(search_patern(the_sexp_pattern), text )
 Range.start , Range.finish = start + pos, finish + pos
 return Range
end

function basic_sexp_patern (a,b)
  return a *  (l.any - b)^0 * b
end

local the_sexp_pattern  = (str_pattern +
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


