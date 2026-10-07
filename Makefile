.PHONY: clean spec sources srpm rpm

PACKAGE := ec2-agent
SPEC    := $(PACKAGE).spec

GIT := $(shell which git)

ifdef GIT
HEAD_SHA := $(shell git rev-parse --short --verify HEAD)
TAG      := $(shell git show-ref --tags -d | grep $(HEAD_SHA) | \
                    git name-rev --tags --name-only $$(awk '{print $2}'))

BUILDID := %{nil}
ifndef TAG
BUILDID := .$(shell date --date="$$(git show -s --format=%ci $(HEAD_SHA))" '+%Y%m%d%H%M').git$(HEAD_SHA)
endif
endif

# Parse version from the spec (no rpm required, works on macOS too).
# Prefer the committed spec in git (like boto3), fall back to the file on disk.
SPEC_SRC := $(shell git cat-file -e $(HEAD_SHA):$(SPEC) 2>/dev/null && echo git || echo disk)
VERSION := $(shell if [ "$(SPEC_SRC)" = "git" ]; then \
		git cat-file -p $(HEAD_SHA):$(SPEC) | sed -n 's/^Version:[[:space:]]*\([^[:space:]]*\).*/\1/p' | head -1; \
	else \
		sed -n 's/^Version:[[:space:]]*\([^[:space:]]*\).*/\1/p' $(SPEC) | head -1; \
	fi)

# Restore the spec from git (with @BUILDID@ substituted), so the on-disk spec
# always matches the committed one. Falls back to in-place substitution if the
# spec is not yet committed.
spec: ## create spec file with substituted buildid
	@if [ "$(SPEC_SRC)" = "git" ]; then \
		git cat-file -p $(HEAD_SHA):$(SPEC) | sed -e 's,@BUILDID@,$(BUILDID),g' > $(SPEC); \
	else \
		sed -e 's,@BUILDID@,$(BUILDID),g' $(SPEC) > $(SPEC).tmp && mv $(SPEC).tmp $(SPEC); \
	fi

sources: ## archive sources
sources: clean spec
	@git archive --format=tar --prefix=$(PACKAGE)-$(VERSION)/ $(HEAD_SHA) | \
	     gzip > $(PACKAGE)-$(VERSION).tar.gz

srpm: ## create srpm
srpm: sources
	@mkdir -p srpms/
	rpmbuild -bs --define "_sourcedir $(CURDIR)" \
		--define "_srcrpmdir $(CURDIR)/srpms" $(SPEC)

rpm: ## create rpm
rpm: srpm
	@mkdir -p rpms/
	rpmbuild -bb --define "_sourcedir $(CURDIR)" \
		--define "_rpmdir $(CURDIR)/rpms" $(SPEC)

clean: ## clean artifacts
	@rm -rf rpms/ srpms/ *.tar.gz *.rpm $(SPEC).tmp