#!/bin/bash


all:



install: install-script install-deps

install-deps:
		cpan PPI 

install-libperl:
		wget -nv http://github.com/c9s/libperl.vim/raw/master/autoload/libperl.vim -O ~/.vim/autoload/libperl.vim

install-script: install-libperl
		mkdir -p ~/.vim/plugin
		rsync -uvr plugin/  ~/.vim/plugin/
		rsync -uvr autoload/ ~/.vim/autoload/
		mkdir -p ~/.vim/perl
		cp perl-functions ~/.vim/perl/
		mkdir -p ~/.vim/bin/
		cp utils/find_base_classes.pl ~/.vim/bin/

doc:
		vim plugin/cpan.vim -c "call cursor(1,1)" -c "exec '1,'.search('^\n').'write! README'" -c ":q"
		perl -i -pe 's{^"}{}' README

dist:
		tar cvzf cpan.vim.tar.gz plugin/ utils/ perl-functions
