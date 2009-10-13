" vim:fdm=marker:et:sw=2:
"
" XXX: implement this
" Perl Completion Features:"{{{
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
"}}}

" require cpan.vim
source plugin/window.vim

let s:PLCompletionWindow = copy(WindowManager)

fun! s:PLCompletionWindow.open(pos,type,size,from)
  call self.split(a:pos,a:type,a:size)
  let self.from = a:from
endf

endf

fun! s:PLCompletionWindow.init_buffer()
  setfiletype PLCompletionWindow
  "cal PrepareInstalledCPANModuleCache()
  "cal self.render_result( g:cpan_installed_pkgs )

  " if it's from $self or $class, parse subroutines from current file
  " and parse parent packages , the maxima is by class depth


  " if it's from PACKAGE::SOMETHING , find the package file , and parse
  " subrouteins from the file , and the parent packages


  " if it's from $PACKAGE::Some.. , find the PACAKGE file , and parse 
  " the variables from the file . and the parent packages



  autocmd CursorMovedI <buffer>       call s:PLCompletionWindow.update_search()
  autocmd BufWinLeave  <buffer>       call s:PLCompletionWindow.close()
  call self.refresh_buffer_name()
endf

com! OpenPLCompletionWindow        :call s:PLCompletionWindow.open('botright', 'split',10,getline('.'))
inoremap <C-f>  <ESC>:OpenPLCompletionWindow<CR>


"
"fun! s:PLCompletionWindow.buffer_reload_init()
"  call self.refresh_buffer_name()
"  startinsert
"  call cursor( 1 , col('$')  )
"endf
"
"fun! s:PLCompletionWindow.init_mapping()
"  " Module action bindings
"  imap <silent> <buffer>     <Tab>   <Esc>:SwitchPLCompletionWindowMode<CR>
"  nmap <silent> <buffer>     <Tab>   :SwitchPLCompletionWindowMode<CR>
"  inoremap <silent> <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/search?query=' . getline('.') . '&mode=all'<CR>
"  nnoremap <silent> <buffer> @   <ESC>:exec '!' .g:cpan_browser_command . ' http://search.cpan.org/dist/' . substitute( getline('.') , '::' , '-' , 'g' )<CR>
"
"  nnoremap <silent> <buffer> $   :call OpenPerldocWindow(expand('<cWORD>'),'')<CR>
"  nnoremap <silent> <buffer> !   :exec '!perldoc ' . expand('<cWORD>')<CR>
"
"  nnoremap <silent> <buffer> <Enter> :call GotoModule()<CR>
"  nnoremap <silent> <buffer> t       :call TabGotoModuleFileInPaths( getline('.') )<CR>
"  nnoremap <silent> <buffer> I       :exec '!' . g:cpan_install_command . ' ' . getline('.')<CR>
"endf
"
"fun! s:PLCompletionWindow.init_syntax()
"  if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
"    "hi CursorLine ctermbg=DarkCyan ctermfg=Black
"    "hi Background ctermbg=darkblue
"  endif
"endf
"
"fun! s:PLCompletionWindow.switch_mode()
"  let g:cpan_win_mode = g:cpan_win_mode + 1
"  if g:cpan_win_mode == 4
"    let g:cpan_win_mode = 1
"  endif
"  call self.refresh_buffer_name()
"  call self.update_search()
"  call cursor( 1, col('$') )
"endf
"
"fun! s:PLCompletionWindow.refresh_buffer_name()
"  if g:cpan_win_mode == g:CPAN.Mode.Installed 
"    silent file CPAN\ (Installed)
"  elseif g:cpan_win_mode == g:CPAN.Mode.All
"    silent file CPAN\ (All)
"  elseif g:cpan_win_mode == g:CPAN.Mode.CurrentLib
"    silent file CPAN\ (CurrentLib)
"  endif
"endf
"
"
"fun! s:PLCompletionWindow.update_search()
"  let pattern = getline('.')
"
"  let pkgs = []
"  if g:cpan_win_mode == g:CPAN.Mode.Installed
"    cal PrepareInstalledCPANModuleCache()
"    let pkgs = filter( copy( g:cpan_installed_pkgs ) , 'v:val =~ "' . pattern . '"' )
"  elseif g:cpan_win_mode == g:CPAN.Mode.All
"    cal PrepareCPANModuleCache()
"    let pkgs = filter( copy( g:cpan_pkgs ) , 'v:val =~ "' . pattern . '"' )
"  elseif g:cpan_win_mode == g:CPAN.Mode.CurrentLib
"    cal PrepareCurrentLibCPANModuleCache()
"    let pkgs = filter( copy( g:cpan_curlib_pkgs ) , 'v:val =~ "' . pattern . '"' )
"  endif
"
"  if len(pkgs) > g:cpan_max_result 
"    let pkgs = remove( pkgs , 0 , g:cpan_max_result )
"  endif
"
"  let old = getpos('.')
"  silent 2,$delete _
"  call self.render_result( pkgs )
"  call setpos('.',old)
"  startinsert
"endfunc
"
"
