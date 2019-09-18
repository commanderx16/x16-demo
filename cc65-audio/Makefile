all: audio.prg

audio.prg: main.c test.inc
	cl65 -t c64 -O -o audio.prg main.c

test.inc: test.vgm
	python3 ../tools/bin2c.py test test.vgm test.inc
	
clean:
	rm -f *.prg *.inc *.o
