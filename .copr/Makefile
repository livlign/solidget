# Copr runs this to make the source RPM ("make srpm" method).
# It packs the commit Copr checked out, so any branch or tag builds.
spec   := packaging/solidget.spec
outdir ?= $(CURDIR)

srpm:
	command -v git >/dev/null || dnf -y install git rpm-build
	git config --global --add safe.directory '*'
	version=$$(rpmspec -q --srpm --qf '%{version}' $(spec)); \
	git archive --prefix=solidget-$$version/ -o $(outdir)/solidget-$$version.tar.gz HEAD && \
	rpmbuild -bs $(spec) --define "_sourcedir $(outdir)" --define "_srcrpmdir $(outdir)"
