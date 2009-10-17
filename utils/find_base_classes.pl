#!/usr/bin/env perl
use warnings;
use strict;
eval qq{
    use PPI;
    use PPI::Dumper;
};
die 'Please use cpan to install PPI' if $@ ;

use constant depth => 3;

sub find_base_classes {
    my $file  = shift;
    my $d = PPI::Document->new( $file );
    my $sts = $d->find( sub {
        return $_[1]->isa('PPI::Statement::Include') and $_[1]->type eq 'use'
    });
    my @bases = ();
    for my $st (@$sts) {
        my @elements = $st->children;
        my $is_base = $st->find( sub { $_[ 1 ]->content eq 'base' } );
        if ($is_base) {
            my @elements = $st->children();
            my @e        = eval $elements[ 4 ]->content;
            push @bases, @e;
        }
    }
    return @bases;
}

sub translate_class {
    my $class = shift;
    my $class_file = $class; $class_file =~ s{::}{/}g; $class_file .= '.pm';
    return $class_file;
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
    my $refer = shift || "[CurrentBaseClass]";
    my $lev   = shift || 1;
    $lev <= depth or return ();

    my @result = ();
    my ($file) = find_module_files( $class );
    push @result,[ $class , $refer , $file ];
    for my $base ( find_base_classes( $file ) ) {
        my ($base_file) = find_module_files( $base );
        push @result, traverse_parent( $base , $class , $lev + 1 );
    }
    return @result;
}

# format: 
#    base_class base_class_refer file
map { print join(" ",@$_)."\n" } map { traverse_parent($_) } find_base_classes( shift );
