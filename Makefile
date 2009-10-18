
VIM_BUILD_DIR = /tmp/vim/

EXIST = $(shell if [ -e $(VIM_BUILD_DIR) ] ; then echo 1 ; else echo 0 ; fi  )

build_dir : 
		mkdir -p $(VIM_BUILD_DIR)

install_from_git = $(shell \

install : deps
		cp plugin/cpan.vim ~/.vim/plugin/cpan.vim

deps : build_dir

ifeq ($(EXIST),1)
	cd $(VIM_BUILD_DIR)/libperl.vim && git pull && make install
else
	cd $(VIM_BUILD_DIR) && git clone  git://github.com/c9s/libperl.vim.git  \
		&& cd libperl.vim \
		&& make install 
endif


clean :
		rm -rf $(VIM_BUILD_DIR)
