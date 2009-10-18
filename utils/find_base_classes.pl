#!/usr/bin/env perl
use warnings;
use strict;
eval qq{
    use PPI;
};
die 'Please use cpan to install PPI' if $@ ;

use constant depth => 3;
use constant grep_statement => 1;

sub find_base_classes {
    my $file  = shift;
    my $d ;
    if ( grep_statement ) {
        my $head = qx(grep -A7 '^use base' $file);
        $d = PPI::Document->new( \$head );
    }
    else {
        $d = PPI::Document->new( $file );
    }

    my $sts = $d->find( sub { 
        return 1 if $_[1]->isa('PPI::Statement::Include') and $_[1]->type eq 'use';
        return 0;
    });

    return () unless $sts;

    my @bases = ();
    for my $st (@$sts) {
        my @elements = $st->children;
        my $is_base = $st->find( sub { $_[ 1 ]->content eq 'base' } );
        if ($is_base) {
            my @elements = $st->children();
            push @bases, ( eval $elements[ 4 ]->content );   # 'use',' ','base','qw/ ...... /',';'
        }
    }
    return @bases;
}

sub translate_class {
    my $class = $_[0];
    $class =~ s{::}{/}g; 
    return $class . '.pm';
}

sub find_module_files {
    my $class = shift;
    my $class_file = translate_class( $class );
    my @paths = ();
    for my $base_path ( @INC ) {
        my $abs_path = $base_path . '/' . $class_file;
        push @paths,$abs_path if ( -e $abs_path );
    }
    return @paths;
}

sub verbose { print STDERR @_,"\n" }

sub traverse_parent {
    my $class = shift;
    my $refer = shift || "[CurrentClass]";
    my $lev   = shift || 1;
    $lev <= depth or return ();

    my ($file) = find_module_files( $class );
    my @result = ( [ $class , $refer , $file ] );
    return @result , map { traverse_parent( $_ , $class , $lev + 1 ) } find_base_classes( $file ) ;
}

# format: 
#    base_class base_class_refer file
map { print join(" ",@$_)."\n" } map { traverse_parent($_) } find_base_classes( shift );
