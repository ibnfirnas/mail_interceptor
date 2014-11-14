.PHONY: \
	all \
	build \
	clean \
	configure \
	distclean \
	doc \
	install \
	reinstall \
	test \
	uninstall


SETUP := ocaml setup.ml


build: setup.data
	$(SETUP) -build $(BUILDFLAGS)

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)

all:
	$(SETUP) -all $(ALLFLAGS)

install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

reinstall: setup.data
	$(SETUP) -reinstall $(REINSTALLFLAGS)

clean:
	$(SETUP) -clean $(CLEANFLAGS)

distclean:
	$(SETUP) -distclean $(DISTCLEANFLAGS)

setup.data: setup.ml
	$(SETUP) -configure $(CONFIGUREFLAGS)

setup.ml:
	@oasis setup

configure:
	$(SETUP) -configure $(CONFIGUREFLAGS)

deps:
	@opam install --yes \
		async \
		async_shell \
		async_smtp \
		caravan \
		core \
		core_extended \
		cryptokit \
		email_message \
		oasis
