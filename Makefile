SUBDIRS := petdrawx16 assembly basic-sprite cc65-audio cc65-sprite

# determine whether to use python3 or python command
ifeq (, $(shell python3 -V))
	ifeq (, $(shell python -V))
		$(error "Neither Python nor Python3 not found in $(PATH)")
	else
		PYTHON=python
	endif
else
	PYTHON=python3
endif

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
	cd release/PRG ; $(PYTHON) -c 'import os, sys; [os.rename(a, a.upper()) for a in sys.argv[1:]]' *

clean:
	rm -rf release

$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: all $(SUBDIRS)
