#!/bin/bash


all:


install:
		mkdir -p ~/.vim/plugin
		cp -v plugin/cpan.vim  ~/.vim/plugin/
		mkdir -p ~/.vim/perl
		cp perl-functions ~/.vim/perl/
#		cp perl-keywords ~/.vim/perl/

doc:
	vim plugin/cpan.vim -c "call cursor(1,1)" -c "exec '1,'.search('^\n').'write! README'" -c ":q"
	perl -i -pe 's{^"}{}' README

pack:
		tar cvzf cpan.vim.tar.gz plugin/
