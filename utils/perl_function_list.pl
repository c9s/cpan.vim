#!/usr/bin/env perl
# get perl function list
open(FH, '-|', qq|podselect -section 'DESCRIPTION/Alphabetical Listing of Perl Functions' pod/perlfunc.pod| );
my @func ;
my $inline = 0;
while( <FH> )
{
    if( /^=over/ ) {
        $inlist++;
    }
    elsif( /^=back/ ) {
        $inlist--;
    }
    elsif( /^=item \w+/ ) {
        s/^=item //;
        chomp;
        push @func,$_ if $inlist == 1;
    }
}
close FH;

print $_ , "\n" for @func;
