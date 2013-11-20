REM Geek Basic Web Server
REM http://www.geekbasic.com

_TITLE "Geek Basic Web Server"

LET crlf$ = CHR$(13) + CHR$(10) ' carrige return, line feed

CONST users = 100 'total users allowed to connect at a time
CONST totalfiles = 1000 'total files to be accounted for
CONST vars = 100
CONST lines = 1000

DIM userid(users) 'client handle
DIM filename$(totalfiles) 'a list of files will be loaded in here
DIM varname$(vars)
DIM varval(vars)
DIM strname$(vars)
DIM strval$(vars)
DIM cmd$(lines)
DIM par$(lines)

INPUT "Enter a port:"; port

GOSUB checkfiles 'read in the list of files
GOSUB starthosting 'start serving or exit on failure

main:

GOSUB checkconnection 'assign handles to new connections
GOSUB handlerequests 'check for and respond to input

IF INP(96) = 1 THEN

     END

ELSE

     _DELAY .01
     GOTO main

END IF

starthosting:

serverhandle = _OPENHOST("TCP/IP:" + STR$(port))

IF serverhandle THEN

     PRINT "Server started on port #"; port

ELSE

     PRINT "Unable to start server"
     SLEEP
     END

END IF

RETURN

checkfiles:

SHELL "dir www /b > files.dat"

OPEN "files.dat" FOR INPUT AS #1

LET checkfile = 0

WHILE NOT EOF(1)

     LINE INPUT #1, filename$(checkfile)
     LET checkfile = checkfile + 1

WEND

CLOSE #1

RETURN

checkconnection:

LET newconnection = _OPENCONNECTION(serverhandle)

IF newconnection THEN

     FOR user = 0 TO users - 1

          IF userid(user) = 0 THEN

               LET userid(user) = newconnection
               PRINT "New connection handle:"; userid(user)

               EXIT FOR

          END IF

     NEXT user

END IF

RETURN

handlerequests:

FOR user = 0 TO users - 1

     IF userid(user) THEN

          GET #userid(user), , indata$

          LET indata$ = LTRIM$(RTRIM$(indata$))

          IF indata$ <> "" THEN

               IF LEFT$(UCASE$(indata$), 5) = "GET /" THEN

                    LET indata$ = RIGHT$(indata$, LEN(indata$) - 5)

                    IF INSTR(UCASE$(indata$), "HTTP/1.1") THEN LET httptype$ = "HTTP/1.1"
                    IF INSTR(UCASE$(indata$), "HTTP/1.0") THEN LET httptype$ = "HTTP/1.0"

                    LET indata$ = LEFT$(indata$, INSTR(indata$, " ") - 1)

                    IF indata$ = "" OR indata$ = "/" THEN

                         LET indata$ = "index.html"

                    END IF

                    LET page$ = ""

                    GOSUB decodeurl

                    FOR checkfile = 0 TO totalfiles

                         IF checkfile = totalfiles THEN

                              LET page$ = "<!DOCTYPE html><html><body><b>Error!</b><br />The page you requested doesn't exist.</body></html>"

                              EXIT FOR

                         ELSEIF UCASE$(indata$) = UCASE$(filename$(checkfile)) THEN

                              IF INSTR(UCASE$(filename$(checkfile)), ".PNG") THEN

                                   OPEN "www\" + filename$(checkfile) FOR BINARY AS #1

                              ELSE

                                   OPEN "www\" + filename$(checkfile) FOR INPUT AS #1

                              END IF

                              FOR check = 0 TO lines - 1

                                   LET cmd$(check) = ""
                                   LET par$(check) = ""

                              NEXT check

                              LET pointline = 0

                              WHILE NOT EOF(1)

                                   IF INSTR(UCASE$(filename$(checkfile)), ".HTML") THEN

                                        LINE INPUT #1, indata$
                                        LET indata$ = LTRIM$(RTRIM$(indata$)) + crlf$
                                        LET page$ = page$ + indata$

                                   ELSEIF INSTR(UCASE$(filename$(checkfile)), ".GBWS") THEN

                                        LINE INPUT #1, indata$
                                        LET indata$ = LTRIM$(RTRIM$(indata$))

                                        LET space = INSTR(indata$, " ")

                                        IF space THEN

                                             LET cmd$(pointline) = LEFT$(indata$, space - 1)
                                             LET par$(pointline) = MID$(indata$, space + 1, LEN(indata$) - space)

                                        ELSE

                                             LET cmd$(pointline) = indata$
                                             LET par$(pointline) = ""

                                        END IF

                                        IF UCASE$(cmd$(pointline)) = "END" THEN

                                             GOSUB executescript
                                             EXIT WHILE

                                        END IF

                                        LET pointline = pointline + 1

                                   ELSE

                                        GET #1, , indata$
                                        LET page$ = page$ + indata$

                                   END IF

                              WEND

                              CLOSE #1

                              EXIT FOR

                         END IF

                    NEXT checkfile

                    IF RIGHT$(UCASE$(filename$(checkfile)), 4) = ".PNG" THEN

                         LET message$ = httptype$ + " 200 OK" + crlf$
                         LET message$ = message$ + "Content-Type: img/png" + crlf$
                         LET message$ = message$ + "Content-Length: " + STR$(LEN(page$)) + crlf$
                         LET message$ = message$ + "Server: GeekBasicWebServer" + crlf$
                         LET message$ = message$ + "Date: " + DATE$ + crlf$
                         LET message$ = message$ + "Conection: Keep-Alive" + crlf$
                         LET message$ = message$ + crlf$ + page$

                    ELSE

                         LET message$ = httptype$ + " 100 Continue" + crlf$ + "" + crlf$
                         LET message$ = message$ + httptype$ + " 200 OK" + crlf$
                         LET message$ = message$ + "Content-Type: text/html" + crlf$
                         LET message$ = message$ + "Content-Length: " + STR$(LEN(page$)) + crlf$
                         LET message$ = message$ + "Server: GeekBasicWebServer" + crlf$
                         LET message$ = message$ + "Date: " + DATE$ + crlf$
                         LET message$ = message$ + crlf$ + page$

                    END IF

                    PUT #userid(user), , message$

               END IF

               IF NOT EOF(userid(user)) THEN CLOSE userid(user)
               LET userid(user) = 0

          END IF

     END IF

NEXT user

RETURN

executescript:

FOR var = 0 TO vars - 1

     LET varname$(var) = ""
     LET varval(var) = 0
     LET strname$(var) = ""
     LET strval$(var) = ""

NEXT var

FOR pointline = 0 TO lines - 1

     LET c$ = cmd$(pointline)
     LET p$ = par$(pointline)

     SELECT CASE UCASE$(c$)

          CASE "INTEGER": GOSUB executeinteger
          CASE "STRING": GOSUB executestring
          CASE "STRSET": GOSUB executestrset
          CASE "CONCAT": GOSUB executeconcat
          CASE "STRCMP": GOSUB executestrcmp
          CASE "STRVAL": GOSUB executestrval
          CASE "STRLEN": GOSUB executestrlen '
          CASE "STRFIND": GOSUB executestrfind '
          CASE "STRCUT": GOSUB executestrcut '
          CASE "STRTRIM": GOSUB executestrtrim
          CASE "STRUCASE": GOSUB executestrucase
          CASE "STRLCASE": GOSUB executestrlcase
          CASE "LET": GOSUB executelet
          CASE "IF": GOSUB executeif
          CASE "GOTO": GOSUB executegoto
          CASE "RANDOM": GOSUB executerandom
          CASE "OUTPUT": GOSUB executeoutput
          CASE "FORMGET": GOSUB executeformget
          CASE "FORMPOST": GOSUB executeformpost '
          CASE "DATE": GOSUB executedate
          CASE "TIME": GOSUB executetime
          CASE "NEWFILE": GOSUB executenewfile
          CASE "LOADFILE": GOSUB executeloadfile
          CASE "APPENDFILE": GOSUB executeappendfile
          CASE "CLOSEFILE": GOSUB executeclosefile
          CASE "GETSTRING": GOSUB executegetstring
          CASE "PUTSTRING": GOSUB executeputstring
          CASE "CHECKFILE": GOSUB executecheckfile
          CASE ELSE: GOSUB checksyntax

     END SELECT

NEXT pointline

RETURN

executeinteger:

LET comma = INSTR(p$, ",")
LET name$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

FOR check = 0 TO vars - 1

     IF varname$(check) = "" THEN

          LET varname$(check) = name$
          LET varval(check) = VAL(p$)
          EXIT FOR

     END IF

NEXT check

RETURN

executestring:

LET comma = INSTR(p$, ",")
LET name$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

FOR check = 0 TO vars - 1

     IF strname$(check) = "" THEN

          LET strname$(check) = name$
          LET strval$(check) = p$
          EXIT FOR

     END IF

NEXT check

RETURN

executestrset:

LET comma = INSTR(p$, ",")
LET name$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(name$) THEN

          LET strval$(check) = p$
          EXIT FOR

     END IF

NEXT check

RETURN

executeconcat:

LET comma = INSTR(p$, ",")
LET name$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

LET comma = INSTR(p$, ",")
LET name2$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

IF LEFT$(name2$, 1) <> "$" THEN

     LET concatstr1$ = name2$

ELSE

     LET name2$ = RIGHT$(name2$, LEN(name2$) - 1)

     FOR check = 0 TO vars - 1

          IF UCASE$(name2$) = UCASE$(strname$(check)) THEN

               LET concatstr1$ = strval$(check)

               EXIT FOR

          END IF

     NEXT check

END IF

IF LEFT$(p$, 1) <> "$" THEN

     LET concatstr2$ = p$

ELSE

     LET p$ = RIGHT$(p$, LEN(p$) - 1)

     FOR check = 0 TO vars - 1

          IF UCASE$(p$) = UCASE$(strname$(check)) THEN

               LET concatstr2$ = strval$(check)

               EXIT FOR

          END IF

     NEXT check

END IF

FOR check = 0 TO vars - 1

     IF UCASE$(name$) = UCASE$(strname$(check)) THEN

          LET strval$(check) = concatstr1$ + concatstr2$

          EXIT FOR

     END IF

NEXT check

RETURN

executestrcmp:

LET comma = INSTR(p$, ",")
LET name$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

LET comma = INSTR(p$, ",")
LET name2$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(name$) THEN

          FOR check2 = 0 TO vars - 1

               IF UCASE$(strname$(check2)) = UCASE$(name2$) THEN

                    IF strval$(check) = strval$(check2) THEN

                         FOR check3 = 0 TO lines - 1

                              IF UCASE$(cmd$(check3)) = "LABEL" AND UCASE$(par$(check3)) = UCASE$(p$) THEN

                                   LET pointline = check3

                                   EXIT FOR

                              END IF

                         NEXT check3

                    END IF

                    EXIT FOR

               END IF

          NEXT check2

          EXIT FOR

     END IF

NEXT check

RETURN

executestrval:

LET comma = INSTR(p$, ",")
LET name$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

FOR check = 0 TO vars - 1

     IF UCASE$(varname$(check)) = UCASE$(name$) THEN

          FOR check2 = 0 TO vars - 1

               IF UCASE$(strname$(check2)) = UCASE$(p$) THEN

                    LET varval(check) = VAL(strval$(check2))

                    EXIT FOR

               END IF

          NEXT check2

          EXIT FOR

     END IF

NEXT check

RETURN

executestrlen:

RETURN

executestrfind:

RETURN

executestrcut:

RETURN

executestrtrim:

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(p$) THEN

          LET strval$(check) = LTRIM$(RTRIM$(strval$(check)))
          EXIT FOR

     END IF

NEXT check

RETURN

executestrucase:

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(p$) THEN

          LET strval$(check) = UCASE$(strval$(check))
          EXIT FOR

     END IF

NEXT check

RETURN

executestrlcase:

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(p$) THEN

          LET strval$(check) = LCASE$(strval$(check))
          EXIT FOR

     END IF

NEXT check

RETURN

executelet:

LET op$ = ""

IF INSTR(p$, "+") THEN LET op$ = "+"
IF INSTR(p$, "-") THEN LET op$ = "-"
IF INSTR(p$, "*") THEN LET op$ = "*"
IF INSTR(p$, "/") THEN LET op$ = "/"

LET tmp1$ = LTRIM$(RTRIM$(LEFT$(p$, INSTR(p$, "=") - 1)))

IF op$ = "" THEN

     LET tmp2$ = LTRIM$(RTRIM$(MID$(p$, INSTR(p$, "=") + 1, LEN(p$))))
     LET tmp3$ = ""

ELSE

     LET tmp2$ = LTRIM$(RTRIM$(MID$(p$, INSTR(p$, "=") + 1, INSTR(p$, op$) - INSTR(p$, "=") - 1)))
     LET tmp3$ = LTRIM$(RTRIM$(MID$(p$, INSTR(p$, op$) + 1, LEN(p$))))

END IF

LET pointvar1 = -1
LET pointvar2 = -1
LET pointvar3 = -1

FOR check = 0 TO vars - 1

     IF UCASE$(tmp1$) = UCASE$(varname$(check)) THEN LET pointvar1 = check
     IF UCASE$(tmp2$) = UCASE$(varname$(check)) THEN LET pointvar2 = check
     IF UCASE$(tmp3$) = UCASE$(varname$(check)) THEN LET pointvar3 = check

NEXT check

IF pointvar1 <> -1 AND pointvar3 = -1 AND op$ = "" THEN

     IF pointvar2 = -1 THEN

          LET varval(pointvar1) = VAL(tmp2$)

     ELSE

          LET varval(pointvar1) = varval(pointvar2)

     END IF

ELSEIF pointvar1 <> -1 AND op$ = "+" THEN

     IF pointvar2 <> -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = varval(pointvar2) + varval(pointvar3)

     ELSEIF pointvar2 = -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = VAL(tmp2$) + varval(pointvar3)

     ELSEIF pointvar2 <> -1 AND pointvar3 = -1 THEN

          LET varval(pointvar1) = varval(pointvar2) + VAL(tmp3$)

     ELSEIF pointvar2 = -1 AND pointvar3 = -1 THEN

          LET varval(pointvar1) = VAL(tmp2$) + VAL(tmp3$)

     END IF

ELSEIF pointvar1 <> -1 AND op$ = "-" THEN

     IF pointvar2 <> -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = varval(pointvar2) - varval(pointvar3)

     ELSEIF pointvar2 = -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = VAL(tmp2$) - varval(pointvar3)

     ELSEIF pointvar2 <> -1 AND pointvar3 = -1 THEN

          LET varval(pointvar2) = varval(pointvar2) - VAL(tmp3$)

     ELSEIF pointvar2 = -1 AND pointvar3 = -1 THEN

          LET varval(pointvar2) = VAL(tmp2$) - VAL(tmp3$)

     END IF

ELSEIF pointvar1 <> -1 AND op$ = "*" THEN

     IF pointvar2 <> -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = varval(pointvar2) * varval(pointvar3)

     ELSEIF pointvar2 = -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = VAL(tmp2$) * varval(pointvar3)

     ELSEIF pointvar2 <> -1 AND pointvar3 = -1 THEN

          LET varval(pointvar2) = varval(pointvar2) * VAL(tmp3$)

     ELSEIF pointvar2 = -1 AND pointvar3 = -1 THEN

          LET varval(pointvar2) = VAL(tmp2$) * VAL(tmp3$)

     END IF

ELSEIF pointvar1 <> -1 AND op$ = "/" THEN

     IF pointvar2 <> -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = varval(pointvar2) / varval(pointvar3)

     ELSEIF pointvar2 = -1 AND pointvar3 <> -1 THEN

          LET varval(pointvar1) = VAL(tmp2$) / varval(pointvar3)

     ELSEIF pointvar2 <> -1 AND pointvar3 = -1 THEN

          LET varval(pointvar2) = varval(pointvar2) / VAL(tmp3$)

     ELSEIF pointvar2 = -1 AND pointvar3 = -1 THEN

          LET varval(pointvar2) = VAL(tmp2$) / VAL(tmp3$)

     END IF

END IF

RETURN

executeif:

LET op$ = ""

IF INSTR(p$, "=") THEN LET op$ = "="
IF INSTR(p$, "<") THEN LET op$ = "<"
IF INSTR(p$, ">") THEN LET op$ = ">"
IF INSTR(p$, "<>") THEN LET op$ = "<>"
IF INSTR(p$, "<=") THEN LET op$ = "<="
IF INSTR(p$, ">=") THEN LET op$ = ">="

LET ol = LEN(op$)

LET tmp1$ = LTRIM$(RTRIM$(LEFT$(p$, INSTR(p$, op$) - 1)))
LET tmp2$ = LTRIM$(RTRIM$(MID$(p$, INSTR(p$, op$) + ol, INSTR(p$, ":") - INSTR(p$, op$) - ol)))
LET tmp3$ = LTRIM$(RTRIM$(MID$(p$, INSTR(p$, ":") + 1, LEN(p$))))

LET pointvar1 = -1
LET pointvar2 = -1

FOR check = 0 TO vars - 1

     IF UCASE$(tmp1$) = UCASE$(varname$(check)) THEN LET pointvar1 = check
     IF UCASE$(tmp2$) = UCASE$(varname$(check)) THEN LET pointvar2 = check

NEXT check

LET target$ = ""

IF pointvar1 <> -1 AND pointvar2 = -1 THEN

     IF varval(pointvar1) = VAL(tmp2$) AND op$ = "=" THEN LET target$ = tmp3$
     IF varval(pointvar1) > VAL(tmp2$) AND op$ = ">" THEN LET target$ = tmp3$
     IF varval(pointvar1) < VAL(tmp2$) AND op$ = "<" THEN LET target$ = tmp3$
     IF varval(pointvar1) <> VAL(tmp2$) AND op$ = "<>" THEN LET target$ = tmp3$
     IF varval(pointvar1) >= VAL(tmp2$) AND op$ = ">=" THEN LET target$ = tmp3$
     IF varval(pointvar1) <= VAL(tmp2$) AND op$ = "<=" THEN LET target$ = tmp3$

ELSEIF pointvar1 = -1 AND pointvar2 <> -1 THEN

     IF VAL(tmp1$) = varval(pointvar2) AND op$ = "=" THEN LET target$ = tmp3$
     IF VAL(tmp1$) > varval(pointvar2) AND op$ = ">" THEN LET target$ = tmp3$
     IF VAL(tmp1$) < varval(pointvar2) AND op$ = "<" THEN LET target$ = tmp3$
     IF VAL(tmp1$) <> varval(pointvar2) AND op$ = "<>" THEN LET target$ = tmp3$
     IF VAL(tmp1$) >= varval(pointvar2) AND op$ = ">=" THEN LET target$ = tmp3$
     IF VAL(tmp1$) <= varval(pointvar2) AND op$ = "<=" THEN LET target$ = tmp3$

ELSEIF pointvar1 = -1 AND pointvar2 = -2 THEN

     IF VAL(tmp1$) = VAL(tmp2$) AND op$ = "=" THEN LET target$ = tmp3$
     IF VAL(tmp1$) > VAL(tmp2$) AND op$ = ">" THEN LET target$ = tmp3$
     IF VAL(tmp1$) < VAL(tmp2$) AND op$ = "<" THEN LET target$ = tmp3$
     IF VAL(tmp1$) <> VAL(tmp2$) AND op$ = "<>" THEN LET target$ = tmp3$
     IF VAL(tmp1$) >= VAL(tmp2$) AND op$ = ">=" THEN LET target$ = tmp3$
     IF VAL(tmp1$) <= VAL(tmp2$) AND op$ = "<=" THEN LET target$ = tmp3$

ELSEIF pointvar1 <> -1 AND pointvar2 <> -2 THEN

     IF varval(pointvar1) = varval(pointvar2) AND op$ = "=" THEN LET target$ = tmp3$
     IF varval(pointvar1) > varval(pointvar2) AND op$ = ">" THEN LET target$ = tmp3$
     IF varval(pointvar1) < varval(pointvar2) AND op$ = "<" THEN LET target$ = tmp3$
     IF varval(pointvar1) <> varval(pointvar2) AND op$ = "<>" THEN LET target$ = tmp3$
     IF varval(pointvar1) >= varval(pointvar2) AND op$ = ">=" THEN LET target$ = tmp3$
     IF varval(pointvar1) <= varval(pointvar2) AND op$ = "<=" THEN LET target$ = tmp3$

END IF

IF target$ <> "" THEN

     FOR check = 0 TO lines - 1

          IF UCASE$(cmd$(check)) = "LABEL" AND UCASE$(par$(check)) = UCASE$(target$) THEN

               LET pointline = check

               EXIT FOR

          END IF

     NEXT check

END IF

RETURN

executegoto:

FOR check = 0 TO lines - 1

     IF UCASE$(cmd$(check)) = "LABEL" AND UCASE$(par$(check)) = UCASE$(p$) THEN

          LET pointline = check

          EXIT FOR

     END IF

NEXT check

RETURN

executerandom:

LET comma = INSTR(p$, ",")
LET name$ = LEFT$(p$, comma - 1)
LET p$ = RIGHT$(p$, LEN(p$) - comma)

LET comma = INSTR(p$, ",")
LET range1 = VAL(LEFT$(p$, comma - 1))
LET p$ = RIGHT$(p$, LEN(p$) - comma)

LET range2 = VAL(p$)

FOR check = 0 TO vars - 1

     IF UCASE$(varname$(check)) = UCASE$(name$) THEN

          LET varval(check) = INT(RND * range2) + range1

          EXIT FOR

     END IF

NEXT check

RETURN

executeoutput:

IF LEFT$(p$, 1) = "$" THEN

     FOR check = 0 TO vars - 1

          IF UCASE$(strname$(check)) = UCASE$(RIGHT$(p$, LEN(p$) - 1)) THEN

               LET page$ = page$ + strval$(check)

          END IF

     NEXT check

ELSEIF LEFT$(p$, 1) = "*" THEN

     FOR check = 0 TO vars - 1

          IF UCASE$(varname$(check)) = UCASE$(RIGHT$(p$, LEN(p$) - 1)) THEN

               LET page$ = page$ + STR$(varval(check))

          END IF

     NEXT check

ELSE

     LET page$ = page$ + p$

END IF

RETURN

executeformget:

IF INSTR(UCASE$(urlpar$), UCASE$(p$)) THEN

     LET decode$ = ""

     FOR check = 0 TO vars - 1

          IF UCASE$(strname$(check)) = UCASE$(p$) THEN

               FOR check2 = INSTR(UCASE$(urlpar$), UCASE$(p$)) + LEN(p$) + 1 TO LEN(urlpar$)

                    IF MID$(urlpar$, check2, 1) <> "&" THEN

                         LET decode$ = decode$ + MID$(urlpar$, check2, 1)

                    ELSE

                         EXIT FOR

                    END IF

               NEXT check2

               LET strval$(check) = decode$

               EXIT FOR

          END IF

     NEXT check

END IF

RETURN

executeformpost:

RETURN

executedate:

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(p$) THEN

          LET strval$(check) = DATE$

          EXIT FOR

     END IF

NEXT check

RETURN

executetime:

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(p$) THEN

          LET strval$(check) = TIME$

          EXIT FOR

     END IF

NEXT check

RETURN

executenewfile:

IF LEFT$(p$, 1) = "$" THEN

     FOR check = 0 TO vars - 1

          IF UCASE$(strname$(check)) = UCASE$(p$) THEN

               OPEN strval$(check) FOR OUTPUT AS #2

               EXIT FOR

          END IF

     NEXT check

ELSE

     OPEN "www\" + p$ FOR OUTPUT AS #2

END IF

RETURN

executeloadfile:

IF LEFT$(p$, 1) = "$" THEN

     FOR check = 0 TO vars - 1

          IF UCASE$(strname$(check)) = UCASE$(p$) THEN

               OPEN strval$(check) FOR INPUT AS #2

               EXIT FOR

          END IF

     NEXT check

ELSE

     OPEN "www\" + p$ FOR INPUT AS #2

END IF

RETURN

executeappendfile:

IF LEFT$(p$, 1) = "$" THEN

     FOR check = 0 TO vars - 1

          IF UCASE$(strname$(check)) = UCASE$(p$) THEN

               OPEN strval$(check) FOR APPEND AS #2

               EXIT FOR

          END IF

     NEXT check

ELSE

     OPEN "www\" + p$ FOR APPEND AS #2

END IF

RETURN

executeclosefile:

CLOSE #2

RETURN

executegetstring:

FOR check = 0 TO vars - 1

     IF UCASE$(strname$(check)) = UCASE$(p$) THEN

          LINE INPUT #2, strval$(check)

          EXIT FOR

     END IF

NEXT check

RETURN

executeputstring:

IF LEFT$(p$, 1) = "$" THEN

     FOR check = 0 TO vars - 1

          IF UCASE$(strname$(check)) = UCASE$(RIGHT$(p$, LEN(p$) - 1)) THEN

               PRINT #2, strval$(check)

          END IF

     NEXT check

ELSEIF LEFT$(p$, 1) = "*" THEN

     FOR check = 0 TO vars - 1

          IF UCASE$(varname$(check)) = UCASE$(RIGHT$(p$, LEN(p$) - 1)) THEN

               PRINT #2, STR$(varval(check))

          END IF

     NEXT check

ELSE

     PRINT #2, p$

END IF

RETURN

executecheckfile:

FOR check = 0 TO vars - 1

     IF UCASE$(varname$(check)) = UCASE$(p$) THEN

          LET varval(check) = EOF(2)

          EXIT FOR

     END IF

NEXT check

RETURN

checksyntax:

IF c$ <> "" AND UCASE$(c$) <> "REM" AND UCASE$(c$) <> "END" AND UCASE$(c$) <> "LABEL" THEN

     LET page$ = "<!DOCTYPE html><html><body><b>Error</b><br />Bad command on line #" + STR$(pointline) + "</body></html>"

END IF

RETURN

decodeurl:

IF INSTR(indata$, "?") THEN

     LET urlpar$ = RIGHT$(indata$, LEN(indata$) - INSTR(indata$, "?"))
     LET indata$ = LEFT$(indata$, INSTR(indata$, "?") - 1)

     LET decode$ = ""

     FOR check = 1 TO LEN(urlpar$)

          IF LEN(urlpar$) - check >= 2 THEN

               SELECT CASE UCASE$(MID$(urlpar$, check, 3))

                    CASE "%20": LET decode$ = decode$ + " ": LET check = check + 2
                    CASE "%21": LET decode$ = decode$ + "!": LET check = check + 2
                    CASE "%22": LET decode$ = decode$ + CHR$(34): LET check = check + 2
                    CASE "%23": LET decode$ = decode$ + "#": LET check = check + 2
                    CASE "%24": LET decode$ = decode$ + "$": LET check = check + 2
                    CASE "%25": LET decode$ = decode$ + "%": LET check = check + 2
                    CASE "%26": LET decode$ = decode$ + "&": LET check = check + 2
                    CASE "%27": LET decode$ = decode$ + "'": LET check = check + 2
                    CASE "%28": LET decode$ = decode$ + "(": LET check = check + 2
                    CASE "%29": LET decode$ = decode$ + ")": LET check = check + 2
                    CASE "%2A": LET decode$ = decode$ + "*": LET check = check + 2
                    CASE "%2B": LET decode$ = decode$ + "+": LET check = check + 2
                    CASE "%2C": LET decode$ = decode$ + ",": LET check = check + 2
                    CASE "%2D": LET decode$ = decode$ + "-": LET check = check + 2
                    CASE "%2E": LET decode$ = decode$ + ".": LET check = check + 2
                    CASE "%2F": LET decode$ = decode$ + "/": LET check = check + 2
                    CASE "%3A": LET decode$ = decode$ + ":": LET check = check + 2
                    CASE "%3B": LET decode$ = decode$ + ";": LET check = check + 2
                    CASE "%3C": LET decode$ = decode$ + "<": LET check = check + 2
                    CASE "%3D": LET decode$ = decode$ + "=": LET check = check + 2
                    CASE "%3E": LET decode$ = decode$ + ">": LET check = check + 2
                    CASE "%3F": LET decode$ = decode$ + "?": LET check = check + 2
                    CASE "%40": LET decode$ = decode$ + "@": LET check = check + 2
                    CASE ELSE

                         IF MID$(urlpar$, check, 1) = "+" THEN

                              LET decode$ = decode$ + " "

                         ELSE

                              LET decode$ = decode$ + MID$(urlpar$, check, 1)

                         END IF


               END SELECT

          ELSE

               IF MID$(urlpar$, check, 1) = "+" THEN

                    LET decode$ = decode$ + " "

               ELSE

                    LET decode$ = decode$ + MID$(urlpar$, check, 1)

               END IF

          END IF

     NEXT check

     LET urlpar$ = decode$

ELSE

     LET urlpar$ = ""

END IF

RETURN

