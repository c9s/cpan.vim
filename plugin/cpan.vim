" cpan.vim
" vim:fdm=syntax:et:sw=2:
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

" Install:
"   put cpan.vim into your ~/.vim/plugin/
" Usage:
"

let g:cpan_installed_cache  = expand('~/.vim-cpan-installed-modules')
let g:cpan_source_cache     = expand('~/.vim-cpan-source')
let g:cpan_cache_expiry     = 60 * 24 * 7   " 7 days
let g:cpan_installed_pkgs = []
let g:cpan_pkgs = []

fu! GetPerlLibPaths()
  let out = system('perl -e ''print join "\n",@INC''')
  let paths = split( out , "\n" ) 
  return paths
endf
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
fu! GotoModule()
  resize 50
  call GotoModuleFileInPaths( getline('.') )
endf
fu! InitMapping()
    imap <buffer> <Enter> <ESC>j<Enter>
    nnoremap <buffer> <Enter> :call GotoModule()<CR>
    nnoremap <buffer> t       :call TabGotoModuleFileInPaths( getline('.') )<CR>
    inoremap <buffer> <C-n> <ESC>j

    nnoremap <buffer> <C-n> j
    nnoremap <buffer> <C-p> k
    nnoremap <buffer> <ESC> <C-W>q

    " http://search.cpan.org/search?query=Data%3A%3ADumper&mode=all&sourceid=Mozilla-search
    nnoremap <buffer> @   :exec '!open -a Firefox http://search.cpan.org/search?query=' . expand('<cWORD>') . '&mode=all'<CR>
    nnoremap <buffer> $   :exec '!perldoc ' . expand('<cWORD>')<CR>
endf
fu! InitSyntax()
    if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
        "hi CursorLine ctermbg=DarkCyan ctermfg=Black
    endif
endf
fu! OpenModuleWindow()
    8new
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal nowrap
    setlocal cursorline
    setlocal nonumber
    setfiletype cpanwindow
    cal PrepareInstalledCPANModuleCache()
    call RenderResult( g:cpan_installed_pkgs )
    autocmd CursorMovedI <buffer>        
        \ call SearchCPANModule()
    "execute 'autocmd InsertLeave  <buffer> nested call ' . self.to_str('on_insert_leave()'  )
    call cursor( 1, 1 )
    call InitMapping()
    call InitSyntax()
    startinsert
endf
fu! SearchCPANModule()
    let pattern = getline('.')
    cal PrepareInstalledCPANModuleCache()
    let pkgs = filter( copy( g:cpan_installed_pkgs ) , 'v:val =~ "' . pattern . '"' )
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

" Function: FindPerlPackageFiles
" Return: package [list]
fu! FindPerlPackageFiles()
    let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
    let pkgs = split("\n" , system(  'find ' . paths . ' -type f -iname *.pm ' 
                \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                \ . " | perl -pe 's/^package (.*?);/\$1/' "
                \ . " | sort | uniq " )
    return pkgs
endf
fu! CacheInstalledCPANModules()
    let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
    call system( 'find ' . paths . ' -type f -iname *.pm ' 
                \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                \ . " | perl -pe 's/^package (.*?);/\$1/' "
                \ . " | sort | uniq > " . g:cpan_installed_cache )
endf
fu! GetPackageSourceListPath()
    let paths = [ 
                \expand('~/.cpanplus/02packages.details.txt.gz'),
                \expand('~/.cpan/sources/modules/02packages.details.txt.gz')
                \]
    for f in paths 
      if filereadable( f ) 
        return f
      endif
    endfor
    return
endf
fu! ExportCPANSource()
  let path =  GetPackageSourceListPath()
  echo "executing zcat: " . path
  call system('zcat ' . path . " | grep -v '^[0-9a-zA-Z-]*: '  | cut -d' ' -f1 > " . g:cpan_source_cache )
  echo "done"
endf
fu! PrepareCPANModuleCache()
    if len( g:cpan_pkgs ) == 0 
      echo "preparing cpan module list..."
      let g:cpan_pkgs = GetCPANModuleList()
    endif
endf
fu! PrepareInstalledCPANModuleCache()
    if len( g:cpan_installed_pkgs ) == 0 
      echo "preparing cpan module list..."
      let g:cpan_installed_pkgs = GetInstalledCPANModuleList()
    endif
endf
fu! GetCPANModuleList()
  " XXX check expiry
  if ! filereadable( g:cpan_source_cache ) && IsExpired( g:cpan_source_cache , g:cpan_cache_expiry  )
    call ExportCPANSource()
  endif
  return readfile( g:cpan_source_cache )
endf
fu! GetInstalledCPANModuleList()
  if filereadable( g:cpan_installed_cache ) && ! IsExpired( g:cpan_installed_cache , g:cpan_cache_expiry )
    return readfile( g:cpan_installed_cache )
  else
    echo "caching packages..."
    call CacheInstalledCPANModules()
    echo "reading cache..."
    return readfile( g:cpan_installed_cache )
  endif
endf
fu! CompleteInstalledCPANModuleList()
    cal PrepareInstalledCPANModuleCache()

    let start_pos  = GetCompStartPos()
    let base = GetCompBase()
    echo "filtering..."
    " let res = filter( copy( g:cpan_installed_pkgs ) , 'v:val =~ "' . base . '"' )
    let res = []
    for p in g:cpan_installed_pkgs 
      if p =~ '^' . base 
        call insert( res , p )
      endif
    endfor
    call complete( start_pos[1]+1 , res )
    return ''
endf
fu! CompleteCPANModuleList()
    if len( g:cpan_pkgs ) == 0 
      echo "preparing cpan module list..."
      let g:cpan_pkgs = GetCPANModuleList()
      echo "done"
    endif

    let start_pos  = GetCompStartPos()
    let base = GetCompBase()
    echo "filtering..."
    let res = filter( copy( g:cpan_pkgs ) , 'v:val =~ "' . base . '"' )
    call complete( start_pos[1]+1 , res )
    return ''
endf
fu! GetCompStartPos()
    return searchpos( '[^a-zA-Z0-9:_]' , 'bn' , line('.') )
endf
fu! GetCompBase()
    let col = col('.')
    let pos = GetCompStartPos()
    let line = getline('.')
    let base =  strpart( line , pos[1] , col )
    return base
endf

" check file expiry
"    @file:    filename
"    @expiry:  minute
fu! IsExpired(file,expiry)
    let lt = localtime( )
    let ft = getftime( expand( a:file ) )
    let dist = lt - ft
    if dist > a:expiry * 60 
        return 1
    else
        return 0
    endif
endf

" inoremap <C-x><C-m>  <C-R>=CompleteCPANModuleList()<CR>
inoremap <C-x><C-m>  <C-R>=CompleteInstalledCPANModuleList()<CR>
nnoremap <C-x><C-m>  :call OpenModuleWindow()<CR>
nnoremap <leader>fm  :call FindModuleByCWord()<CR>

" for testing...
" Jifty::Collection
" Data::Dumper::Simple
" AnyEvent::Impl::Perl 
