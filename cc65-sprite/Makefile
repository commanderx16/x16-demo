all: demo.prg

demo.prg: demo.c balloon.inc
	cl65 -t cx16 -O -o demo.prg demo.c

balloon.inc: balloon.png
	python3 ../tools/png2sprite.py -n balloon balloon.png balloon.inc
	
clean:
	rm -f *.prg *.inc *.o
