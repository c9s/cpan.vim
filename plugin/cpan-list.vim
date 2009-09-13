
let g:mlist_filename = expand('~/.vim-cpan-modules')

fu! FecthCPANModuleList()
    let pkgs = [ ]
    if filereadable( g:mlist_filename )
        let pkgs = readfile( g:mlist_filename )
    else
        let paths = system('perl -e ''print join(" ",@INC)''  ')
        let pkgs = split("\n" , system(  'find ' . paths . ' -type f -iname *.pm ' 
                    \ . " | xargs -I{} egrep -o 'package [_a-zA-Z0-9:]+;' {} "
                    \ . " | perl -pe 's/^package (.*?);/\$1/' "
                    \ . " | sort | uniq " )
        call writefile( pkgs , g:mlist_filename )
    endif

    let start_pos  = GetStartPos()
    let base = GetBase()


    let res = []
    for pkg in pkgs 
        if pkg =~ '^' . base
            call add( res , pkg )
        endif
    endfor
    call complete( start_pos[1]+1 , res )
    return ''
endf

fu! GetStartPos()
    return searchpos( '[^a-zA-Z0-9:_]' , 'bn' , line('.') )
endf

fu! GetBase()
    let col = col('.')
    let pos = GetStartPos()
    let line = getline('.')
    let base =  strpart( line , pos[1] , col )
    return base
endf
inoremap <C-x><C-m>  <C-R>=FecthCPANModuleList()<CR>

" AnyEvent::Impl::Qt::Timer
" AnyEvent::Impl::Perl

