#!/bin/bash


all:


install:
		mkdir -p ~/.vim/plugin
		cp -v plugin/cpan.vim  ~/.vim/plugin/

pack:
		tar cvzf cpan.vim.tar.gz plugin/
