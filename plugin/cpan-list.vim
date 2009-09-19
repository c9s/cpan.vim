
" vim:fdm=marker:
let g:mlist_filename = expand('~/.vim-cpan-modules')

" {{{
fu! s:GetCursorModuleName()
  let cw = substitute( expand("<cWORD>") , '.\{-}\([a-zA-Z0-9_:]\+\).*$' , '\1' , '' )
  return cw
endf

fu! s:GetMethodName()
  let cw = expand("<cWORD>")
  let m = substitute( cw , '.\{-}\([a-zA-Z0-9_:]\+\)->\(\w\+\).*$' , '\2' , '' )
  if m != cw 
    return m
  else
    return
  endif
endf

fu! s:TranslateModuleName(n)
  return substitute( a:n , '::' , '/' , 'g' ) . '.pm'
endf

fu! s:GetPerlLibPaths()
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
    let mod = call s:GetCursorModuleName()
    call s:GotoModuleFileInPaths( mod )
endf

fu! s:GotoModuleFileInPaths(mod)
  let paths = s:GetPerlLibPaths()
  let fname = s:TranslateModuleName( a:mod )
  let methodname = s:GetMethodName()
  call insert(paths, 'lib/' )
  for p in paths 
    let fullpath = p . '/' . fname
    if filereadable( fullpath ) && GotoFile( fullpath , methodname ) 
      break
    endif
  endfor
endf
" }}}

fu! ReadModule()
  resize 50
  call s:GotoModuleFileInPaths( getline('.') )
endf

fu! s:InitMapping()
    inoremap <buffer> <Enter> <ESC>:call SearchCPANModule()<CR>
    nnoremap <buffer> <Enter> :call ReadModule()<CR>
    inoremap <buffer> <C-n> <ESC>j

    nnoremap <buffer> <C-n> j
    nnoremap <buffer> <C-p> k

    " http://search.cpan.org/search?query=Data%3A%3ADumper&mode=all&sourceid=Mozilla-search
    nnoremap <buffer> @   :exec '!open -a Firefox http://search.cpan.org/search?query=' . expand('<cWORD>') . '&mode=all'<CR>
endf

fu! s:InitSyntax()
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
    setfiletype cpanwindow
    let g:pkg_cache = GetCPANModuleList()
    call s:RenderResult( g:pkg_cache )
    call cursor( 1, 1 )
    call s:InitMapping()
    call s:InitSyntax()
    startinsert
endf

fu! SearchCPANModule()
    let pattern = getline('.')
    let pkgs = filter( copy( g:pkg_cache ) , 'v:val =~ "' . pattern . '"' )

    let old = getpos('.')
    silent 2,$delete _
    call s:RenderResult( pkgs )

    call setpos('.',old)
    startinsert
    call cursor(line("."), col(".") + 1)
endfunc

fu! s:RenderResult(pkgs)
    let @o = join( a:pkgs , "\n" )
    silent put o
endf

call OpenModuleWindow()

fu! FindCPANModules()
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
        let pkgs = FindCPANModules()
        call writefile( pkgs , g:mlist_filename )
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

" AnyEvent::Impl::Qt::Timer
" AnyEvent::Impl::Perl

