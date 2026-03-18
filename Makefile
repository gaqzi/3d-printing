OPENSCAD := /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
SOURCES := $(wildcard *.scad)
OUTPUTS := $(patsubst %.scad,out/%.stl,$(SOURCES))

.PHONY: all clean check

all: $(OUTPUTS)

out/%.stl: %.scad | out
	$(OPENSCAD) -o $@ $<

out:
	mkdir -p out

check:
	@fail=0; \
	for f in $(SOURCES); do \
		echo "Checking $$f..."; \
		$(OPENSCAD) -o /dev/null --export-format binstl $$f 2>&1 || fail=1; \
	done; \
	exit $$fail

clean:
	rm -rf out
