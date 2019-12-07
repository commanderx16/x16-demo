10 ? "******************************************"
15 ? "*                                        *"
20 ? "*  TRAVELLER STARSHIP BUILDER V1.0       *"
25 ? "*                                        *"
30 ? "*  USE THIS MENU SYSTEM TO DESIGN A      *"
35 ? "*  STARSHIP ACCORDING TO YOUR SPECS      *"
45 ? "*                                        *"
50 ? "******************************************"
55 ?

90 HX$ = "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ"
91 HY$ = "000000000000000000111111222222222222"
92 HS$ = "B": HV = 2: J$ = " ": M$ = " ": P$ = " ": CC$ = "1"
95 DIM HP$(24)
100 REM ******************************************
101 REM MAIN LOOP
109 REM ******************************************
110 GOSUB 200: REM SUMMARY
120 ? "**************  MAIN MENU ****************":?
130 ?:? " Q - QUIT"
131 ?:? " 1 - SELECT MISSION (" MC$ ")"
132 ?:? " 2 - SELECT HULL CODE (" HS$ ")"
133 ?:? " 3 - SELECT HULL CONFIG (" HC$ ")"
134 ?:? " 4 - SELECT LANDING GEAR (" LG$ ")"
135 ?:? " 5 - SELECT JUMP DRIVE (" J ")"
136 ?:? " 6 - SELECT MANEUVER DRIVE (" M ")"
137 ?:? " 7 - SELECT COMPUTER (MODEL/" CC$ ")"
138 IF HS$ <> "" THEN ?:? " 8 - SELECT DEFENSES"
139 ?
140 GET K$:IF K$="" GOTO 140
141 IF K$ = "Q" GOTO 300
142 IF K$ = "8" AND HS$ = "" GOTO 140
143 IF K$ < "1" OR K$ > "8" GOTO 140 
145 ON VAL(K$) GOSUB 1100,1200,1300,1400,1500,1600,1650,1700
190 GOTO 110

200 ? "**************  SUMMARY  *****************":?
210 W$="": FOR X=0 TO HP%: W$ = W$ + LEFT$(HP$(X),1): NEXT
220 ? " QSP: " MC$ "-" HS$ HC$ LG$ M$ J$ "-" CC$ " " W$:?
221 HV$ = RIGHT$("    "+STR$(HV*100),5)
222 HC=HV: REM TODO
230 J = VAL(J$): IF J$ = "H" THEN J = 1
231 JT = 5 + INT(J * HV * 2.5): IF JT = 5 THEN JT = 0
232 JT$ = RIGHT$("    "+STR$(JT),5)
233 M = VAL(M$)
234 MT = INT(M * HV): IF MT > 2 THEN MT = MT - 1
235 MT$ = RIGHT$("    "+STR$(MT),5)
236 P$ = M$: IF J$ > M$ THEN P$ = J$
237 P = VAL(P$)
238 PT = 1 + INT(P * HV): IF PT = 1 THEN PT = 0
239 PT$ = RIGHT$("    "+STR$(PT),5)
240 FU = HV * (J*10 + M)
241 FU$ = RIGHT$("    "+STR$(FU),5)
250 H$ = LEFT$(HS$+HC$+LG$ + "   ",3)
251 CT = VAL(CC$) * (VAL(CC$) + 0.5)
260 ? " TONS   COMPONENT    MCR"
261 ? " ----  -----------  ----"
262 ? HV$    "  HULL " H$ "    " RIGHT$("     "+STR$(HC),5)
263 ? " ----                   "
264 ? "    " CC$ "  MODEL/" CC$ "      " RIGHT$("     " + STR$(CT ), 4)
265 ? JT$    "  J-DRIVE-" J$ "    " RIGHT$("     " + STR$(JT  ), 4)
266 ? MT$    "  M-DRIVE-" M$ "    " RIGHT$("     " + STR$(MT*2), 4)
267 ? PT$    "  P-PLANT-" P$ "    " RIGHT$("     " + STR$(PT  ), 4)
268 ? FU$    "  FUEL            -"
270 WT=0:FOR X=0 TO HP%: IF LEN(HP$(X)) = 0 GOTO 279
271 WT=WT+1
278 ? "    1  "   HP$(X) "     1"
279 NEXT
280 TF=INT(HV*100 - JT - MT - PT - FU - WT - VAL(CC$))
281 TF$ = RIGHT$("     "+STR$(TF),5)
282 TC = HC+JT+MT*2+PT+WT+CT
283 TC$ = RIGHT$("     "+STR$(TC),5)
284 ? TF$    "  CARGO           -"
290 ? "                    ----"
291 ? "                   " TC$
292 ?
299 RETURN

300 REM ******************************************
301 REM QUIT
309 REM ******************************************
320 ? " QSP: " MC$ "-" HS$ HC$ LG$ M$ J$ "-" CC$ " " W$:?
399 END

1100 REM ******************************************
1101 REM MISSION CODE
1109 REM ******************************************
1110 ? "SHIP MISSION CODE":?
1111 ? " A - TRADER"
1112 ? " C - CRUISER"
1113 ? " E - ESCORT"
1114 ? " F - FREIGHTER"
1115 ? " G - FRIGATE"
1116 ? " J - PROSPECTOR"
1117 ? " K - TOURING SHIP"
1118 ? " L - LAB SHIP"
1119 ? " M - LINER"
1120 ? " P - CORSAIR"
1121 ? " R - MERCHANT"
1122 ? " S - SCOUT/COURIER"
1123 ? " T - TRANSPORT"
1124 ? " U - PACKET"
1125 ? " V - CORVETTE"
1126 ? " X - EXPRESS"
1127 ? " Y - YACHT"
1128 ?
1130 GET K$: IF K$ < "A" OR K$ > "Z" GOTO 1130
1140 MC$ = K$
1190 RETURN

1200 REM ******************************************
1201 REM HULL CODE
1209 REM ******************************************
1210 ? "HULL SIZE CODE":?
1215 FOR X = 1 TO 24
1220 ? " " MID$(HX$,X+10,1) " -" X * 100 "TONS" 
1230 NEXT:?
1240 GET K$:IF K$ < "A" OR K$="I" OR K$="O" OR K$>"Z" GOTO 1240
1250 HS$ = K$
1255 HV = ASC(HS$)-64
1260 IF HS$ > "H" THEN HV = HV - 1
1265 IF HS$ > "N" THEN HV = HV - 1
1290 RETURN

1300 REM ******************************************
1301 REM HULL CONFIG
1309 REM ******************************************
1310 ? "HULL CONFIGURATION":?
1311 ? " 1 - PLANETOID"
1312 ? " 2 - CLUSTER"
1313 ? " 3 - BRACED"
1314 ? " 4 - UNSTREAMLINED"
1315 ? " 5 - STREAMLINED"
1316 ? " 6 - AIRFRAME"
1317 ? " 7 - LIFTING BODY"
1320 ?
1325 GET K$: IF K$ < "1" OR K$ > "7" GOTO 1325
1330 HC$ = MID$("PCBUSAL",VAL(K$),1)
1390 RETURN

1400 REM ******************************************
1401 REM LANDING GEAR
1409 REM ******************************************
1410 ? "LANDING GEAR":?
1411 ? " 1 - NONE"
1412 ? " 2 - SKIDS"
1413 ? " 3 - LANDERS"
1414 ? " 4 - WHEELS"
1420 ?
1425 GET K$: IF K$ < "1" OR K$ > "4" GOTO 1425
1430 LG$ = MID$("NSLW",VAL(K$),1)
1490 RETURN

1500 REM ******************************************
1501 REM JUMP DRIVE
1509 REM ******************************************
1510 ? "JUMP DRIVE":?
1511 ? " 1 - JUMP-1"
1512 ? " 2 - JUMP-2"
1513 ? " 3 - JUMP-3"
1514 ? " 4 - JUMP-4"
1515 ? " 5 - JUMP-5"
1516 ? " 6 - JUMP-6"
1517 ? " 7 - JUMP-7"
1518 ? " H - HOP-1"
1520 ?
1525 GET K$: IF K$ = "H" GOTO 1535
1530 IF K$ < "1" OR K$ > "7" GOTO 1525
1535 J$ = K$
1590 RETURN

1600 REM ******************************************
1601 REM MANEUVER DRIVE
1609 REM ******************************************
1610 ? "MANEUVER DRIVE"
1611 ? " 1 - 1G"
1612 ? " 2 - 2G"
1613 ? " 3 - 3G"
1614 ? " 4 - 4G"
1615 ? " 5 - 5G"
1616 ? " 6 - 6G"
1617 ? " 7 - 7G"
1618 ? " 8 - 8G"
1619 ? " 9 - 9G"
1620 ?
1625 GET K$
1630 IF K$ < "1" OR K$ > "9" GOTO 1625
1635 M$ = K$
1649 RETURN

1650 REM ******************************************
1651 REM COMPUTER
1659 REM ******************************************
1660 ? "COMPUTER MODEL"
1661 ? " 1 - MODEL/1"
1662 ? " 2 - MODEL/2"
1663 ? " 3 - MODEL/3"
1664 ? " 4 - MODEL/4"
1665 ? " 5 - MODEL/5"
1666 ? " 6 - MODEL/6"
1667 ? " 7 - MODEL/7"
1668 ? " 8 - MODEL/8"
1669 ? " 9 - MODEL/9"
1670 ?
1675 GET K$
1680 IF K$ < "1" OR K$ > "9" GOTO 1675
1685 CC$ = K$
1699 RETURN

1700 REM ******************************************
1701 REM HARDPOINTS
1709 REM ******************************************
1710 S% = 0: MA% = 0
1711 IF MC$ = "C" OR MC$ = "E" OR MC$ = "G" OR MC$ = "V" THEN MA% = 1
1712 HP% = HV-1: IF HP% > 9 THEN HP% = 9
1714 ? "  TURRET / CONTENTS             "
1715 ? "  ------   ---------------------"
1716 FOR X = 0 TO HP%
1717 IF S% = X THEN ? "*";
1718 IF S% <> X THEN ? " ";
1719 ? " " X ":     " HP$(X)
1720 NEXT X
1721 ? "   K : PULSE LASER TURRET"
1722 ? "   L : BEAM LASER TURRET"
1723 ? "   M : MISSILE LAUNCHER TURRET"
1724 ? "   S : SANDCASTER TURRET"
1725 IF MA% = 1 THEN ? "   P : PLASMA BARBETTE"
1729 ? "   Q : QUIT MENU":?
1730 GET A$: IF A$ = "" GOTO 1730
1740 IF A$ = "K" THEN HP$(S%) = "K (PULSE L)"
1741 IF A$ = "L" THEN HP$(S%) = "L (BEAM L) "
1742 IF A$ = "M" THEN HP$(S%) = "MISSILE    "
1743 IF A$ = "S" THEN HP$(S%) = "SANDCASTER "
1744 IF MA% = 1 AND A$ = "P" THEN HP$(S%) = "PLASMA     "
1750 IF A$ = "Q" GOTO 1790
1755 IF A$ >= "0" AND A$ <= MID$(STR$(HP%),2,1) THEN S% = VAL(A$): GOTO 1714
1760 GOTO 1714
1790 RETURN

