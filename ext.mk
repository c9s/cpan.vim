


install-cpanm-git:
	git clone git://github.com/miyagawa/cpanminus.git
	cd cpanminus.git
	perl Makefile.PL && make && sudo make install

install-cpanm:
	mkdir ~/bin/
	if [[ -n `which wget` ]] ; then wget http://xrl.us/cpanm -O ~/bin/cpanm ; \
	else curl http://xrl.us/cpanm -o ~/bin/cpanm ; fi
	chmod +x ~/bin/cpanm
