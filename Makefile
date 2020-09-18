.DEFAULT_GOAL := help
.PHONY: build-parser build build-full test test-full update-golden-files
.PHONY: install-gfx-deps install-gfx-deps-LINUX install-gfx-deps-MSYS install-gfx-deps-MINGW install-gfx-deps-MACOS install-deps install install-full

PWD := $(shell pwd)

#PKG_NAMES_LINUX := glade xvfb libxinerama-dev libxcursor-dev libxrandr-dev libgl1-mesa-dev libxi-dev gir1.2-gtk-3.0 libgtk2.0-dev libperl-dev libcairo2-dev libpango1.0-dev libgtk-3-dev gtk+3.0 libglib2.0-dev
PKG_NAMES_LINUX := glade xvfb libxinerama-dev libxcursor-dev libxrandr-dev libgl1-mesa-dev libxi-dev libperl-dev libcairo2-dev libpango1.0-dev libglib2.0-dev libopenal-dev
#PKG_NAMES_MACOS := gtk gtk-mac-integration gtk+3 glade
PKG_NAMES_WINDOWS := mingw-w64-x86_64-openal

UNAME_S := $(shell uname -s)

ifneq (,$(findstring Linux, $(UNAME_S)))
PLATFORM := LINUX
SUBSYSTEM := LINUX
PACKAGES := PGK_NAMES_LINUX
DISPLAY  := :99.0
endif

ifneq (,$(findstring Darwin, $(UNAME_S)))
PLATFORM := MACOS
SUBSYSTEM := MACOS
PACKAGES := PKG_NAMES_MACOS
endif

ifneq (,$(findstring MINGW, $(UNAME_S)))
PLATFORM := WINDOWS
SUBSYSTEM := MINGW
PACKAGES := PKG_NAMES_WINDOWS
endif

#ifneq (,$(findstring CYGWIN, $(UNAME_S)))
#PLATFORM := WINDOWS
#SUBSYSTEM := CYGWIN
#endif

ifneq (,$(findstring MSYS, $(UNAME_S)))
PLATFORM := WINDOWS
SUBSYSTEM := MSYS
PACKAGES := PKG_NAMES_WINDOWS
endif

ifeq ($(PLATFORM), WINDOWS)
GOPATH := $(subst \,/,${GOPATH})
HOME := $(subst \,/,${HOME})
CXPATH := $(subst, \,/, ${CXPATH})
endif

INSTALL_GFX_DEPS := install-gfx-deps-$(SUBSYSTEM)

GLOBAL_GOPATH := $(GOPATH)
LOCAL_GOPATH  := $(HOME)/go

ifdef GLOBAL_GOPATH
  GOPATH := $(GLOBAL_GOPATH)
else
  GOPATH := $(LOCAL_GOPATH)
endif

ifdef CXPATH
	CX_PATH := $(CXPATH)
else
	CX_PATH := $(HOME)/cx
endif

ifeq ($(UNAME_S), Linux)
endif

configure: ## Configure the system to build and run CX
	@if [ -z "$(GLOBAL_GOPATH)" ]; then echo "NOTE:\tGOPATH not set" ; export GOPATH="$(LOCAL_GOPATH)"; export PATH="$(LOCAL_GOPATH)/bin:${PATH}" ; fi
	@echo "GOPATH=$(GOPATH)"
	@mkdir -p $(GOPATH)/src/github.com/SkycoinProject
	@if [ ! -e $(GOPATH)/src/github.com/SkycoinProject/cx ]; then mkdir -p $(GOPATH)/src/github.com/SkycoinProject ; ln -s $(PWD) $(GOPATH)/src/github.com/SkycoinProject/cx ; fi

configure-workspace: ## Configure CX workspace environment
	mkdir -p $(CX_PATH)/{,src,bin,pkg}
	@echo "NOTE:\tCX workspace at $(CX_PATH)"

build-parser: configure install-deps ## Generate lexer and parser for CX grammar
	nex -e cxgo/cxgo0/cxgo0.nex
	goyacc -o cxgo/cxgo0/cxgo0.go cxgo/cxgo0/cxgo0.y
	nex -e cxgo/parser/cxgo.nex
	goyacc -o cxgo/parser/cxgo.go cxgo/parser/cxgo.y

build: configure build-parser ## Build CX from sources
	go build -tags="base" -i -o $(GOPATH)/bin/cx github.com/SkycoinProject/cx/cxgo/
	chmod +x $(GOPATH)/bin/cx

build-full: install-full configure build-parser ## Build CX from sources with all build tags
	go build -tags="base cxfx cxtweet" -i -o $(GOPATH)/bin/cx github.com/SkycoinProject/cx/cxgo/
	chmod +x $(GOPATH)/bin/cx

clean-db:
	rm -f $(GOPATH)/src/github.com/SkycoinProject/cx/cxdb.db

build-cxstrat: configure build-parser clean-db
	export GOOS=linux
	mkdir -p releases/cxstrat
	rm -f releases/cxstrat/cx
	rm -f releases/cxstrat/*.cx
	rm -f releases/cxstrat/tweetcoin
	. ./cxd.sh
	go build -tags="base cxstrat cxstratclient cxstratlnx" -i -o releases/cxstrat/cx github.com/SkycoinProject/cx/cxgo/
	chmod +x releases/cxstrat/cx
	cp ${GOPATH}/src/github.com/SkycoinProject/cx/cxstrat/datum/*.cx releases/cxstrat
	rm -f releases/cxstrat.zip
	rm -f releases/cxstrat/cxdb.db
	cp cxstrat/fiber/tweetcoin releases/cxstrat
	chmod +x releases/cxstrat/tweetcoin

build-cxstrat-win: configure build-parser clean-db
	mkdir -p releases/cxstrat-win
	rm -f releases/cxstrat-win/cx.exe
	rm -f releases/cxstrat-win/*.cx
	. ./cxd.sh
	GOOS=windows go build -tags="base cxstrat cxstratclient cxstratwin" -o releases/cxstrat-win/cx.exe github.com/SkycoinProject/cx/cxgo/
	chmod +x releases/cxstrat-win/cx.exe
	cp ${GOPATH}/src/github.com/SkycoinProject/cx/cxstrat/datum/*.cx releases/cxstrat-win
	rm -f releases/cxstrat-win.zip
	rm -f releases/cxstrat-win/cxdb.db
	cp cxstrat/fiber/tweetcoin.exe releases/cxstrat-win
	chmod +x releases/cxstrat-win/tweetcoin.exe

build-cxstrat-public: configure build-parser clean-db ## CX Stratus Explorer binaries
	mkdir -p releases/cxstrat-pub
	rm -f releases/cxstrat-pub/cxpublic
	rm -f releases/cxstrat-pub/*.cx
	. ./cxd.sh
	go build -tags="base cxstrat cxstratpublic cxstratlnx" -i -o releases/cxstrat-pub/cxpublic github.com/SkycoinProject/cx/cxgo/
	chmod +x releases/cxstrat-pub/cxpublic
	cp $(GOPATH)/src/github.com/SkycoinProject/cx/cxstrat/datum/*.cx releases/cxstrat-pub
	rm -f releases/cxstrat-pub.zip
	cp cxstrat/fiber/tweetcoin releases/cxstrat-pub
	chmod +x releases/cxstrat-pub/tweetcoin
	
package-cxstrat: build-cxstrat build-cxstrat-win build-cxstrat-public
	zip -r releases/cxstrat-win.zip releases/cxstrat-win
	zip -r releases/cxstrat.zip releases/cxstrat
	zip -r releases/cxstrat-pub.zip releases/cxstrat-pub

build-android: install-full install-mobile configure build-parser
#go get github.com/SkycoinProject/gltext
	git clone https://github.com/SkycoinProject/gomobile $(GOPATH)/src/golang.org/x/mobile 2> /dev/null || true
	cd $(GOPATH)/src/golang.org/x/mobile/; git pull origin master; go get ./cmd/gomobile
	gomobile install -tags="base cxfx mobile android_gles31" -target=android $(GOPATH)/src/github.com/SkycoinProject/cx/cxgo/

install-gfx-deps-LINUX:
	@echo 'Installing dependencies for $(UNAME_S)'
	sudo apt-get update -qq
	sudo apt-get install -y $(PKG_NAMES_LINUX) --no-install-recommends

install-gfx-deps-MSYS:
	@echo 'Installing dependencies for $(UNAME_S)'
	pacman -Sy
	pacman -S $(PKG_NAMES_WINDOWS)
	if [ ! -a /mingw64/lib/libOpenAL32.a]; then ln -s /mingw64/lib/libopenal.a /mingw64/lib/libOpenAL32.a; fi
	if [ ! -a /mingw64/lib/libOpenAL32.dll.a]; then ln -s /mingw64/lib/libopenal.dll.a /mingw64/lib/libOpenAL32.dll.a; fi

install-gfx-deps-MINGW: install-gfx-deps-MSYS

install-gfx-deps-MACOS:
	@echo 'Installing dependencies for $(UNAME_S)'
#brew install $(PKG_NAMES_MACOS)

install-deps: configure
	@echo "Installing go package dependencies"
	go get github.com/SkycoinProject/nex
	go get github.com/cznic/goyacc

install-gfx-deps: configure $(INSTALL_GFX_DEPS)
	go get github.com/SkycoinProject/gltext
	go get github.com/go-gl/gl/v3.2-compatibility/gl
	go get github.com/go-gl/glfw/v3.3/glfw
	go get golang.org/x/mobile/exp/audio/al
	go get github.com/mjibson/go-dsp/wav

install: install-deps build configure-workspace ## Install CX from sources. Build dependencies
	@echo 'NOTE:\tWe recommend you to test your CX installation by running "cx $(GOPATH)/src/github.com/SkycoinProject/cx/tests"'
	cx -v

install-full: install-gfx-deps install-deps build-full configure-workspace

install-mobile:
	go get golang.org/x/mobile/gl

install-linters: ## Install linters
	go get -u github.com/FiloSottile/vendorcheck
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.25.0

lint: ## Run linters. Use make install-linters first.
	vendorcheck ./...
	golangci-lint run -c .golangci.yml ./cx

test: build ## Run CX test suite.
	go test -race -tags base github.com/SkycoinProject/cx/cxgo/
	cx ./lib/args.cx ./tests/main.cx ++wdir=./tests ++disable-tests=gui,issue

test-full: build ## Run CX test suite with all build tags
	go test -race -tags="base cxfx" github.com/SkycoinProject/cx/cxgo/
	cx ./lib/args.cx ./tests/main.cx ++wdir=./tests ++disable-tests=gui,issue

update-golden-files: build ## Update golden files used in CX test suite
	ls -1 tests/ | grep '.cx$$' | while read -r NAME; do echo "Processing $$NAME"; cx -t -co tests/testdata/tokens/$${NAME}.txt tests/$$NAME || true ; done

check-golden-files: update-golden-files ## Ensure golden files are up to date
	if [ "$(shell git diff tests/testdata | wc -l | tr -d ' ')" != "0" ] ; then echo 'Changes detected. Golden files not up to date' ; exit 2 ; fi

check: check-golden-files test ## Perform self-tests

format: ## Formats the code. Must have goimports installed (use make install-linters).
	goimports -w -local github.com/SkycoinProject/cx ./cx
	goimports -w -local github.com/SkycoinProject/cx ./cxgo/actions

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
