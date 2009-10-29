

" &&&& CTags Search Window &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& {{{
" try to log ./tags or other matches file name
" or load preconfigured tag files
" load first 2 columns (tagname and file) from tags file
"
" grep tags
" search tags
"
"   Enter to goto tag
"   t to open the tag in new tabpage

let s:CtagsWindow = copy( swindow#class )
let s:CtagsWindow.resource = [ ]
let s:CtagsWindow.default_ctags = 'tags'  " default ctags filename to write 
let s:CtagsWindow.tagfiles = [ "tags" ]   " for searching tags file in different names
let s:CtagsWindow.max_item = 100

fun! s:echo(msg)
  echomsg a:msg
  redraw
endf

fun! s:CtagsWindow.init_mapping()
  " XXX: should remove dependency from libperl
  nnoremap <silent> <buffer> t       :call libperl#tab_open_tag(getline('.'))<CR>
  nnoremap <silent> <buffer> <Enter> :call libperl#open_tag(getline('.'))<CR>
  nnoremap <silent> <buffer> <C-R>   :GenCtags<CR>
endf

fun! s:CtagsWindow.init_syntax()
  setlocal syntax=tags
endf

fun! s:CtagsWindow.input_path_for_ctags()
  let path = input("tags file not found. enter your source path to generate ctags:" , "" ,  "dir")
  if strlen(path) > 0
    retu self.generate_ctags_file(expand(path))
  endif
endf

fun! s:CtagsWindow.init_buffer()
  setfiletype ctagsearch
  let file = self.find_ctags_file()

  if ! filereadable(file)
    let file = self.input_path_for_ctags()
  endif

  if ! filereadable(file)
    throw "ERROR: not ctags file specified"
  endif

  cal s:echo( "Loading TagList..." )
  let self.resource = self.read_tags(file)   " XXX let it be configurable
  cal s:echo( "Rendering..." )

  let matches = copy( self.resource )

  if len( matches ) > self.max_item 
    let matches = remove( matches ,0, self.max_item) 
  endif

  cal self.render_result( matches )  " just take out first 100 items
  cal s:echo( "Ready" )
  autocmd CursorMovedI <buffer> call s:CtagsWindow.update_search()

  silent file CtagsSearch
endf

fun! s:CtagsWindow.generate_ctags_file(path)
  let f = self.default_ctags
  cal s:echo("Generating...")
  call system("ctags -f " . f . " -R " . a:path)
  cal s:echo("Done")
  return f
endf

fun! s:CtagsWindow.find_ctags_file()
  for file in self.tagfiles 
    if filereadable( file ) | return file | endif
  endfor
endf

fun! s:CtagsWindow.read_tags(file)
  let ret = system("cat " . a:file . " | grep -v '^!'  | cut -f 1 | sort | uniq")
  return split(ret,'\n')
endf

fun! s:CtagsWindow.buffer_reload_init()
  call setline(1,'')
  call cursor(1,1)
  startinsert
endf

fun! s:CtagsWindow.update_search()
  let pattern = getline('.')
  let matches = filter( copy( self.resource )  , 'v:val =~ ''' . pattern . '''' )
  if len(matches) > 100 
    call remove( matches , 0 , 100 )
  endif

  let old = getpos('.')

  if len(matches) > 0 
    silent 2,$delete _
    cal self.render_result( matches )
  endif

  cal setpos('.',old)
  startinsert
endf

fun! s:CtagsWindow.switch_mode()
  if self.mode == 1 
    let self.mode = 0
  else 
    let self.mode = self.mode + 1
  endif
endf

com! OpenCtagsWindow        :call s:CtagsWindow.open('topleft', 'split',10)
com! GenCtags               :call s:CtagsWindow.input_path_for_ctags()
nnoremap <C-c><C-t>        :OpenCtagsWindow<CR>

"}}}
