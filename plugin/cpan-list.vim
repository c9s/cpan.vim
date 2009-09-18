
let g:mlist_filename = expand('~/.vim-cpan-modules')


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

