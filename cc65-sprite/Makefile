.PHONY: all clean
all: demo.prg

demo.prg: demo.c balloon.inc
	cl65 -t cx16 -O -o $@ $<

balloon.inc: balloon.png
	python3 ../tools/png2sprite.py -n balloon $< $@

clean:
	rm -f *.inc *.o *.prg
