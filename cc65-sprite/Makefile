all: demo.prg

demo.prg: demo.c balloon.inc
	cl65 -t c64 -O -o demo.prg demo.c

balloon.inc: balloon.png
	python3 ../tools/png2sprite.py balloon.png balloon.inc balloon
	
clean:
	rm -f *.prg *.inc *.o
