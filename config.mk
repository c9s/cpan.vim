NAME=cpan.vim

bundle-deps:
	$(call fetch_github,c9s,libperl.vim,master,vimlib/autoload/libperl.vim,autoload/libperl.vim)
	$(call fetch_github,c9s,search-window.vim,master,vimlib/autoload/swindow.vim,autoload/swindow.vim)
	$(call fetch_github,c9s,perldoc.vim,master,vimlib/autoload/perldoc.vim,autoload/perldoc.vim)
