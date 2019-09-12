all:
	acme -f cbm -DMACHINE_C64=0 -o mode4-demo.prg mode4-demo.asm
	acme -f cbm -DMACHINE_C64=1 -o 64mode4-demo.prg mode4-demo.asm
	
	acme -f cbm -DMACHINE_C64=0 -o mode7-demo.prg mode7-demo.asm
	acme -f cbm -DMACHINE_C64=1 -o 64mode7-demo.prg mode7-demo.asm

	acme -f cbm -DMACHINE_C64=0 -o sprite-demo.prg sprite-demo.asm
	acme -f cbm -DMACHINE_C64=1 -o 64sprite-demo.prg sprite-demo.asm

d64: all
	c1541 -format 64demo,31 d64 disk.d64 -write 64sprite-demo.prg
#	c1541 -format 64demo,31 d64 disk.d64 -write 64mode4-demo.prg -write 64mode7-demo.prg -write 64sprite-demo.prg
	
	
1541: d64
	d64copy -b disk.d64 10
	
clean:
	rm -f *.prg disk.d64