" cpan-list.vim
" vim:fdm=marker:et:sw=2:
"
" Author: Cornelius <cornelius.howl@gmail.com>
" Date: Sun Sep 19 10:47:15 2009
" Keywords: perl , cpan , vim
" 
" This file is free software; you can redistribute it and/or modify it under
" the terms of the GNU General Public License as published by the Free
" Software Foundation; either version 2, or (at your option) any later
" version.
" 
" This file is distributed in the hope that it will be useful, but WITHOUT ANY
" WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
" FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
" details.
" 
" You should have received a copy of the GNU General Public License along with
" GNU Emacs; see the file COPYING.  If not, write to the Free Software
" Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
" USA.

let g:mlist_filename = expand('~/.vim-cpan-modules')

" standard vim function for perl {{{
fu! GetCursorModuleName()
  let cw = substitute( expand("<cWORD>") , '.\{-}\([a-zA-Z0-9_:]\+\).*$' , '\1' , '' )
  return cw
endf

fu! GetCursorMethodName()
  let cw = expand("<cWORD>")
  let m = substitute( cw , '.\{-}\([a-zA-Z0-9_:]\+\)->\(\w\+\).*$' , '\2' , '' )
  if m != cw 
    return m
  else
    return
  endif
endf

fu! TranslateModuleName(n)
  return substitute( a:n , '::' , '/' , 'g' ) . '.pm'
endf

fu! GetPerlLibPaths()
  let out = system('perl -e ''print join "\n",@INC''')
  let paths = split( out , "\n" ) 
  return paths
endf

fu! TabGotoFile(fullpath,method)
    execute ':tabedit ' . a:fullpath
    if strlen(a:method) > 0
      let s = search( '^sub\s\+' . a:method . '\s' , '', 0 )
      if !s 
        "echomsg "Can not found method: " . a:method 
      endif
    endif
    return 1
endf

fu! GotoFile(fullpath,method)
    execute ':e ' . a:fullpath
    if strlen(a:method) > 0
      let s = search( '^sub\s\+' . a:method . '\s' , '', 0 )
      if !s 
        "echomsg "Can not found method: " . a:method 
      endif
    endif
    return 1
endf

fu! FindModuleByCWord()
    let mod = GetCursorModuleName()
    call TabGotoModuleFileInPaths( mod )
endf

fu! TabGotoModuleFileInPaths(mod)
  let paths = GetPerlLibPaths()
  let fname = TranslateModuleName( a:mod )
  let methodname = GetCursorMethodName()
  call insert(paths, 'lib/' )
  for p in paths 
    let fullpath = p . '/' . fname
    if filereadable( fullpath ) && TabGotoFile( fullpath , methodname ) 
      break
    endif
  endfor
endf

fu! GotoModuleFileInPaths(mod)
  let paths = GetPerlLibPaths()
  let fname = TranslateModuleName( a:mod )
  let methodname = GetCursorMethodName()
  call insert(paths, 'lib/' )
  for p in paths 
    let fullpath = p . '/' . fname
    if filereadable( fullpath ) && GotoFile( fullpath , methodname ) 
      return
    endif
  endfor
  echomsg "No such module: " . a:mod
endf

fu! ReadModule()
  resize 50
  call GotoModuleFileInPaths( getline('.') )
endf
" }}}

fu! InitMapping()
    inoremap <buffer> <Enter> <ESC>:call SearchCPANModule()<CR>
    nnoremap <buffer> <Enter> :call ReadModule()<CR>
    inoremap <buffer> <C-n> <ESC>j

    nnoremap <buffer> <C-n> j
    nnoremap <buffer> <C-p> k
    nnoremap <buffer> <ESC> <C-W>q

    " http://search.cpan.org/search?query=Data%3A%3ADumper&mode=all&sourceid=Mozilla-search
    nnoremap <buffer> @   :exec '!open -a Firefox http://search.cpan.org/search?query=' . expand('<cWORD>') . '&mode=all'<CR>
    nnoremap <buffer> $   :exec '!perldoc ' . expand('<cWORD>')<CR>
endf

"string"
fu! InitSyntax()
    if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
        "hi CursorLine ctermbg=DarkCyan ctermfg=Black
    endif
endf

fu! OpenModuleWindow()
    9new
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal nowrap
    setlocal cursorline
    setlocal nonumber
    setfiletype cpanwindow
    let g:pkg_cache = GetCPANModuleList()
    call RenderResult( g:pkg_cache )
    call cursor( 1, 1 )
    call InitMapping()
    call InitSyntax()
    startinsert
endf

fu! SearchCPANModule()
    let pattern = getline('.')
    let pkgs = filter( copy( g:pkg_cache ) , 'v:val =~ "' . pattern . '"' )

    let old = getpos('.')
    silent 2,$delete _
    call RenderResult( pkgs )

    call setpos('.',old)
    startinsert
    call cursor(line("."), col(".") + 1)
endfunc

fu! RenderResult(pkgs)
    let @o = join( a:pkgs , "\n" )
    silent put o
endf

fu! FindPerlPackageFiles()
    let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
    let pkgs = split("\n" , system(  'find ' . paths . ' -type f -iname *.pm ' 
                \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                \ . " | perl -pe 's/^package (.*?);/\$1/' "
                \ . " | sort | uniq " )
    return pkgs
endf

fu! FindPerlPackages()
    let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
    let pkgs = split("\n" , system(  'find ' . paths . ' -type f -iname *.pm ' 
                \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                \ . " | perl -pe 's/^package (.*?);/\$1/' "
                \ . " | sort | uniq " )
    return pkgs
endf

fu! GetCPANModuleList()
    let pkgs = [ ]
    if filereadable( g:mlist_filename )
        let pkgs = readfile( g:mlist_filename )
    else
        echo "caching packages..."
        let pkgs = FindPerlPackages()
        call writefile( pkgs , g:mlist_filename )
        echo "done"
    endif
    return pkgs
endf

fu! CompleteCPANModuleList()
    let pkgs = GetCPANModuleList()

    let start_pos  = CompStartPos()
    let base = CompBase()

    let res = []
    for pkg in pkgs 
        if pkg =~ '^' . base
            call add( res , pkg )
        endif
    endfor
    call complete( start_pos[1]+1 , res )
    return ''
endf

fu! CompStartPos()
    return searchpos( '[^a-zA-Z0-9:_]' , 'bn' , line('.') )
endf

fu! CompBase()
    let col = col('.')
    let pos = CompStartPos()
    let line = getline('.')
    let base =  strpart( line , pos[1] , col )
    return base
endf

inoremap <C-x><C-m>  <C-R>=CompleteCPANModuleList()<CR>
nnoremap <C-x><C-m>  :call OpenModuleWindow()<CR>
nnoremap <leader>fm  :call FindModuleByCWord()<CR>

" for testing...
" Jifty::Collection
" Data::Dumper::Simple
" AnyEvent::Impl::Perl 
