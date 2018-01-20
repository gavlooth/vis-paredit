
## Synopsis
This is a plugin to add structural expression capabilities for martanne/vis
Editor. I intent to use it to write clojure code, I dont use emacs and vis is much
faster than neovim. just add paredit.lua and require it in your visrc. The plugin works
similar to paredit.vim. All functions use the LPEG library, so no need to worry about key
bindings, none of them feed keys to emulate structural editing.

For now the following functions  are implemented


 slurp_sexp_backwards

 slice_sexp

 make_sexp_wraper

 split_sexp

You can find them at the bottom of paredit.lua, binded to Space based key compinations
This is because in neovim space is my Leader. Just change them if you dont like, untill I implement a
leader key properly (Or you can implement it*)
 This is the first time I write Lua code and used PEGs so probably the code
 can be improved.
