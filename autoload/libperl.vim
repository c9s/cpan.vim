
" vim:fdm=syntax:fdl=0:
" let g:libperl#pkg_token_pattern = '\w[a-zA-Z0-9:_]\+'
let g:libperl#pkg_token_pattern = '\w[a-zA-Z0-9:_]\+'

fun! libperl#echo(msg)
  redraw
  echomsg a:msg
endf

fun! libperl#GetPerlLibPaths()
  return split( system('perl -e ''print join "\n",@INC''') , "\n" ) 
endf

fun! libperl#GetModuleFilePath(mod)
  let paths = libperl#GetPerlLibPaths()
  let fname = libperl#TranslateModuleName( a:mod )
  call insert(paths,'lib/')
  for p in paths
    let fullpath = p . '/' . fname
    if filereadable( fullpath ) 
      return fullpath
    endif
  endfor
  return 
endf

fun! libperl#TabGotoModuleFileInPaths(mod)
  let paths = libperl#GetPerlLibPaths()
  let fname = libperl#TranslateModuleName( a:mod )
  let methodname = libperl#GetCursorMethodName()
  let path = libperl#GetModuleFilePath( a:mod )
  if filereadable( path ) 
    call TabGotoFile( path , methodname ) 
  endif
endf

" translate module name to file path
fun! libperl#TranslateModuleName(n)
  return substitute( a:n , '::' , '/' , 'g' ) . '.pm'
endf

fun! libperl#GotoTagNewTab(tag)
  let list = taglist( a:tag )
  if len(list) == 1 | exec 'tab tag ' . a:tag
  else | exec 'tab ts ' . a:tag | endif
endf

fun! libperl#GotoTag(tag)
  resize 60 
  let list = taglist( a:tag )
  if len(list) == 1 | exec ' tag ' . a:tag
  else | exec ' ts ' . a:tag | endif
endf

fun! libperl#GotoModule()
  if g:cpan_win_type == 'v'
    vertical resize 98
  else
    resize 60
  endif
  call libperl#GotoModuleFileInPaths( getline('.') )
endf

fun! libperl#GetCursorModuleName()
  return matchstr( expand("<cWORD>") , g:libperl#pkg_token_pattern )
endf

fun! libperl#GetCursorMethodName()
  let cw = expand("<cWORD>")
  let m = substitute( cw , '.\{-}\([a-zA-Z0-9_:]\+\)->\(\w\+\).*$' , '\2' , '' )
  if m != cw 
    return m
  endif
  return
endf

fun! libperl#GotoFile(fullpath,method)
  execute ':e ' . a:fullpath
  if strlen(a:method) > 0
    call search( '^sub\s\+' . a:method . '\s' , '', 0 )
  endif
  return 1
endf

fun! libperl#TabGotoModuleFileFromCursor()
  call libperl#TabGotoModuleFileInPaths( libperl#GetCursorModuleName() )
endf

fun! libperl#GotoModuleFileInPaths(mod)
  let paths = libperl#GetPerlLibPaths()
  let fname = libperl#TranslateModuleName( a:mod )
  let methodname = libperl#GetCursorMethodName()
  call insert(paths, 'lib/' )
  for p in paths 
    let fullpath = p . '/' . fname
    if filereadable( fullpath ) && libperl#GotoFile( fullpath , methodname ) 
      return
    endif
  endfor
  echomsg "No such module: " . a:mod
endf

fun! libperl#GetINC()
  return system('perl -e ''print join(" ",@INC)'' ')
endf

fun! libperl#FindPerlPackageFiles()
  let paths = 'lib ' .  libperl#GetINC()
  let pkgs = split("\n" , system(  'find ' . paths . ' -type f -iname *.pm ' 
        \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
        \ . " | perl -pe 's/^package (.*?);/\$1/' "
        \ . " | sort | uniq " )
  return pkgs
endf

" please defined g:cpan_install_command to install module 
fun! libperl#InstallCPANModule()
  exec '!' . g:cpan_install_command . ' ' . libperl#GetCursorModuleName()
endf

fu! libperl#GetPackageSourceListPath()
  let paths = [ 
        \expand('~/.cpanplus/02packages.details.txt.gz'),
        \expand('~/.cpan/sources/modules/02packages.details.txt.gz')
        \]
  if exists('g:cpan_user_defined_sources')
    call extend( paths , g:cpan_user_defined_sources )
  endif

  for f in paths 
    if filereadable( f ) 
      return f
    endif
  endfor
  return
endf


" return a list , each item contains two items : [ class , file ].
fun! libperl#find_base_classes(file)
  let script_path = expand('$HOME') . '/.vim/bin/find_base_classes.pl'
  if ! filereadable( script_path )
    echoerr 'can not read ' . script_path
    return [ ]
  endif
  let out = system('perl ' . script_path . ' ' . a:file)
  let classes = [ ]
  for l in split(out,"\n") 
    let [class,refer,path] = split(l,' ')
    call add(classes,[class,refer,path])
  endfor
  return classes
endf

" XXX: Try PPI
fun! libperl#grep_file_functions(file)
  let out = system('grep -oP "(?<=^sub )\w+" ' . a:file )
  return split( out , "\n" )
endf

fun! libperl#parse_base_class_functions(filepath)
  let base_classes = libperl#find_base_classes( a:filepath ) 
  let result = [ ]
  for [class,class_refer,path] in base_classes
    let class_comp = { 'class': class , 'refer': class_refer , 'functions': [ ] }
    let class_comp.functions = libperl#grep_file_functions( path )
    call add( result , class_comp )
  endfor
  return result
endf

" Data::Dumper->something
" $self->something
" Jifty->
" Jifty->a

" should get the start postion of something like Data::Dumper and $self
fun! libperl#get_method_comp_refer_start()
  return searchpos( '\S\+\(->\)\@='  , 'bn' , line('.') )
endf

" should return something like 'Data::Dumper' and '$self'
fun! libperl#get_method_comp_refer_base()
  let start = libperl#get_method_comp_refer_start()
  let end = libperl#get_method_comp_start()
  if start[0] == 0 && start[1] == 0
    return ""
  endif
  return strpart( getline('.') , start[1] - 1 , end[1] - 2 - start[1] )
endf

fun! libperl#get_method_comp_start()
  let pos = searchpos( '->'  , 'bn' , line('.') )
  let pos[1] += 2
  return pos
endf

fun! libperl#get_method_comp_base()
  let [lnum,coln] = libperl#get_method_comp_start()
  if lnum == 0 && coln == 0
    return ""
  endif
  return strpart( getline('.') , coln - 1 , col('.') - coln + 1 )
endf

fun! libperl#clear_method_comp_base()
  let [numl,coln] = libperl#get_method_comp_start()
  let new = strpart( getline('.') , 0 , coln - 1 )
  call setline( line('.') , new )
endf

" return [ lnum , col ]
fu! libperl#get_pkg_comp_start()
  return searchpos( '[^a-zA-Z0-9:_]' , 'bn' , line('.') )
endf

" return comp base string
fu! libperl#get_pkg_comp_base()
  let col = col('.')
  let [ lnum , coln ] = libperl#get_pkg_comp_start()
  let line = getline('.')
  return strpart( getline('.') , coln , col )
endf
