### Current
v 0.6
### Requires
[conversion.lua](conversion.lua)
### Syntax
#### Load module
	module = require "ModuleName"
```lua
local ct = require "CommonTools"
```
#### Function call
	module:FunctionName()
```lua
local tFRec = ct:GetFilesRecursive(ct:GetCurrentDir(), "lua", "hs")
```
### Content

<table style='font-family:"Courier New"'>
<tr><td><b><span style='color:darkblue'>SYSTEM</span></b></td></tr>
<tr><td>FileExists</td><td>Checks if a file exists</td></tr>
<tr><td>FolderCreate</td><td>Creates a folder (if not exists)</td></tr>
<tr><td>FolderExists</td><td>Checks if a folder exists</td></tr>
<tr><td>GetCurrentDir</td><td>Returns the script directory</td></tr>
<tr><td>GetFilesRecursive</td><td>Returns a table with all recursive files (full path name) from given root. You can use filter for file type and attributes.</td></tr>
<tr><td>GetFolderRecursive</td><td>Returns a table with all recursive sub folders (full path name) from given root. You can use filter for attributes.</td></tr>
<tr><td>OSNow</td><td>Returns a table with date & time fields from now</td></tr>
<tr><td>OSDate</td><td>Returns a string with the current date as "YYYY-MM-DD"</td></tr>
<tr><td>OSTime</td><td>Returns a string with the current time as "hh:mm:ss"</td></tr>
<tr><td>require_protected</td><td>Load library protected</td></tr>

<tr><td><b><span style='color:darkblue'>EDITOR</span></b></td></tr>
<tr><td>EditorCodingCookieLine</td><td>Checks the current buffer for coding cookie. Returns the line number from this or nil.</td></tr>
<tr><td>EditorDeleteLine</td><td>Deletes the passed line number from editor. Returns line content if success.</td></tr>
<tr><td>EditorGetCommentChar</td><td>Returns the character(s) for a line comment of the passed file type (or default: from current buffer), if defined.</td></tr>
<tr><td>EditorGetEOL</td><td>Returns length, mode of EOL and the EOL character(s) in current SciTE buffer</td></tr>
<tr><td>EditorMoveLine</td><td>Moves a line in editor up/down by param count (negative=up/positive=down).</td></tr>
<tr><td>EditorTabColPosInLine</td><td>Returns column and position of previous/next TAB in passed line</td></tr>

<tr><td><b><span style='color:darkblue'>MISC</span></b></td></tr>
<tr><td>PropExt</td><td>Asks for property specified by filter.extension or extension</td></tr>
<tr><td>EscapeMagic</td><td>Escapes all magic characters in a string:  ( ) . % + - * ? [ ^ $</td></tr>
<tr><td>InSensePattern</td><td>Creates an insensitive pattern string ("Hallo" --> "[Hh][Aa][Ll][Ll][Oo]"). Ascii chars only!</td></tr>
<tr><td>Power2And</td><td>Checks if a passed uint value contains a given power of 2.</td></tr>
<tr><td>Split</td><td>Splits a string by the passed delimiter into a table (each character as one element only with ASCII characters)</td></tr>
<tr><td>StringUTF8Len</td><td>Get the number of characters (not the number of bytes, like string.len) of a string with UTF8 characters</td></tr>
<tr><td>StringUTF8Split</td><td>Splits a string by the passed delimiter into a table (each character as one element with UTF8 characters too)</td></tr>
<tr><td>StripSpaceChar</td><td>Strip space characters (%s) from a string.</td></tr>
<tr><td>Ternary</td><td>The ternary operator as function (condition, if_true, if_false)</td></tr>
<tr><td>Trim</td><td>Trim a count of chars from a strings left or right side</td></tr>
<tr><td>UrlEncode</td><td>Returns the given string encoded for use in URL</td></tr>

<tr><td><b><span style='color:darkblue'>AU3 - SPECIFIC</span></b></td></tr>
<tr><td>GetIncludePathes</td><td>Returns a table with locations of AU3 - include files in the system</td></tr>
</table>


