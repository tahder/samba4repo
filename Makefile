#
# Makefile - build wrapper for Samba 4 on RHEL 6
#
#	git clone RHEL 6 SRPM building tools from
#	https://github.com/nkadel/[package] into designated
#	SAMBAPKGS below
#
#	Set up local 

# Current libtalloc-2.1.x required
SAMBAPKGS+=libtalloc-srpm

# Current libtdb-1.3.x required
SAMBAPKGS+=libtdb-srpm

# Current libtevent-0.9.x required
SAMBAPKGS+=libtevent-srpm

# Current libldb-1.4.x required
# Also reuqires libtevent
SAMBAPKGS+=libldb-srpm

# Current samba release, requires all curent libraries
SAMBAPKGS+=samba-srpm

REPOS+=samba4repo/el/7
REPOS+=samba4repo/fedora/28

REPODIRS := $(patsubst %,%/x86_64/repodata,$(REPOS)) $(patsubst %,%/SRPMS/repodata,$(REPOS))

CFGS+=samba4repo-f28-x86_64.cfg
CFGS+=samba4repo-7-x86_64.cfg
# Discard RHEL 6
#CFGS+=samba4repo-6-x86_64.cfg

all:: $(CFGS)
all:: $(REPODIRS)
all:: $(SAMBAPKGS)

all install clean:: FORCE
	@for name in $(SAMBAPKGS); do \
	     (cd $$name; $(MAKE) $(MFLAGS) $@); \
	done  

# Build for locacl OS
build:: FORCE
	@for name in $(SAMBAPKGS); do \
	     (cd $$name; $(MAKE) $(MFLAGS) $@); \
	done

# Git clone operations, not normally required
# Targets may change

libtalloc-srpm::
	@[ -d $@/.git ] || \
	git clone git://github.com/nkadel/libtalloc-2.1.x-srpm.git libtalloc-srpm

libtdb-srpm::
	@[ -d $@/.git ] || \
	git clone git://github.com/nkadel/libtdb-1.3.x-srpm.git libtdb-srpm

libldb-srpm::
	@[ -d $@/.git ] || \
	git clone git://github.com/nkadel/libldb-1.1.x-srpm.git libldb-srpm

libtevent-srpm::
	@[ -d $@/.git ] || \
	git clone git://github.com/nkadel/libtevent-0.9.x-srpm.git libtevent-srpm

samba-srpm::
	@[ -d $@/.git ] || \
	git clone git://github.com/nkadel/samba-4.1.x-srpm.git samba-srpm


# Dependencies of libraries on other libraries for compilation
libtevent:: libtalloc-srpm

libldb-srpm:: libtalloc-srpm
libldb-srpm:: libtdb-srpm
libldb-srpm:: libtevent-srpm

# Samba rellies on all the othe components
samba-srpm:: libtalloc-srpm
samba-srpm:: libldb-srpm
samba-srpm:: libtevent-srpm
samba-srpm:: libtdb-srpm
#samba-srpm:: iniparser-srpm


# Actually build in directories
$(SAMBAPKGS):: FORCE
	(cd $@; $(MAKE) $(MLAGS) install)

repos: $(REPOS) $(REPODIRS)
$(REPOS):
	install -d -m 755 $@

.PHONY: $(REPODIRS)
$(REPODIRS): $(REPOS)
	@install -d -m 755 `dirname $@`
	/usr/bin/createrepo `dirname $@`


CFGS+=samba4repo-f28-x86_64.cfg
CFGS+=samba4repo-7-x86_64.cfg
# Discard RHHEL 6
#CFGS+=samba4repo-6-x86_64.cfg

.PHONY: cfg
cfg:: $(CFGS)

.PHONY: cfgs
cfgs: $(CFGS)
$(CFGS)::
	sed 's|@REPOBASEDIR@|$(PWD)|g' $@.in > $@

repo: samba4repo.repo
samba4repo.repo:: samba4repo.repo.in
	sed 's|@REPOBASEDIR@|$(PWD)|g' $@.in > $@
samba4repo.repo::
	@cmp -s $@ /etc/yum.repos.d/$@ || \
	    diff -u $@ /etc/yum.repos.d/$@

clean::
	find . -name \*~ -exec rm -f {} \;
	rm -f *.cfg
	rm -f *.out
	@for name in $(SAMBAPKGS); do \
	    $(MAKE) -C $$name clean; \
	done

distclean:
	rm -rf $(REPOS)

maintainer-clean:
	rm -rf $(SAMBAPKGS)

FORCE::

