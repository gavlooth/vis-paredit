-- load standard vis module,  providing parts of the Lua API
require('vis')
require('lexer')
require('plugins/filetype')
require('plugins/textobject-lexer')



local l = require('lexer')
local match = lpeg.match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

balanced_sexp = lpeg.P{ "(" * ((1 - lpeg.S"()") + lpeg.V(1))^0 * ")" }

function basic_sexp_patern (a,b)
  return a *  (l.any - b)^0 * b
end

function search_patern (start_pos, pattern)
  local I = lpeg.Cp()
  return (1 - lpeg.P(p))^0 * I * p * I
end

function next_sexp (start_pos)
 local start_, finish_ =  search_parern(basic_sexp_patern('"','"') +  basic_sexp_patern('(',')') +  basic_sexp_patern('[',']') + basic_sexp_patern('{','}') + l.graph^0 )
 return Range = {start = start_ , finish = finish_ }
end

function previus_sexp (pos)
  local file = vis.win.file
  local current_pos, = 0
  local sexp_pos = nil
  while current_pos < pos  do
    sexp_pos = next_sexp(current_pos)
    if sexp_pos.start == nil then current_pos = current_pos + 1 else current_pos =sexp_pos.start end
  end
  return
end


match_sexp = {["("] = ")",
         [")"] = "(",
         ["["] = "]",
         ["]"] = "[",
         ["{"] = "}",
         ["}"] = "{",
         ["\""]="\"" }


function move_sexp (current_pos, target_pos)
   local file = vis.win.file
   local cursor_char =  file:content(current_pos,1)
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
 local file = vis.win.file
 local pos = vis.win.selection.pos
 local the_word =    (l.space + S('\n'))^0 *  (basic_sexp_patern('"','"') +
 basic_sexp_patern('(',')') +  basic_sexp_patern('[',']') +
 basic_sexp_patern('{','}') + l.graph^0 )

 local start_pos, end_pos = file:match_at(the_word, pos + 1 )
 move_sexp(pos, end_pos)
end

function slurp_sexp_backward ()
 local file = vis.win.file
 local pos = vis.win.selection.pos
 local the_word =  (l.space + S('\n'))^0 * (sexp_patern('"','"') +
       sexp_patern('(',')') +  sexp_patern('[',']') + sexp_patern('{','}') +
       l.graph^0 )
 local start_pos, end_pos = file:match_at(the_word, pos + 1 )
 move_sexp(pos, end_pos)
end


function burf_sexp_backwards ()
 local file = vis.win.file
 local pos = vis.win.selection.pos
 local current_pos = 0
 local starting_pos = 0;
 local tmp = nil
 local tmp0 = nil
 local the_word =  (l.space + S('\n'))^0 * (sexp_patern('"','"') +  sexp_patern('(',')') +  sexp_patern('[',']') + sexp_patern('{','}') + l.graph^0 )
   while current_pos < pos  do
     tmp0 ,
 tmp  =  file:match_at(one_word ,  current_pos)
     if tmp0 ~= nil then starting_pos = tmp0  end
     if tmp == nil then current_pos = current_pos + 1 else current_pos = tmp end
   end
   file:insert(starting_pos ,  "<>")
 end
