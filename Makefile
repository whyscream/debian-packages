SRC = $(shell pwd)/.src

GEM_HOME = $(shell pwd)/.gems
FPM_BIN = $(GEM_HOME)/bin/fpm
FPM_EXE = GEM_HOME=$(GEM_HOME) $(FPM_BIN) --force

ARCH = amd64

# versions
POSTSRSD_VERSION = 1.4
SMFSPF_VERSION = 2.4.2
RUBY_JLS_GROK_VERSION = 0.11.2

.PHONY: fpmhelp mrproper

all: postsrsd smf-spf

$(SRC)/postsrsd: $(SRC)
	git clone https://github.com/roehling/postsrsd.git $@

postsrsd_$(POSTSRSD_VERSION)_$(ARCH).deb: fpm $(SRC)/postsrsd
	sudo apt-get install -yqq cmake
	cd $(SRC)/postsrsd && git checkout $(POSTSRSD_VERSION)
	mkdir -p $(SRC)/postsrsd/build
	cd $(SRC)/postsrsd/build && cmake -DCMAKE_INSTALL_PREFIX=/usr \
		-DINIT_FLAVOR=sysv-lsb -DCHROOT_DIR=/var/lib/postsrsd \
		-DGENERATE_SRS_SECRET=OFF ..
	cd $(SRC)/postsrsd/build && make && make install DESTDIR=../dist
	$(FPM_EXE) -s dir -t deb -C $(SRC)/postsrsd/dist \
		--name postsrsd \
		--version $(POSTSRSD_VERSION) \
		--description "Sender Rewriting Scheme daemon for postfix" \
		--deb-init $(SRC)/postsrsd/dist/etc/init.d/postsrsd \
		--deb-default $(SRC)/postsrsd/dist/etc/default/postsrsd \
		--after-install postsrsd/after-install.sh

postsrsd: postsrsd_$(POSTSRSD_VERSION)_$(ARCH).deb

$(SRC)/smf-spf: $(SRC)
	git clone https://github.com/jcbf/smf-spf.git $@

smf-spf_$(SMFSPF_VERSION)_$(ARCH).deb: fpm $(SRC)/smf-spf
	cd $(SRC)/smf-spf && git checkout v$(SMFSPF_VERSION)
	cd $(SRC)/smf-spf && make
	sed -e 's@#User\s\+smfs@User nobody@' \
		-e 's@#Socket\s\+unix:/var/run/smfs/smf-spf.sock@Socket unix:/var/run/smf-spf/smf-spf.sock@' \
		-i $(SRC)/smf-spf/smf-spf.conf
	$(FPM_EXE) -s dir -t deb -C $(SRC)/smf-spf \
		--name smf-spf \
		--version $(SMFSPF_VERSION) \
		--description "SPF milter service" \
		--depends libmilter1.0.1 \
		--depends libspf2-2 \
		--deb-init smf-spf/init/smf-spf \
		smf-spf=/usr/sbin/ \
		smf-spf.conf=/etc/

smf-spf: smf-spf_$(SMFSPF_VERSION)_$(ARCH).deb

ruby-jls-grok_$(RUBY_JLS_GROK_VERSION)_all.deb: fpm
	$(FPM_EXE) -s gem -t deb \
		--version $(RUBY_JLS_GROK_VERSION) \
		--gem-package-name-prefix ruby \
		--prefix $(shell gem environment gemdir) \
		jls-grok

ruby-jls-grok: ruby-jls-grok_$(RUBY_JLS_GROK_VERSION)_all.deb

$(FPM_BIN):
	sudo apt-get install -yqq ruby-dev build-essential
	mkdir -p $(GEM_HOME)
	gem install --no-ri --no-rdoc --install-dir $(GEM_HOME) fpm

fpm: $(FPM_BIN)

fpmhelp: $(FPM_BIN)
	$(FPM_EXE) --help | less

$(SRC):
	mkdir -p $(SRC)

clean:
	rm -rf $(SRC) *.deb

mrproper: clean
	rm -rf $(GEM_HOME)
