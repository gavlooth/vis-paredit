-- load standard vis module,  providing parts of the Lua API
require('vis')
local l = require('lexer')
local match = lpeg.match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

balanced_sexp = lpeg.P{ "(" * ((1 - lpeg.S"()") + lpeg.V(1))^0 * ")" }


match_sexp = {["("] = ")",
         [")"] = "(",
         ["["] = "]",
         ["]"] = "[",
         ["{"] = "}",
         ["}"] = "{",
         ["\""]="\"" }



function basic_sexp_patern (a,b)
  return a *  (l.any - b)^0 * b
end

function search_for_patern (p)
  local I = lpeg.Cp()
  return (1 - lpeg.P(p))^0 * I * p * I
end

local composed_sexp_paternt  =  (basic_sexp_patern('"','"') + basic_sexp_patern('(',')') +  basic_sexp_patern('[',']') + basic_sexp_patern('{','}') + l.graph^0 )

function next_sexp (start_pos)
local Range
 Range.start, Range.finish =  search_for_patern(composed_sexp_paternt)
 return Range
end

function previus_sexp (pos)
  local file, current_pos, sexp_pos  = vis.win.file, 0, nil
  while current_pos < pos  do
    sexp_pos = next_sexp(current_pos)
    if sexp_pos.start == nil then current_pos = current_pos + 1 else
      current_pos = sexp_pos.start end
  end
  return
end


function move_sexp (current_pos, target_pos)
   local file, cursor_char = vis.win.file, vis.win.file:content(current_pos,1)
   if  match_sexp[cursor_char] ~= nil then
       file:insert(target_pos,  cursor_char)
       file:delete(current_pos, 1)
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
 local the_word =    (l.space + S('\n'))^0 *  composed_sexp_paternt
 local start_pos, end_pos = file:match_at(the_word, pos + 1 )
 move_sexp(pos, end_pos)
end

function slurp_sexp_backward ()
 local file, pos = vis.win.file,  vis.win.selection.pos
 local the_word =  (l.space + S('\n'))^0 * composed_sexp_paternt
 local start_pos, end_pos = file:match_at(the_word, pos + 1 )
 move_sexp(pos, end_pos)
end


 vis:map(vis.modes.NORMAL,  '<Space>h', slurp_sexp_backwards)
   vis.events.subscribe(vis.events.INIT, function()
   vis:map(vis.modes.INSERT, "(", balance_sexp("(") )
   vis:map(vis.modes.INSERT, "[", balance_sexp("[") )
   vis:map(vis.modes.INSERT, "{", balance_sexp("{") )
   vis:map(vis.modes.INSERT, '"', balance_sexp('"') )
   vis:map(vis.modes.NORMAL,  '<Space>l', slurp_sexp_forward)
   vis:map(vis.modes.NORMAL,  '<Space>h',  burf_sexp_backwards  )
 end)


