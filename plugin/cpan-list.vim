
let g:mlist_filename = expand('~/.vim-cpan-modules')

fu! s:InitMapping()
    inoremap <buffer> <Enter> <ESC>:call SearchCPANModule()<CR>
    inoremap <buffer> <C-n> <ESC>:call SelectResult()<CR>
endf

fu! OpenModuleWindow()
    9new
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal nowrap
    setlocal cursorline
    " hi CursorLine ctermbg=DarkCyan ctermfg=Black
    let g:pkg_cache = GetCPANModuleList()
    call s:RenderResult( g:pkg_cache )
    call cursor( 1, 1 )
    startinsert
    call s:InitMapping()
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

