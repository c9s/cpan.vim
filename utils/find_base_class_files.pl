#!/usr/bin/env perl
use warnings;
use strict;
use PPI;
use PPI::Dumper;
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

sub traverse_class_f {
    my $class = shift;
    my $lev = shift || 1;

    $lev <= depth or return;

    my @files = find_module_files( $class );
    @files or return;  # file doesn't exist

    my $file = shift @files; # just take the first one

    verbose "depth: $lev | parsing $file";

    my @bases = find_base_classes( $file );
    my @class_files = ($file);
    for my $base ( @bases ) {
        push @class_files , traverse_class_f( $base , $lev + 1 );
    }
    return @class_files;
}

# my @bases = find_base_classes( shift ); # search from file
my @classes = map { traverse_class_f( $_ ) } find_base_classes( shift );
print join(" ",@classes) . "\n";
