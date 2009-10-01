" cpan.vim
" Vim plugin for perl hackers {{{
"
" vim:fdm=marker:et:sw=2:
"
" &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
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
"
" &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
"
" Author: Cornelius <cornelius.howl@DELETE-ME.gmail.com>
" Site: http://oulixe.us/
" Date: Sun Sep 19 10:47:15 2009
" Screencast:  http://www.youtube.com/watch?v=erF0NWUIbr4  <cpan.vim>
"
" Keywords: perl , cpan , vim
"
" Features:
"   * provide a quick way to search install cpan modules
"   * easily open module file or in new tab
"   * cpan module completion
"   * browser integration
"
" Install:
"
"   $ make install 
"
" Usage:
"   CPAN Window:
"       1. 
"
"           type <C-c><C-m> to open cpan window horizontally
"           type <C-c><C-v> to open cpan window vertically
"
"       2. type pattern to search cpan modules
"
"       3. 
"           - press <enter> to go to the first matched module file.
"           - press <C-t> to go to the first matched module file in new tab.
"           - press @ to search module by current pattern in your browser
"           - support bash style bindings , eg: <C-a>, <C-e>, <C-f>, <C-b>
"           - press <Tab> to switch cpan window mode (search all modules or
"                 installed modules)
"
"       4. <C-n> or <C-p> to select result
"
"       5. 
"           - press <enter> to go to the module file.
"           - press t to go to the module file in new tab
"           - press @ to see the module documentation in your browser
"           - press ! to see the module documentation by perldoc command
"           - press $ to see the module documentation inside vim window
"           - press I to install the module
"           - support bash style bindings , eg: <C-a>, <C-e>, <C-f>, <C-b>
"
"       6. 
"           <ESC><ESC> to close cpan window
"
"   ModuleName Completion:
"       
"       in insert mode: <Ctrl-x><Ctrl-m> for module name completion (installed
"       module)
"
"   Inspect Module File Content:
"       in normal mode: <Ctrl-c>g to open the module under the cursor in new
"       tab
"
"   Pod Helper:
"       auto insert function pod: press <C-c><C-p>f on function name (normal mode)
"
" Commands:
"
"   ReloadModuleCache           
"   ReloadInstalledModuleCache 
"   ReloadCurrentLibModuleCache 
"
" Configuration:
"
"        g:cpan_browser_command  : command for launching browser
"        g:cpan_win_type         : v (vertical) or s (horizontal) cpan window
"        g:cpan_win_width     
"        g:cpan_win_height     
"        g:cpan_win_mode         : default cpan window mode 
"                             (search installed modules or all modules or currentlib ./lib)
"        g:cpan_installed_cache  : filename of installed package cache
"        g:cpan_source_cache     : filename of package source cache
"        g:cpan_cache_expiry     : cache expirytime in minutes
"        g:cpan_max_result       : max search result
"        g:cpan_install_command  : command for installing cpan modules
"        g:cpan_user_defined_sources : user-defined package source paths
"
" &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
" }}}
" version check {{{
if exists('g:loaded_cpan') || v:version < 701
  "finish
endif
let g:loaded_cpan = 0200  "Version
" }}}
" configurations "{{{
let g:CPAN = { }
let g:CPAN.Mode = { 'Installed': 1 , 'CurrentLib': 2 , 'All': 3  }

let g:cpan_install_command = ''
let g:cpan_browser_command = ''
let g:cpan_win_mode = g:CPAN.Mode.Installed
let g:cpan_win_type = 'vsplit'   " v (vertical) or s (split)
let g:cpan_win_width = 30
let g:cpan_win_height = 10
let g:cpan_installed_cache  = expand('~/.vim-cpan-installed-modules')
let g:cpan_source_cache     = expand('~/.vim-cpan-source')
let g:cpan_cache_expiry     = 60 * 24 * 7   " 7 days
let g:cpan_installed_pkgs = []
let g:cpan_pkgs = []
let g:cpan_curlib_pkgs = []
let g:cpan_max_result = 50
let g:cpan_user_defined_sources = []
"}}}
" default init {{{
if system('uname') =~ 'Darwin'
  let g:cpan_browser_command  = 'open -a Firefox'
elseif system('uname') =~ 'Linux'
  let g:cpan_browser_command  = 'firefox'
else  " default
  let g:cpan_browser_command  = 'firefox'
endif

if executable('cpanp')
  let g:cpan_install_command = 'cpanp i'
elseif executable('cpan')
  let g:cpan_install_command = 'cpan'
endif
" }}}
" Common Functions"{{{

fun! GetPerlLibPaths()
  return split( system('perl -e ''print join "\n",@INC''') , "\n" ) 
endf

fun! GetCursorModuleName()
  return substitute( expand("<cWORD>") , '.\{-}\([a-zA-Z0-9_:]\+\).*$' , '\1' , '' )
endf

fun! GetCursorMethodName()
  let cw = expand("<cWORD>")
  let m = substitute( cw , '.\{-}\([a-zA-Z0-9_:]\+\)->\(\w\+\).*$' , '\2' , '' )
  if m != cw 
    return m
  endif
  return
endf

" translate module name to file path
fun! TranslateModuleName(n)
  return substitute( a:n , '::' , '/' , 'g' ) . '.pm'
endf

fun! TabGotoFile(fullpath,method)
    execute ':tabedit ' . a:fullpath
    if strlen(a:method) > 0
      let s = search( '^sub\s\+' . a:method . '\s' , '', 0 )
      if !s 
        "echomsg "Can not found method: " . a:method 
      endif
    endif
    return 1
endf

fun! GotoFile(fullpath,method)
    execute ':e ' . a:fullpath
    if strlen(a:method) > 0
      call search( '^sub\s\+' . a:method . '\s' , '', 0 )
    endif
    return 1
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


"  }}}

fun! TabGotoModuleFileInPaths(mod)
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

fun! TabGotoModuleFileFromCursor()
  call TabGotoModuleFileInPaths( GetCursorModuleName() )
endf

fun! GotoModuleFileInPaths(mod)
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

fun! GotoModule()
  if g:cpan_win_type == 'v'
    vertical resize 98
  else
    resize 60
  endif
  call GotoModuleFileInPaths( getline('.') )
endf

" ==== Window Manager =========================================== {{{
let s:WindowManager = { 'buf_nr' : -1 }

fun! s:WindowManager.open(pos,type,size)
  call self.split(a:pos,a:type,a:size)
endf

fun! s:WindowManager.split(position,type,size)
  if ! bufexists( self.buf_nr )
    if a:type == 'split'
      let act = 'new'
    elseif a:type == 'vsplit'
      let act = 'vnew'
    endif
    exec a:position . ' ' . a:size . act
    let self.buf_nr = bufnr('%')
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal nowrap
    setlocal cursorline
    setlocal nonumber
    setlocal fdc=0
    call self.init_buffer()
    call self.init_syntax()
    call self.init_basic_mapping()
    call self.init_mapping()
    call self.start()
  elseif bufwinnr(self.buf_nr) == -1 
    exec a:position . ' ' . a:size . a:type
    execute self.buf_nr . 'buffer'
    call self.buffer_reload_init()
  elseif bufwinnr(self.buf_nr) != bufwinnr('%')
    execute bufwinnr(self.buf_nr) . 'wincmd w'
  endif
endf

fun! s:WindowManager.start()
    call cursor( 1, 1 )
    startinsert
endf

fun! s:WindowManager.init_buffer()

endf

fun! s:WindowManager.init_syntax()

endf

fun! s:WindowManager.init_mapping()

endf

fun! s:WindowManager.init_basic_mapping()
    imap <buffer>     <Enter> <ESC>j<Enter>
    imap <buffer>     <C-a>   <Esc>0i
    imap <buffer>     <C-e>   <Esc>A
    imap <buffer>     <C-b>   <Esc>i
    imap <buffer>     <C-f>   <Esc>a
    inoremap <buffer> <C-n> <ESC>j
    nnoremap <buffer> <C-n> j
    nnoremap <buffer> <C-p> k
    nnoremap <buffer> <ESC> <C-W>q
endf

fun! s:WindowManager.render_result(matches)
    let @o = join( a:matches , "\n" )
    silent put o
endf

fun! s:WindowManager.close()
  silent 0f
endf

" ==== Window Manager =========================================== }}}


" &&&& Perl Function Search window &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
"
" Features
"   built-in function name search
"   perl api function name search
"
let s:FunctionWindow = copy(s:WindowManager)
let s:FunctionWindow.resource = [ ]

fun! s:FunctionWindow.init_mapping()
    nnoremap <buffer> <Enter> :cal OpenPerldocWindow( substitute( getline('.') , '^\(\w\+\).*$' , '\1' , '' ) ,'-f')<CR>
endf

fun! s:FunctionWindow.init_syntax()
  "if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
      "hi CursorLine ctermbg=DarkCyan ctermfg=Black
      "hi Background ctermbg=darkblue
      syn match PerlFunctionName "^\w\+"
      syn keyword PerlType LIST FILEHANDLE VARIABLE FILEHANDLE EXPR FILENAME DIRHANDLE SOCKET NAME BLOCK NUMBER HASH ARRAY
      hi link PerlFunctionName Identifier
      hi link PerlType Type
  "endif
endf

fun! s:FunctionWindow.init_buffer()
  setfiletype perlfunctionwindow
  let self.resource = readfile( 'perl-functions' )
  cal self.render_result( self.resource )
  autocmd CursorMovedI <buffer> call s:FunctionWindow.update_search()
endf

fun! s:FunctionWindow.update_search()
  let pattern = getline('.')
  let matches = filter( copy( self.resource )  , 'v:val =~ "' . pattern . '"' )
  "if len(funcs) > g:func_max_result 
  "  let pkgs = remove( pkgs , 0 , g:cpan_max_result )
  "endif
  " XXX: refactor this
  let old = getpos('.')
  silent 2,$delete _
  cal self.render_result( matches )
  cal setpos('.',old)
  startinsert
endf

fun! s:FunctionWindow.switch_mode()

endf

com! SwitchFunctionWindowMode  :call s:FunctionWindow.switch_mode()
com! OpenFunctionWindow        :call s:FunctionWindow.open('topleft', 'split',10)

nnoremap <C-c><C-f>        :OpenFunctionWindow<CR>

" &&&& CPAN Window &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& {{{

let s:CPANWindow = copy(s:WindowManager)

fun! s:CPANWindow.init_buffer()
    setfiletype cpanwindow
    cal PrepareInstalledCPANModuleCache()
    cal self.render_result( g:cpan_installed_pkgs )
    autocmd CursorMovedI <buffer>        call s:CPANWindow.update_search()
    autocmd BufWinLeave  <buffer>         call s:CPANWindow.close()
    call self.refresh_buffer_name()
endf

fun! s:CPANWindow.buffer_reload_init()
    call self.refresh_buffer_name()
    startinsert
    call cursor( 1 , col('$')  )
endf


fun! s:CPANWindow.init_mapping()
    imap <buffer>     <Enter> <ESC>j<Enter>
    imap <buffer>     <C-t>   <ESC>jt
    imap <buffer>     <C-a>   <Esc>0i
    imap <buffer>     <C-e>   <Esc>A
    imap <buffer>     <C-b>   <Esc>i
    imap <buffer>     <C-f>   <Esc>a

    " Motion bindings
    inoremap <buffer> <C-n> <ESC>j
    nnoremap <buffer> <C-n> j
    nnoremap <buffer> <C-p> k
    nnoremap <buffer> <ESC> <C-W>q

    " Module action bindings
    imap <silent> <buffer>     <Tab>   <Esc>:SwitchCPANWindowMode<CR>
    inoremap <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/search?query=' . getline('.') . '&mode=all'<CR>
    nnoremap <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/dist/' . substitute( getline('.') , '::' , '-' , 'g' )<CR>

    nnoremap <buffer> $   :call OpenPerldocWindow(expand('<cWORD>'),'')<CR>
    nnoremap <buffer> !   :exec '!perldoc ' . expand('<cWORD>')<CR>

    nnoremap <buffer> <Enter> :call GotoModule()<CR>
    nnoremap <buffer> t       :call TabGotoModuleFileInPaths( getline('.') )<CR>
    nnoremap <buffer> I       :exec '!' . g:cpan_install_command . ' ' . getline('.')<CR>
endf

fun! s:CPANWindow.init_syntax()
    if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
        "hi CursorLine ctermbg=DarkCyan ctermfg=Black
        hi Background ctermbg=darkblue
    endif
endf

fun! s:CPANWindow.switch_mode()
    let g:cpan_win_mode = g:cpan_win_mode + 1
    if g:cpan_win_mode == 4
      let g:cpan_win_mode = 1
    endif
    call self.refresh_buffer_name()
    call self.update_search()
    call cursor( 1, col('$') )
endf

fun! s:CPANWindow.refresh_buffer_name()
    if g:cpan_win_mode == g:CPAN.Mode.Installed 
      silent file CPAN\ (Installed)
    elseif g:cpan_win_mode == g:CPAN.Mode.All
      silent file CPAN\ (All)
    elseif g:cpan_win_mode == g:CPAN.Mode.CurrentLib
      silent file CPAN\ (CurrentLib)
    endif
endf


fun! s:CPANWindow.update_search()
    let pattern = getline('.')

    let pkgs = []
    if g:cpan_win_mode == g:CPAN.Mode.Installed
      cal PrepareInstalledCPANModuleCache()
      let pkgs = filter( copy( g:cpan_installed_pkgs ) , 'v:val =~ "' . pattern . '"' )
    elseif g:cpan_win_mode == g:CPAN.Mode.All
      cal PrepareCPANModuleCache()
      let pkgs = filter( copy( g:cpan_pkgs ) , 'v:val =~ "' . pattern . '"' )
    elseif g:cpan_win_mode == g:CPAN.Mode.CurrentLib
      cal PrepareCurrentLibCPANModuleCache()
      let pkgs = filter( copy( g:cpan_curlib_pkgs ) , 'v:val =~ "' . pattern . '"' )
    endif

    if len(pkgs) > g:cpan_max_result 
      let pkgs = remove( pkgs , 0 , g:cpan_max_result )
    endif

    let old = getpos('.')
    silent 2,$delete _
    call self.render_result( pkgs )
    call setpos('.',old)
    startinsert
endfunc


fun! InstallCPANModule()
	exec '!' . g:cpan_install_command . ' ' . GetCursorModuleName()
endf

fu! GetPackageSourceListPath()
    let paths = [ 
                \expand('~/.cpanplus/02packages.details.txt.gz'),
                \expand('~/.cpan/sources/modules/02packages.details.txt.gz')
                \]
    call extend( paths , g:cpan_user_defined_sources )
    for f in paths 
      if filereadable( f ) 
        return f
      endif
    endfor
    return
endf

fu! PrepareCPANModuleCache()
    if len( g:cpan_pkgs ) == 0 
      echo "preparing cpan module list..."
      let g:cpan_pkgs = GetCPANModuleList(0)
    endif
endf
fu! PrepareInstalledCPANModuleCache()
    if len( g:cpan_installed_pkgs ) == 0 
      echo "preparing installed cpan module list..."
      let g:cpan_installed_pkgs = GetInstalledCPANModuleList(0)
    endif
endf
fu! PrepareCurrentLibCPANModuleCache()
    if len( g:cpan_curlib_pkgs ) == 0 
      echo "preparing installed cpan module list..."
      let g:cpan_curlib_pkgs = GetCurrentLibCPANModuleList(0)
    endif
endf

" Return: cpan module list [list]
fu! GetCPANModuleList(force)
  if ! filereadable( g:cpan_source_cache ) && IsExpired( g:cpan_source_cache , g:cpan_cache_expiry  ) || a:force
    let path =  GetPackageSourceListPath()
    echo "executing zcat: " . path
    call system('zcat ' . path . " | grep -v '^[0-9a-zA-Z-]*: '  | cut -d' ' -f1 > " . g:cpan_source_cache )
    echo "done"
  endif
  return readfile( g:cpan_source_cache )
endf
" Return: installed cpan module list [list]
fu! GetInstalledCPANModuleList(force)
  if ! filereadable( g:cpan_installed_cache ) && IsExpired( g:cpan_installed_cache , g:cpan_cache_expiry ) || a:force
    let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
    echo "finding packages from @INC... This might take a while. Press Ctrl-C to stop."
    call system( 'find ' . paths . ' -type f -iname "*.pm" ' 
                \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                \ . " | perl -pe 's/^package (.*?);/\$1/' "
                \ . " | sort | uniq > " . g:cpan_installed_cache )
    echo "done"
  endif
  return readfile( g:cpan_installed_cache )
endf
" Return: current lib/ cpan module list [list]
fu! GetCurrentLibCPANModuleList(force)
  let cpan_curlib_cache = expand( '~/.vim/' . tolower( substitute( getcwd() , '/' , '.' , 'g') ) )
  if ! filereadable( cpan_curlib_cache ) && IsExpired( cpan_curlib_cache , g:cpan_cache_expiry ) || a:force
    echo "finding packages... from lib/"
    call system( 'find lib -type f -iname "*.pm" ' 
                \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                \ . " | perl -pe 's/^package (.*?);/\$1/' "
                \ . " | sort | uniq > " . cpan_curlib_cache )
    echo "done"
  endif
  return readfile( cpan_curlib_cache )
endf

com! SwitchCPANWindowMode   :call s:CPANWindow.switch_mode()
com! OpenCPANWindowS        :call s:CPANWindow.open('topleft', 'split',g:cpan_win_height)
com! OpenCPANWindowSV       :call s:CPANWindow.open('topleft', 'vsplit',g:cpan_win_width)

" inoremap <C-x><C-m>  <C-R>=CompleteCPANModuleList()<CR>
inoremap <C-x><C-m>        <C-R>=CompleteInstalledCPANModuleList()<CR>
nnoremap <C-c><C-m>        :OpenCPANWindowS<CR>
nnoremap <C-c><C-v>        :OpenCPANWindowSV<CR>

" &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& }}}


" &&&& Perldoc Window &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"{{{
"
fun! OpenPerldocWindow(name,param)
    vnew
    setlocal modifiable
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal nowrap
    setlocal cursorline
    setlocal nonumber
    setlocal fdc=0
    setfiletype perldoc
    silent file Perldoc
    exec 'r !perldoc -tT ' . a:param . ' ' . a:name
    setlocal nomodifiable
    call cursor(1,1)
    resize 50
    vertical resize 82
    autocmd BufWinLeave <buffer> call ClosePerldocWindow()
endf

fun! ClosePerldocWindow()
  if g:cpan_win_type == 'v'
    exec 'vertical resize ' . g:cpan_win_width
  else
    exec 'resize ' . g:cpan_win_height
  endif
  silent 0f
  close
endf
"}}}

" Function: FindPerlPackageFiles
" Return: package [list]
fun! FindPerlPackageFiles()
    let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
    let pkgs = split("\n" , system(  'find ' . paths . ' -type f -iname *.pm ' 
                \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                \ . " | perl -pe 's/^package (.*?);/\$1/' "
                \ . " | sort | uniq " )
    return pkgs
endf

" Function header helper  {{{
" insert pod template like this:
" =head2 function 
"
"
"
" =cut
" sub test {
fu! PodHelperFunctionHeader()
  let subname = substitute( getline('.') , 'sub\s\+\(\w\+\)\s\+.*$' , '\1' , "" )
  let lines = [ 
        \ '=head2 ' . subname , 
        \ '' , 
        \ '' ,
        \ '' ,
        \ '=cut'  ,
        \ '',
        \]
  for text in lines 
    :call append( line('.') - 1 , text )
  endfor
  :call cursor( line('.') - len( lines ) + 2 , 1  )
endf
" }}}

" Completions &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"{{{
"
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
      let g:cpan_pkgs = GetCPANModuleList(0)
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
"}}}

" XXX: implement this
" Perl Completion Features:
"
" when user type '$self' or '$class' , press [key] to trigger completion function
"   (or just map '->' key to trigger completion function)
"           
"           the completion should include:
"               function name
"               accessor
"
"   then it should complete the '->' and open a completion window 
"   and list all matched items
" 
" when user type $App::Class:: , then press [key] to trigger completion function
"
"           the completion should include:
"               variable name
"
" when user type App::Class:: , then press [key] to trigger completion function
"
"           the completion should include:
"               function name
"               constants
"
" when user typing, it should automatically update the line (option)
" and update completion result in the bottom window , and highlight 
" the matched part
"
" user type C-n , C-p to select item to complete
" then press <Enter> to complete with the selected item.
" after all , the completion window should be closed
"
" Completion Window:
"
" there are more than 1 parts to list completion in perl completion window
" === BaseClass    (from 'use base qw//')
" = accessors =
" = variables =
" = constants =
" = functions =
"
" === CurrentClass (package [ ];)
" = accessors =
" = variables =
" = constants = 
" = functions =
"
"
" Function List Item Format:
"
" App::Base::Class
" [var name]
" [function name]  (line nn)
" [function name]  (line nn)
"
" App::Class
" [var name]
" [function name]  (line nn)

nnoremap <C-c>g            :call TabGotoModuleFileFromCursor()<CR>
nnoremap <C-x><C-i>        :call InstallCPANModule()<CR>
nnoremap <C-c><C-p>f       :call PodHelperFunctionHeader()<CR>

com! ReloadModuleCache              :let g:cpan_pkgs = GetCPANModuleList(1)
com! ReloadInstalledModuleCache     :let g:cpan_installed_pkgs = GetInstalledCPANModuleList(1)
com! ReloadCurrentLibModuleCache    :let g:cpan_curlib_pkgs = GetCurrentLibCPANModuleList(1)

" for testing...
" Jifty::Collection
" Data::Dumper::Simple
" AnyEvent::Impl::Perl 
