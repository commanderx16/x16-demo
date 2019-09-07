all: smiley.bas

simley.bas: smiley.inc
	cat prolog.inc smiley.inc > smiley.bas

smiley.inc: smiley.png
	python3 ../tools/png2sprite.py -f basic smiley.png smiley.inc
	
clean:
	rm -f smiley.inc smiley.bas
