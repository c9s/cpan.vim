" vim:fdm=marker:et:sw=2:
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

runtime! plugin/window.vim

let g:plc_max_entries_per_class = 5

let g:PLCompletionWindow = copy( WindowManager )
let g:PLCompletionWindow.resource = { }

fun! g:PLCompletionWindow.open(pos,type,size,from)
  let self.from = a:from
  let self.current_file = expand('%')
  call self.split(a:pos,a:type,a:size)
endf

fun! g:PLCompletionWindow.close()
  bw  " we should clean up buffer in each completion
  redraw
endf



" XXX: 
"   should save completion base position
"   and do complete from base position
"
fun! g:PLCompletionWindow.init_buffer()
  let from = self.from
  let pos = match( from , '\S*$' , )
  let lastkey = strpart( from , pos )

  let matches = { }

  " if it's from $self or $class, parse subroutines from current file
  " and parse parent packages , the maxima is by class depth
  if lastkey =~ '\$\(self\|class\)->' 
    let self.resource[ "self" ] = self.grep_file_functions( self.current_file )

    " grep function from base class
    let base_classes = self.find_base_class_files( self.current_file ) 
    for [class,path] in base_classes
      let self.resource[ class ] = self.grep_file_functions( path )
    endfor

  " if it's from PACKAGE::SOMETHING , find the package file , and parse
  " subrouteins from the file , and the parent packages
  elseif lastkey =~ g:pkg_token_pattern . '->'
    let pkg = matchstr( lastkey , g:pkg_token_pattern )
    let filepath = GetModuleFilePath(pkg)
    let self.resource[ pkg ] = self.grep_file_functions( filepath )
  " XXX
  " if it's from $PACKAGE::Some.. , find the PACAKGE file , and parse 
  " the variables from the file . and the parent packages
  else
    echo 'nothing to do'
  endif

  setfiletype PLCompletionWindow

  call append(0, [">> PerlCompletion Window: Complete:<Enter>  Next/Previous Class:<Ctrl-j>/<Ctrl-k>  Next/Previous Entry:<Ctrl-n>/<Ctrl-p> ",""])

  cal self.render_result( self.resource )

  autocmd CursorMovedI <buffer>       call g:PLCompletionWindow.update_search()
  autocmd BufWinLeave  <buffer>       call g:PLCompletionWindow.close()
  " call self.refresh_buffer_name()
  silent file PerlCompletion
endf

fun! g:PLCompletionWindow.start()
  call cursor(2,1)
  startinsert
endf

fun! g:PLCompletionWindow.find_base_class_files(file)
  let out = system('perl ' . expand('$HOME') . '/.vim/bin/find_base_classes.pl ' . a:file)
  let classes = [ ]
  for l in split(out,"\n") 
    let [class,path] = split(l,' ')
    call insert(classes,[ class,path ])
  endfor
  return classes
endf

" when pattern is empty , should display all entries
fun! g:PLCompletionWindow.grep_entries(entries,pattern) 
  let result = { }
  for k in keys( a:entries )
    let result[ k ] = filter( copy( a:entries[ k ] ) , 'v:val =~ ''^' . a:pattern . '''' )
    if strlen( a:pattern ) > 0 && len( result[k] ) > g:plc_max_entries_per_class 
      let result[k] = remove( result[k] , 0 , g:plc_max_entries_per_class )
    endif
  endfor
  return result
endf

fun! g:PLCompletionWindow.render_result(matches)
  let out = ''
  let f_pad = "\n  "
  for k in keys( a:matches ) 
    let out .= k . f_pad . join( a:matches[k] ,  f_pad ) . "\n"
  endfor
  silent put=out
endf

" XXX: Try PPI
fun! g:PLCompletionWindow.grep_file_functions(file)
  let out = system('grep -oP "(?<=^sub )\w+" ' . a:file )
  return split( out , "\n" )
endf

fun! g:PLCompletionWindow.update_search()
  let pattern = getline( 2 )
  let matches = self.grep_entries( self.resource , pattern )
  let old = getpos('.')
  silent 3,$delete _
  cal self.render_result( matches )
  cal setpos('.',old)
  startinsert
endf

fun! g:PLCompletionWindow.init_syntax()
  if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
    syn match EntryHeader +^[a-zA-Z0-9:_]\++
    syn match EntryItem   +^\s\s\w\++
    hi EntryHeader ctermfg=magenta
    hi EntryItem ctermfg=cyan
  endif
endf


fun! g:PLCompletionWindow.do_complete()
  let line = getline('.')
  let pos = match( line , '\w\+' )
  if line =~ '^\s\s'   " function entry 
    let entry = strpart( line , pos )
    bw
    call setline( line('.') , getline('.') . entry . '()' )
    startinsert
    call cursor( line('.') , col('$') - 1 )
  endif
endf

fun! g:PLCompletionWindow.init_mapping()
  nnoremap <silent> <buffer> <Enter> :call g:PLCompletionWindow.do_complete()<CR>
  inoremap <silent> <buffer> <Enter> <ESC>jj:call g:PLCompletionWindow.do_complete()<CR>

  nnoremap <silent> <buffer> <C-j> :call search('^[a-zA-Z]')<CR>
  nnoremap <silent> <buffer> <C-k> :call search('^[a-zA-Z]','b')<CR>

  inoremap <silent> <buffer> <C-j> <ESC>:call search('^[a-zA-Z]')<CR>
  inoremap <silent> <buffer> <C-k> <ESC>:call search('^[a-zA-Z]','b')<CR>
endf

com! OpenPLCompletionWindow        :call g:PLCompletionWindow.open('botright', 'split',10,getline('.'))
inoremap <C-x><C-x>                <ESC>:OpenPLCompletionWindow<CR>
