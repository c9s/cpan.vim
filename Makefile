#!/bin/bash


all:


install:
		mkdir -p ~/.vim/plugin
		cp -v plugin/cpan.vim  ~/.vim/plugin/
		mkdir -p ~/.vim/perl
		cp perl-functions ~/.vim/perl/
		mkdir -p ~/.vim/bin/
		cp utils/find_base_classes.pl ~/.vim/bin/

doc:
	vim plugin/cpan.vim -c "call cursor(1,1)" -c "exec '1,'.search('^\n').'write! README'" -c ":q"
	perl -i -pe 's{^"}{}' README

dist:
		tar cvzf cpan.vim.tar.gz plugin/ utils/ perl-functions
