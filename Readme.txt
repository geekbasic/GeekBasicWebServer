Geek Basic Web Server

Description:

 This package contains a TCP/IP HTTP web server written in QB64.
 The server will currently serve all htm/html files found in the www directory.
 Only PNG images may be used. Subdirectories are not currently supported.
 A server side scripting language is now functional, but very incomplete.
 Inline css and scripts are recommended until all downloads are supported.

Usage:

 Copy your html files to the www directory and run the httpserv executable.

Future Plans:

 Support all file downloads and images.

 Data logging (ip addresses, requests, etc)

 Arrays

Script Commands

Command: INTEGER
Usage: integer variable,value
Description: Declare and initialize new integer variable.

Command: STRING
Usage: string variable,initial text (may blank)
Description: Declare and initialize new string variable.

Command: STRSET
Usage: strset stringvariable,any text
Description: Set a string variable as some text.

Command: CONCAT
Usage concat destinationstring,$stringvariable1,$stringvariable2
Other Usage: destinationstring,string,$stringvariable
Other Usage: destinationstring,$stringvariable,string
Description: Concatenate two strings/string variables into a destination string.

Command: STRCMP
Usage: strcmp str1,str2,labelname
Description: If two string variables are equal, then jump to a label.

Command: STRVAL
Usage: integervariable,stringvariable
Description: Return the value of a string into an integer variable.

Command: STRTRIM
Usage: strtrim stringvariable
Description: Removes white spacing from the both sides of a string variable.

Command: STRLCASE
Usage: strlcase stringvariable
Description: Returns a string variable as all lower case.

Command: STRUCASE
Usage: strucase stringvariable
Description: Returns a string variable as all upper case.

Command: LET
Usage: let variable=(variable or value)(+, -, *, /)(variable or value)
Description: Perfom calculations and assign values with existign variables.

Command: IF
Usage: if (variable or value)(=, <>, >=, <=, <, >)(variable or value):labelname
Description: Jump to a label if the specified condition is true.

Command: LABEL
Usage: label labelname
Description: Specify a location for GOTO and IF statements to find.

Command: GOTO
Usage: goto labelname
Description: Find and jump to the corresponding LABEL.

command OUTPUT
Usage: output <html><body>anytext</body></html>
Other Ysage: output $stringvariable
Other Usage: output *variable
Description: Output any text, string, or integer variable. The $ specifies a string variable while the * specifies integer.

Command: FORMGET
Usage: formget stringvariable
Description: Return the contents of a URL parameter into a string variable.

Command: NEWFILE
Usage: newfile filename.any
Description: Create/Overwrite a new file.

Command: LOADFILE
Usage: loadfile filename.any
Description: Open an existing file for reading.

Command: APPENDFILE
Usage: appendfile filename.any
Description: Open an existing file for appending.

Command: CLOSEFILE
Usage: closefile
Description: Close access to a file.

Command: GETSTRING
Usage: getstring stringvariable
Description: Reads a line of data from a file into a string variable.

Command: PUTSTRING
Usage: putstring stringvariable
Description: Outputs a string variable to a file.

Command: CHECKFILE
Usage: checkfile integervariable
Description: Return the status of a file to an integer variable. (1 if end of file reached, 0 if not)

Command: DATE
Usage: date *stringvariable
Description: Return the current date nto a string variable.

Command: TIME
Usage: date *stringvariable
Description: Return the current time nto a string variable.

Command: RANDOM
Usage: random variable,1,100
Other Usage: random,10,50
Description: Return a random number between the specified range. The first example returns 1-100 and the second returns 10-60.

Command: END
Usage: end
Description: End the script process.

Command: REM
Usage: rem any text or whatever
Description: Comment line.

Commands to be implemented:

STRLEN
STRFIND
STRCUT
FORMPOST
GETIP