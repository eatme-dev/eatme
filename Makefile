ALL-SCSS := $(shell find src -name '*.scss')
ALL-CSS := $(ALL-SCSS:src/%.scss=lib/%.css)
ALL-COFFEE := $(shell find src -name '*.coffee')
ALL-JS := $(ALL-COFFEE:src/%.coffee=lib/%.js)
ALL := $(ALL-JS) $(ALL-CSS)

build: $(ALL)

clean:
	rm -fr lib npm

realclean: clean
	rm -fr www

lib/%.css: src/%.scss
	sassc $< > $@

lib/%.js: src/%.coffee
	coffee -cp $< > $@
