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
" Repository:  http://github.com/c9s/cpan-list.vim
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
" Requirement:
"
"   libperl.vim
"
"       http://github.com/c9s/libperl.vim/
"       
" Install:
"
"   $ make install 
"
" Usage:
"   CPAN Window:
"       1. 
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
"           <ESC><ESC> to close search window
"           you can also press <C-c> in insert mode to close search window too
"
"   Ctags Search Window:
"       press <C-c><C-t> to open ctags search window
"       press <Enter> to goto tag
"       press t to goto tag in a new tab
"
"   Function Search Window:
"
"       press <C-c><C-f> to open function search window
"       <C-n>,<C-p> to select result 
"       <Enter> to open perldoc window
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
"
" XXX: require version 0.3
if ! exists('g:libperl#lib_version') || g:libperl#lib_version < 0.3
  echoerr 'cpan.vim: please install libperl.vim'
  finish
endif

" we need window manager class

runtime plugin/window.vim

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
  let g:cpan_install_command = 'sudo cpanp i'
elseif executable('cpan')
  let g:cpan_install_command = 'sudo cpan'
endif
" }}}


" Common Functions"{{{


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


" &&&& Perl Function Search window &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& {{{
"
" Feature
"   built-in function name search
"
let s:FunctionWindow = copy(WindowManager)
let s:FunctionWindow.Modes = { 'BUILTIN':0 , 'PERLINTERNAL':1 }
let s:FunctionWindow.resource = [ ]

fun! s:FunctionWindow.init_mapping()
  nnoremap <silent> <buffer> <Enter> :cal OpenPerldocWindow( substitute( getline('.') , '^\(\w\+\).*$' , '\1' , '' ) ,'-f')<CR>
endf

fun! s:FunctionWindow.init_syntax()
  syn match PerlFunctionName "^\S\+"
  syn keyword PerlType LIST FILEHANDLE VARIABLE FILEHANDLE EXPR FILENAME DIRHANDLE SOCKET NAME BLOCK NUMBER HASH ARRAY
  hi link PerlFunctionName Identifier
  hi link PerlType Type
endf

fun! s:FunctionWindow.init_buffer()
  setfiletype perlfunctionwindow
  echon "Loading Function List..."
  let self.resource = readfile( expand('~/.vim/perl/perl-functions') )
  echon "Done"
  cal self.render_result( self.resource )
  autocmd CursorMovedI <buffer> call s:FunctionWindow.update_search()
  silent file Perl\ Builtin\ Functions
endf

fun! s:FunctionWindow.buffer_reload_init()
  call setline(1,'')
  call cursor(1,1)
  startinsert
endf

fun! s:FunctionWindow.update_search()
  let pattern = getline(1)
  let matches = filter( copy( self.resource )  , 'v:val =~ ''^' . pattern . '''' )
  let old = getpos('.')
  silent 2,$delete _
  cal self.render_result( matches )
  cal setpos('.',old)
  startinsert
endf

fun! s:FunctionWindow.switch_mode()
  if self.mode == 1 | let self.mode = 0 | else | let self.mode = self.mode + 1 | endif
endf


" &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"}}}


" &&&& CPAN Window &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& {{{

let s:CPANWindow = copy(WindowManager)

fun! s:CPANWindow.init_buffer()
  setfiletype cpanwindow
  cal PrepareInstalledCPANModuleCache()
  cal self.render_result( g:cpan_installed_pkgs )
  autocmd CursorMovedI <buffer>       call s:CPANWindow.update_search()
  autocmd BufWinLeave  <buffer>       call s:CPANWindow.close()
  call self.refresh_buffer_name()
endf

fun! s:CPANWindow.buffer_reload_init()
  call self.refresh_buffer_name()
  startinsert
  call cursor( 1 , col('$')  )
endf

fun! s:CPANWindow.init_mapping()
  " Module action bindings
  imap <silent> <buffer>     <Tab>   <Esc>:SwitchCPANWindowMode<CR>
  nmap <silent> <buffer>     <Tab>   :SwitchCPANWindowMode<CR>
  inoremap <silent> <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/search?query=' . getline('.') . '&mode=all'<CR>
  nnoremap <silent> <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/dist/' . substitute( getline('.') , '::' , '-' , 'g' )<CR>

  nnoremap <silent> <buffer> $   :call OpenPerldocWindow(expand('<cWORD>'),'')<CR>
  nnoremap <silent> <buffer> !   :exec '!perldoc ' . expand('<cWORD>')<CR>

  nnoremap <silent> <buffer> <Enter> :call libperl#open_module()<CR>
  nnoremap <silent> <buffer> t       :call tab_open_module_file_in_paths( getline('.') )<CR>
  nnoremap <silent> <buffer> I       :exec '!' . g:cpan_install_command . ' ' . getline('.')<CR>
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
  let pattern = getline(1)
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

fu! PrepareCPANModuleCache()
  if len( g:cpan_pkgs ) == 0 
    cal libperl#echo( "preparing cpan module list...")
    let g:cpan_pkgs = libperl#get_cpan_module_list(0)
  endif
endf
fu! PrepareInstalledCPANModuleCache()
  if len( g:cpan_installed_pkgs ) == 0 
    cal libperl#echo("preparing installed cpan module list...")
    let g:cpan_installed_pkgs = libperl#get_installed_cpan_module_list(0)
  endif
endf
fu! PrepareCurrentLibCPANModuleCache()
  if len( g:cpan_curlib_pkgs ) == 0 
    cal libperl#echo("preparing currentlib cpan module list...")
    let g:cpan_curlib_pkgs = libperl#get_currentlib_cpan_module_list(0)
  endif
endf

" Return: installed cpan module list [list]
fu! libperl#get_installed_cpan_module_list(force)
  if ! filereadable( g:cpan_installed_cache ) && IsExpired( g:cpan_installed_cache , g:cpan_cache_expiry ) || a:force
    let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
    call libperl#echo("finding packages from @INC... This might take a while. Press Ctrl-C to stop.")
    call system( 'find ' . paths . ' -type f -iname "*.pm" ' 
          \ . " | xargs -I{} head {} | egrep -o 'package [_a-zA-Z0-9:]+;' "
          \ . " | perl -pe 's/^package (.*?);/\$1/' "
          \ . " | sort | uniq > " . g:cpan_installed_cache )
    " sed  's/^package //' | sed 's/;$//'
    call libperl#echo("ready")
  endif
  return readfile( g:cpan_installed_cache )
endf

" Return: current lib/ cpan module list [list]
fu! libperl#get_currentlib_cpan_module_list(force)
  let cpan_curlib_cache = expand( '~/.vim/' . tolower( substitute( getcwd() , '/' , '.' , 'g') ) )
  if ! filereadable( cpan_curlib_cache ) && IsExpired( cpan_curlib_cache , g:cpan_cache_expiry ) || a:force
    call libperl#echo( "finding packages... from lib/" )
    call system( 'find lib -type f -iname "*.pm" ' 
          \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
          \ . " | perl -pe 's/^package (.*?);/\$1/' "
          \ . " | sort | uniq > " . cpan_curlib_cache )
    call libperl#echo('cached')
  endif
  return readfile( cpan_curlib_cache )
endf


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

  syn match HEADER +^\w.*$+
  syn match STRING +".\{-}"+
  syn match STRING2 +'.\{-}'+
  hi link HEADER Identifier
  hi link STRING Comment
  hi link STRING2 Comment

  setlocal nomodifiable
  call cursor(1,1)
  resize 50
  vertical resize 82
  autocmd BufWinLeave <buffer> call ClosePerldocWindow()
  nmap <buffer> <ESC> <C-W>q
endf

fun! ClosePerldocWindow()
  " resize back
  if g:cpan_win_type == 'v'
    exec 'vertical resize ' . g:cpan_win_width
  else
    exec 'resize ' . g:cpan_win_height
  endif
  bw
  redraw
endf
"}}}



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
    call append( line('.') - 1 , text )
  endfor
  call cursor( line('.') - len( lines ) + 2 , 1  )
endf
" }}}



" Completions &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"{{{
"
fu! CompleteInstalledCPANModuleList()
  cal PrepareInstalledCPANModuleCache()
  let start_pos  = libperl#get_pkg_comp_start()
  let base = libperl#get_pkg_comp_base()
  echon "filtering..."
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
    echon "preparing cpan module list..."
    let g:cpan_pkgs = libperl#get_cpan_module_list(0)
    echon "done"
  endif
  let start_pos  = libperl#get_pkg_comp_start()
  let base = libperl#get_pkg_comp_base()
  echon "filtering..."
  let res = filter( copy( g:cpan_pkgs ) , 'v:val =~ "' . base . '"' )
  call complete( start_pos[1]+1 , res )
  return ''
endf

"}}}
"
"
com! SwitchFunctionWindowMode  :call s:FunctionWindow.switch_mode()
com! OpenFunctionWindow        :call s:FunctionWindow.open('topleft', 'split',10)
nnoremap <C-c><C-f>        :OpenFunctionWindow<CR>



com! SwitchCPANWindowMode   :call s:CPANWindow.switch_mode()
com! OpenCPANWindowS        :call s:CPANWindow.open('topleft', 'split',g:cpan_win_height)
com! OpenCPANWindowSV       :call s:CPANWindow.open('topleft', 'vsplit',g:cpan_win_width)

" inoremap <C-x><C-m>  <C-R>=CompleteCPANModuleList()<CR>
inoremap <C-x><C-m>        <C-R>=CompleteInstalledCPANModuleList()<CR>
nnoremap <silent> <C-c><C-m>        :OpenCPANWindowS<CR>
nnoremap <silent> <C-c><C-v>        :OpenCPANWindowSV<CR>


nnoremap <C-x><C-i>        :call libperl#install_module()<CR>
nnoremap <C-c>g            :call libperl#tab_open_module_from_cursor()<CR>
nnoremap <C-c><C-p>f       :call PodHelperFunctionHeader()<CR>

com! ReloadModuleCache              :let g:cpan_pkgs = libperl#get_cpan_module_list(1)
com! ReloadInstalledModuleCache     :let g:cpan_installed_pkgs = libperl#get_installed_cpan_module_list(1)
com! ReloadCurrentLibModuleCache    :let g:cpan_curlib_pkgs = libperl#get_currentlib_cpan_module_list(1)
