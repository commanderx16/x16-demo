0 REM A LOADER FOR IMAGES IN KOALA PAINTER FORMAT
10 DIMV%(15):FORI=0TO15:V%(I)=I+16*I:NEXT:TI$="000000"
15 PRINT CHR$(147):INPUT"PICTURE FILE:";A$
18 IF A$="" THEN A$="TESTIMG2.PIC"
20 GOSUB 20000:GOSUB 10000:TT=TI
30 GETA$:IFA$=""THEN30
40 GOSUB 25000:PRINT"TIME: ";TT:END
10000 LOADA$,8,1,40960
10015 BS=40960:SS=BS+8000:CS=SS+1000:BG=CS+1000
10055 MP=0:MC=0:MS=0:YA=0:X=0:Y=0:D=4:BO=PEEK(40801)
10060 FORI=0TO7999
10070 PP=BS+MP:GOSUB 16000:B=PP:PO=Y+X
10080 P=INT(B/64):GOSUB 15000:VPOKE0,PO,V%(CV)
10100 P=(B/16) AND 3:GOSUB 15000:VPOKE0,PO+1,V%(CV)
10120 P=(B/4) AND 3:GOSUB 15000:VPOKE0,PO+2,V%(CV)
10140 P=B AND 3:GOSUB 15000:VPOKE0,PO+3,V%(CV)
10190 X=X+4:MP=MP+8
10200 IF X<160 THEN NEXT:RETURN
10210 X=0:Y=Y+160:MP=MP-319:MC=MC+1:IFMC=8THENMS=MS+320:MP=MS:MC=0:YA=YA+40
10220 NEXT
11000 RETURN
15000 IF P=0 THEN PP=BG:GOSUB 16000:CV=PP AND 15:RETURN
15010 CP=X/D+YA
15020 IF P=3 THEN PP=CS+CP:GOSUB 16000:CV=PP AND 15:RETURN
15030 IF P=2 THEN PP=SS+CP:GOSUB 16000:CV=PP AND 15:RETURN
15040 IF P=1 THEN PP=SS+CP:GOSUB 16000:CV=PP/16:RETURN
15050 PRINT "????":GOSUB 25000:END
16000 BA=1:IF (PP>49151) THEN PP=PP-8192:BA=2
16015 POKE40801,BA:PP=PEEK(PP):POKE40801,BO:RETURN
20000 DIM IV%(7)
20010 IV%(0)=VPEEK(15,2):IV%(1)=VPEEK(15,1):IV%(2)=VPEEK(15,$2000)
20020 IV%(3)=VPEEK(15,$3005):IV%(4)=VPEEK(15,$3001)
20030 IV%(5)=VPEEK(15,$3000):IV%(6)=PEEK(218)
20110 VPOKE 15,2,64:VPOKE 15,1,64:POKE 218,40:VPOKE15,$2000,0
20120 VPOKE 15,$3005,$0:VPOKE 15,$3001,$0:VPOKE 15,$3000,193
20130 RETURN
25000 VPOKE 15,2,IV%(0):VPOKE 15,1,IV%(1):VPOKE15,$2000,IV%(2)
25010 VPOKE 15,$3005,IV%(3):VPOKE 15,$3001,IV%(4):VPOKE 15,$3000,IV%(5)
25020 POKE 218,IV%(6):PRINTCHR$(147);:RETURN
