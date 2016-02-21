SRC = .src

GEM_HOME = .gems
FPM_BIN = $(GEM_HOME)/bin/fpm
FPM_EXE = GEM_HOME=$(GEM_HOME) $(FPM_BIN)

ARCH = amd64
POSTSRSD_VERSION = 1.4

.PHONY: prereqs mrproper

all: postsrsd

$(SRC)/postsrsd:
	git clone git@github.com:roehling/postsrsd.git $@

postsrsd_$(POSTSRSD_VERSION)_$(ARCH).deb: prereqs $(SRC)/postsrsd
	sudo apt-get install -yqq cmake
	cd $(SRC)/postsrsd && git checkout $(POSTSRSD_VERSION)
	mkdir -p $(SRC)/postsrsd/build
	cd $(SRC)/postsrsd/build && cmake -DCMAKE_INSTALL_PREFIX=/usr .. && make && make install DESTDIR=dist
	$(FPM_EXE) -s dir -t deb -n postsrsd -v $(POSTSRSD_VERSION) -C $(SRC)/postsrsd/build/dist

postsrsd: postsrsd_$(POSTSRSD_VERSION)_$(ARCH).deb

$(FPM_BIN):
	sudo apt-get install -yqq ruby-dev build-essential
	mkdir -p $(GEM_HOME)
	gem install --no-ri --no-rdoc --install-dir $(GEM_HOME) fpm

fpm: $(FPM_BIN)

$(SRC):
	mkdir -p $(SRC)

prereqs: $(FPM_BIN) $(SRC)

clean:
	rm -rf $(SRC) *.deb

mrproper: clean
	rm -rf $(GEM_HOME)
