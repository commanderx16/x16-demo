0 REM **COMMANDER X16 MANDELBROT   **
1 REM **BY SERERRIS 16.08.2020     **
2 REM **FOR LEARNING AND EDUCATION **
3 REM **THIS MANDELBROT USES BOTH VERA DATA REGISTERS TO SPEEDUP 
4 REM **RENDERING
100 REM VARIABLES SETUP
110 REM MANDELBROT DIMENSIONS
120 XL=-2.000:XU=0.500
130 YL=-1.100:YU=1.100
140 MI=20 :REM MAXIMUM ITERATIONS
150 WI=320:HI=240 :REM SCREEN DIMENSIONS
155 MA=WI*HI+$4000 :REM END OF SCREEN ADDRESS
160 XI=(XU-XL)/WI :REM X INCREMENT
170 YI=(YU-YL)/HI :REM Y INCREMENT
300 REM SCREEN SETUP
310 GOSUB 10000:REM SETUP SCREEN
320 GOSUB 10100:REM MOVE CHARROM
330 GOSUB 15000 :REM SETUP PALLETTE
340 GOSUB 10200:REM SET VRAM ADDR0 TO BEGIN $4000
500 REM MAIN ROUTINE
510 XE=XU-XI:YE=YL+(HI/2*YI) :REM DEFINE LOOP END FOR FASTER LOOPING
520 TA=MA :REM SET UPPER ADDRESS TO END OF SCREEN
530 FOR Y0=YL TO YE STEP YI
540 REM CACULATE UPPER VRAM ADDRESS
550 TA=TA-WI:AP=0:AB=TA
560 IF AB>$FFFF THEN AP=1:AB=AB-$10000 :REM SET AP FOR PAGE
570 AH=INT(AB/256) : REM GATHER HI BYTE
580 AL=AB-AH*256 : REM GATHER LOW BYTE
590 REM SET ADDRESS REGISTER FOR DATA BYTE 1
600 POKE $9F25,$01:POKE $9F20,AL:POKE $9F21,AH:POKE $9F22,($10+AP)
610 FOR X0=XL TO XE STEP XI
620 GOSUB 2000 :REM CALCULATE MANDELBROT
700 POKE $9F23,IT:REM PUT ACTUAL ITERATION INTO VRAM LINE
710 POKE $9F24,IT:REM PUT ACTUAL ITERATION INTO MIRRORED LINE
800 NEXT X0
810 NEXT Y0
1900 REM THE END
1910 GET A$:IF A$="" THEN GOTO 1910
1920 GOSUB 16000:REM CLEANUP MODE
1930 END
2000 :REM CALCULATE MANDELBROT
2010 X=0:Y=0:IT=0
2020 X2=0:Y2=0
2030 :REM WHILE
2040 FOR K=1 TO MI
2050 XY=X*Y
2060 X=X2-Y2+X0
2070 Y=2*XY+Y0
2080 X2=X*X:Y2=Y*Y
2090 IF (X2+Y2 > 4) AND (IT <= MI) THEN IT=K:K=MI 
2100 NEXT
2110 IF IT=MI THEN IT=0
2120 IT=IT-INT(IT/16)*16
2200 RETURN
10000 :REM SETUP SCREEN SCALING 2X = 320X240
10005 CLS:PRINT "PREPARING SCREEN ...";
10010 POKE $9F2B,$40:POKE $9F2A,$40
10020 REM SETUP BITMAP MODE 8BPP AND BITMAP START $4000
10030 POKE $9F2F,$20:POKE $9F2D,$07:POKE $9F29,PEEK($9F29) OR $10
10050 RETURN
10100 :REM MOVE CHARROM
10110 FOR I=0 TO $7FF
10115 BT=VPEEK(0,$F800+I)
10120 VPOKE 1,$F000+I,BT
10130 NEXT
10140 POKE $9F36,$F8
10150 RETURN
10200 :REM SETUP VRAM ADDRESS AND INCREMENT
10210 POKE $9F21,$40:POKE $9F20,$00:POKE $9F22,$10
10220 RETURN
15000 REM SET PALLETTE
15010 FOR I=0 TO 16*2+1
15020 READ P
15030 VPOKE 1,$FA00+I,P
15040 NEXT I
15050 COLOR 9,0 :PRINT CHR$(147);
15060 RETURN
16000 REM CLEANUP
16010 POKE $9F29,PEEK($9F29) AND $EF
16020 POKE $9F2B,$80:POKE $9F2A,$80
16030 CLS
16040 RETURN
20000 REM COLOR DATA
20010 DATA 0,0,2,0,20,0,22,0,56,2,74,2
20020 DATA 92,3,140,6,207,11,235,15,195,15
20030 DATA 176,15,128,12,64,6,32,4,16,2,2,1
