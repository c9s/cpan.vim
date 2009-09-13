#!/bin/bash


all:


install:
		mkdir -p ~/.vim/plugin
		cp -v plugin/cpan-list.vim  ~/.vim/plugin/

pack:
		tar cvzf cpan-list.tar.gz plugin/
