SUBDIRS := assembly basic-sprite cc65-audio cc65-sprite

all: $(SUBDIRS)
	rm -rf release
	mkdir -p release/basic
	mkdir -p release/PRG
	cp assembly/mode4-demo.prg release/PRG
	cp assembly/mode7-demo.prg release/PRG
	cp assembly/sprite-demo.prg release/PRG
	cp cc65-audio/audio.prg release/PRG
	cp cc65-sprite/demo.prg release/PRG
	cp basic-sprite/smiley.bas release/basic
	cp basic/* release/basic
	cp "layer demo/layer-demo.bas" release/basic
	./tools/bas2prg.py ../x16-emulator/x16emu ./release/basic ./release/PRG
	cd release/PRG ; python -c 'import os, sys; [os.rename(a, a.upper()) for a in sys.argv[1:]]' *

$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: all $(SUBDIRS)
