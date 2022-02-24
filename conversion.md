### Collection of functions for converting numbers of bases 2 to 16 among each other
#### Note
With the exception of base10 values, all other values are used as strings.  
Conversion to base2 and to base16 can commit an optional length parameter to insert leading zeros.  
The length is limited for 32bit numbers (base2: 32, base16: 16).  
Base2 values also recognised, if they committed as number (without leading zeros) with max length of 19 characters.
#### Syntax
##### Load module
	module = require "ModuleName"		
	
```lua
-- example:
conv = require "conversion"
```
##### Function call
	module:FunctionName(param..)	or
	module.FunctionName(module, param..)

```lua
-- example:
local result = conv:dec2bin(123)	-- or
local result = conv.dec2bin(conv, 123)
```
#### Function List
- main
	- conversion.base2base
- from binary
	- conversion.bin2oct
	- conversion.bin2dec
	- conversion.bin2duodec
	- conversion.bin2hex
- from octal
	- conversion.oct2bin
	- conversion.oct2dec
	- conversion.oct2duodec
	- conversion.oct2hex
- from decimal
	- conversion.dec2bin
	- conversion.dec2oct
	- conversion.dec2duodec
	- conversion.dec2hex
- from duodecimal
	- conversion.duodec2bin
	- conversion.duodec2oct
	- conversion.duodec2dec
	- conversion.duodec2hex
- from hexadecimal
	- conversion.hex2bin
	- conversion.hex2oct
	- conversion.hex2dec
	- conversion.hex2duodec
	