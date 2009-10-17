
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
  return matchstr( expand("<cWORD>") , g:pkg_token_pattern )
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

fun! libperl#FindPerlPackageFiles()
  let paths = 'lib ' .  system('perl -e ''print join(" ",@INC)''  ')
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





