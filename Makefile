.PHONY: build

build:
	./update_c.sh
	python setup.py build
	python setup.py build_ext --inplace