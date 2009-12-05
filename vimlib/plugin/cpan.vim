" cpan.vim
"
"
"
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
"
" Author: Cornelius <cornelius.howl@DELETE-ME.gmail.com>
" Version: 2.2
"
" Site: http://oulixe.us/
" Date: Sun Sep 19 10:47:15 2009
"
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
" Configuration:
"
"        g:cpan_browser_command  : command for launching browser
"        g:cpan_win_type         : v (vertical) or s (horizontal) cpan window
"        g:cpan_win_width     
"        g:cpan_win_height     
"        self.search_mode         : default cpan window mode 
"                             (search installed modules or all modules or currentlib ./lib)
"        g:cpan_install_command  : command for installing cpan modules
"
" &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
" }}}
"
if ! exists('g:libperl#lib_version') || g:libperl#lib_version < 0.6
  echoerr 'cpan.vim: please install libperl.vim 0.6'
  finish
endif

fun! s:echo(msg)
  redraw
  echo a:msg
endf

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
let g:cpan_win_type = 'vsplit'   " v (vertical) or s (split)
let g:cpan_win_width = 20
let g:cpan_win_height = 10
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

cal perldoc#load()

" &&&& CPAN Window &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& {{{
let s:CPANWindow = copy( swindow#class )
let s:CPANWindow.search_mode = g:CPAN.Mode.Installed

fun! s:CPANWindow.init_buffer()
  setfiletype cpanwindow
  autocmd CursorMovedI <buffer>       call s:CPANWindow.update()
  autocmd BufWinLeave  <buffer>       call s:CPANWindow.close()
  cal self.buffer_name()
endf

fun! s:CPANWindow.index()
  if self.search_mode == g:CPAN.Mode.Installed
    return libperl#get_cpan_installed_module_list(0)
  elseif self.search_mode == g:CPAN.Mode.All
    return libperl#get_cpan_module_list(0)
  elseif self.search_mode == g:CPAN.Mode.CurrentLib
    return libperl#get_currentlib_cpan_module_list(0)
  else
    return [ ]
  endif
endf

fun! s:CPANWindow.buffer_reload_init()
  call self.buffer_name()
  startinsert
  call cursor( 1 , col('$')  )
endf

fun! s:CPANWindow.init_mapping()
  " Module action bindings
  imap <silent> <buffer>     <Tab>   <Esc>:SwitchCPANWindowMode<CR>
  nmap <silent> <buffer>     <Tab>   :SwitchCPANWindowMode<CR>
  inoremap <silent> <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/search?query=' . getline('.') . '&mode=all'<CR>
  nnoremap <silent> <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/dist/' . substitute( getline('.') , '::' , '-' , 'g' )<CR>

  " XXX: rewrite as command
  " XXX: better key mapping rule.....
  nnoremap <silent> <buffer> p   :call  g:perldoc.open_tab(expand('<cWORD>'),'',0)<CR>
  nnoremap <silent> <buffer> P   :call  g:perldoc.open_tab(expand('<cWORD>'),'',1)<CR>

  nnoremap <silent> <buffer> $   :call  g:perldoc.open(expand('<cWORD>'),'')<CR>

  nnoremap <silent> <buffer> !   :exec '!perldoc ' . expand('<cWORD>')<CR>
  nnoremap <silent> <buffer> f   :exec '!sudo cpanf ' . expand('<cWORD>')<CR>

  nnoremap <silent> <buffer> <Enter> :call libperl#open_module()<CR>
  nnoremap <silent> <buffer> t       :call libperl#tab_open_module_file_in_paths( getline('.') )<CR>
  nnoremap <silent> <buffer> I       :exec '!' . g:cpan_install_command . ' ' . getline('.')<CR>
endf

fun! s:CPANWindow.switch_mode()
  let self.search_mode = self.search_mode + 1
  if self.search_mode == 4
    let self.search_mode = 1
  endif
  call self.buffer_name()

  " update predefined result
  let self.predefined_index = self.index()
  cal self.update()
  cal cursor( 1, col('$') )
endf

fun! s:CPANWindow.buffer_name()
  if self.search_mode == g:CPAN.Mode.Installed 
    silent file CPAN\ (Installed)
  elseif self.search_mode == g:CPAN.Mode.All
    silent file CPAN\ (All)
  elseif self.search_mode == g:CPAN.Mode.CurrentLib
    silent file CPAN\ (CurrentLib)
  endif
endf



" &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& }}}

" Completions &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"{{{
"
fu! CompleteInstalledCPANModuleList()
  cal PrepareInstalledCPANModuleCache()
  let start_pos  = libperl#get_pkg_comp_start()
  let base = libperl#get_pkg_comp_base()
  call s:echo( "filtering..." )
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
    cal s:echo("preparing cpan module list...")
    let g:cpan_pkgs = libperl#get_cpan_module_list(0)
    cal s:echo("done")
  endif
  let start_pos  = libperl#get_pkg_comp_start()
  let base = libperl#get_pkg_comp_base()
  cal s:echo("filtering")
  let res = filter( copy( g:cpan_pkgs ) , 'v:val =~ "' . base . '"' )
  cal complete( start_pos[1]+1 , res )
  return ''
endf

"}}}
com! SwitchCPANWindowMode   :call s:CPANWindow.switch_mode()
com! OpenCPANWindowS        :call s:CPANWindow.open('topleft', 'split',g:cpan_win_height)
com! OpenCPANWindowSV       :call s:CPANWindow.open('topleft', 'vsplit',g:cpan_win_width)

com! ReloadModuleCache              :cal libperl#get_cpan_module_list(1)
com! ReloadInstalledModuleCache     :cal libperl#get_cpan_installed_module_list(1)
com! ReloadCurrentLibModuleCache    :cal libperl#get_currentlib_cpan_module_list(1)

" inoremap <C-x><C-m>  <C-R>=CompleteCPANModuleList()<CR>
" inoremap <C-x><C-m>                 <C-R>=CompleteInstalledCPANModuleList()<CR>
" nnoremap <silent> <C-c><C-m>        :OpenCPANWindowS<CR>
" nnoremap <silent> <C-c><C-v>        :OpenCPANWindowSV<CR>
" nnoremap <C-x><C-i>        :call libperl#install_module()<CR>
" nnoremap <C-c>g            :call libperl#tab_open_module_from_cursor()<CR>
