SUBDIRS := petdrawx16 assembly basic-sprite cc65-audio cc65-sprite

EMULATOR ?= ../x16-emulator/x16emu

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
	./tools/bas2prg.py "${EMULATOR}" ./release/basic ./release/PRG
	cd release/PRG ; python -c 'import os, sys; [os.rename(a, a.upper()) for a in sys.argv[1:]]' *

clean:
	rm -rf release

$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: all $(SUBDIRS)
