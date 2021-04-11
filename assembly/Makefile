all:
	acme -f cbm -DMACHINE_C64=0 -o tilemap-demo.prg tilemap-demo.asm
	acme -f cbm -DMACHINE_C64=1 -o 64tilemap-demo.prg tilemap-demo.asm
	
	acme -f cbm -DMACHINE_C64=0 -o bitmap-demo.prg bitmap-demo.asm
	acme -f cbm -DMACHINE_C64=1 -o 64bitmap-demo.prg bitmap-demo.asm

	acme -f cbm -DMACHINE_C64=0 -o sprite-demo.prg sprite-demo.asm
	acme -f cbm -DMACHINE_C64=1 -o 64sprite-demo.prg sprite-demo.asm

d64: all
	c1541 -format 64demo,31 d64 disk.d64 -write 64sprite-demo.prg
#	c1541 -format 64demo,31 d64 disk.d64 -write 64tilemap-demo.prg -write 64bitmap-demo.prg -write 64sprite-demo.prg
	
	
1541: d64
	d64copy -b disk.d64 10
	
clean:
	rm -f *.prg disk.d64