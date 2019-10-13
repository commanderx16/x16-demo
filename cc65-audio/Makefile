all: audio.prg

audio.prg: main.c vgm.inc
	cl65 -t cx16 -O -o audio.prg main.c

vgm.inc: test.vgm
	python3 ../tools/bin2c.py vgmData test.vgm vgm.inc
	
clean:
	rm -f *.prg *.inc *.o
