


INSTALL_CPANM_TO=~/bin/cpanm

install-cpanm-git:
	git clone git://github.com/miyagawa/cpanminus.git
	cd cpanminus.git
	perl Makefile.PL && make && sudo make install

install-cpanm:
	mkdir -p ~/bin/
	if [[ -n `which wget` ]] ; then wget http://xrl.us/cpanm -O $(INSTALL_CPANM_TO) ; \
	elif [[ -n `which curl` ]] ; then curl http://xrl.us/cpanm -o $(INSTALL_CPANM_TO) ; \
	fi
	chmod +x $(INSTALL_CPANM_TO)
