-- load standard vis module,  providing parts of the Lua API
require('vis')
local lexers = vis.lexers
local l = require('lexer')
local match = lpeg.match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local char_sexp_literals = P{"\\" * S('(){}[]"') }
local char_literals = P{"\\" * (l.graph -  S("n\"\\"))}

local str_pattern = ('"' *  ( ( P("\\\"") +    (1 -  S('"'))))^0 * '"')
local strings_and_chars = str_pattern + char_sexp_literals

complete_balanced_sexp =   P{("(" * ((1 - S("(){}[]\"")) + strings_and_chars + lpeg.V(1))^0 * ")") +
("[" * ((1 - S("(){}[]\"")) + strings_and_chars + lpeg.V(1))^0 * "]") +
("{" * ((1 - S("(){}[]\"")) + strings_and_chars  + lpeg.V(1))^0 * "}") +
(((l.graph -  S("(){}[]\"\\")) + char_literals))^1+ str_pattern^1  }

match_sexp = {["("] = ")",
[")"] = "(",
["["] = "]",
["]"] = "[",
["{"] = "}",
["}"] = "{",
["\""]="\"" }



--This function returns a patternt that skips as many characters
--in order to find the given patternt



function first_occurance (p)
  return lpeg.P{ p + 1 * l.V(1) }
end

function search_patern (p)
  local I = lpeg.Cp()
  return (1 - lpeg.P(p))^0 * I * p * I
end
function print_two (a,b)
  print ("  " .. tostring (a) .. "--" .. tostring(b))
end

function match_next_sexp (pos) --pos + 1 ?
  local Range = {}
  local I = lpeg.Cp()
  local text = vis.win.file:content(pos + 1,vis.win.file.size)
  local start, finish = match(S(" \n")^0 * I  * complete_balanced_sexp * I, text  )
  if start ~= nil then
    Range.start , Range.finish = pos + start, pos + finish
  end
  -- print_two(Range.start,Range.finish)
  return Range
end



function match_next_sexp_two(pos) --pos + 1 ?
  local Range = {}
  local I = lpeg.Cp()
  local text = vis.win.file:content(pos + 1,vis.win.file.size)
  local start, finish = match(S(" \n")^0 * I  * complete_balanced_sexp * I, text  )
  if start ~= nil then
    Range.start , Range.finish = pos + start, pos + finish
  end
  -- print_two(Range.start,Range.finish)
  return Range
end


function last_occurance (p)
  local I = lpeg.Cp ()
  return lpeg.P{(I * p * I * lpeg.S(" \n")^0 * lpeg.P(-1)) + 1 * lpeg.V(1)}
end


function match_previus_sexp (pos)
  local text_trimmed =  vis.win.file:content(0,pos)
  return match(last_occurance(complete_balanced_sexp), text_trimmed)
end


function blink_error()
end


function move_sexp (current_pos, target_pos)
  local file, cursor_char = vis.win.file, vis.win.file:content(current_pos,1)
  if target_pos == nil then
    blink_error()
  elseif match_sexp[cursor_char] == nil then
    blink_error(lexers.STYLE_INFO)
  elseif match_sexp[cursor_char] ~= nil then
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
  local sexp_pos = match_next_sexp(pos)
  move_sexp(pos, sexp_pos.finish)
end

function slurp_sexp_backwards ()
  local  pos = vis.win.selection.pos
  local start, finish = match_previus_sexp(pos)
  if start == nil then

    move_sexp(pos,nil)
  else
    move_sexp(pos,start - 1)
  end
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


