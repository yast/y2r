Known Bugs
==========

Intention of this document is to document already known bugs and how to work around it.

Escaped Characters
------------------
Problem is that yast2-core in parser already expand some escaped characters which cause wrong translation of it. Characters that have problem are
```
"\a", # alert
"\b", # backspace
"\e", # escape
"\f", # FF
"\r", # CR
"\v", # vertical tab
```

Workaround is to grep ycp sources for all occurences of these rare characters and manually fix it after translation.

Conversion of Include Files
---------------------------
Include files conversion has hard-coded path to include file. If it is not used then generated include file is not correct and will not work correctly.

Workaround is to always run y2r in module root path and specify whole include file name like `src/include/my/include.ycp`
