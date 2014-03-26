# Makefile for django Organice
#

# variables
LANGUAGES = en de it
REQUIREMENTS = docs/requirements.txt
SHELL = /bin/bash

.PHONY: help bootstrap bumpver clean develop undevelop docs install uninstall release requirements setuptools tests transifex

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  bootstrap     to update Sass, Compass, and bootstrap-sass on your (Ubuntu) system"
	@echo "  bumpver       to bump the version number, commit and tag for releasing"
	@echo "  clean         to remove build files and folders"
	@echo "  develop       to install all dependencies needed for development/docs/translation"
	@echo "  undevelop     to uninstall all dependencies needed for development/docs/translation"
	@echo "  docs          to generate documentation in English and all translated languages"
	@echo "  install       to install this project including all dependencies (~ pip install)"
	@echo "  uninstall     to uninstall all dependencies / installed packages (pip uninstall -y)"
	@echo "  release       to package a new release, and upload it to pypi.org"
	@echo "  requirements  to generate the requirements.txt file in the docs folder (pip freeze)"
	@echo "  setuptools    to install setuptools or repair a broken pip installation"
	@echo "  tests         to run all tests manually"
	@echo "  transifex     to synchronize translation resources with Transifex (upload+download)"

bootstrap:
	@echo "Updating your system-wide bootstrap-sass installation... (may require your password)"
	gem list &> /dev/null || sudo apt-get install -y ruby
	yes | sudo gem uninstall sass compass bootstrap-sass
	sudo gem install compass bootstrap-sass --no-rdoc --no-ri
	@gem list

bumpver:
	@echo "Not implemented yet. Install pypi package instead: \`pip install bumpversion'"

clean:
	$(MAKE) -C docs clean
	rm -rf build/ dist/ django_organice.egg-info/ docs/build/ docs/locale/ organice/static/.sass-cache
	for DIR in media/ static/ templates/ ; do \
		[ -d $$DIR ] && rmdir $$DIR || true ; \
	done

develop: setuptools
	pip install Sphinx sphinx-intl transifex-client

undevelop: setuptools
	for PKG in docutils Jinja2 MarkupSafe polib Pygments Sphinx sphinx-intl transifex-client ; do \
		pip uninstall -y $$PKG || true ; \
	done

docs: develop
	@cd docs && \
	tx pull --all --force && \
	sphinx-intl build
	@for LANG in $(LANGUAGES) ; do \
		$(MAKE) -C docs -e SPHINXOPTS="-D language='"$$LANG"'" html && \
		DIR_LANG=docs/build/html/$$LANG && \
		rm -rf $$DIR_LANG && \
		mkdir $$DIR_LANG && \
		mv docs/build/html/{_sources/,_static/,*.html,*.js} $$DIR_LANG/ ; \
	done
	@echo
	@echo "Build finished. Documentation is in subdirectories ($(LANGUAGES)) of docs/build/html/"

install: setuptools
	python setup.py install

uninstall:
	pip freeze | sed 's/==.*$//' | xargs -I PKG pip uninstall -y PKG

release: setuptools clean requirements
	python setup.py sdist upload

requirements: setuptools undevelop
# NOTE: we must filter out erroneously listed globally installed packages on Ubuntu
	pip freeze | sed -e '/^argparse/d' -e '/^wsgiref/d' > $(REQUIREMENTS)
	git diff $(REQUIREMENTS)

setuptools:
	python -c 'import setuptools' || \
	curl -s -S https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py | python
	rm -f setuptools-*.zip

tests:
	@echo "Not implemented yet."

transifex: develop
	@cd docs && tx pull --all --force
	@$(MAKE) -C docs gettext
	@cd docs && sphinx-intl update -p build/locale && tx push -s
	@echo
	@echo "Translation resources synchronized."