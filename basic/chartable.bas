10 PRINT CHR$(147);"    0 1 2 3 4 5 6 7 8 9 A B C D E F"
20 FOR Y=0 TO 15: FOR X=0 TO 15
30 C = Y*16+X: CH$ = " "
40 IF (C>=$20 AND C<=$7F) OR (C>=$A0 AND C<=$FF) THEN CH$ = CHR$(C)
50 IF X>0 THEN GOTO 90
60 IF Y<10 THEN GOTO 70
64 PRINT " ";CHR$(Y+$37);"  ";CH$;" ";
67 GOTO 100
70 PRINT Y;" ";CH$;" ";
80 GOTO 100
90 PRINT CH$;" ";
100 NEXT X
110 PRINT:PRINT
120 NEXT Y
130 PRINT:PRINT "    0 1 2 3 4 5 6 7 8 9 A B C D E F":PRINT
140 END
