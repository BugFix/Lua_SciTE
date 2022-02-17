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
#### Content
- SYSTEM
    - **FileExists** Checks if a file exists
    - **FolderCreate** Creates a folder (if not exists)
    - **FolderExists** Checks if a folder exists
    - **GetCurrentDir** Returns the script directory
    - **GetFilesRecursive** Returns a table with all recursive files (full path name) from given root. You can use filter for file type and attributes.
    - **GetFolderRecursive** Returns a table with all recursive sub folders (full path name) from given root. You can use filter for attributes.
    - **OSNow** Returns a table with date & time fields from now
    - **OSDate** Returns a string with the current date as "YYYY-MM-DD"
    - **OSTime** Returns a string with the current time as "hh:mm:ss"
    - **require_protected** Load library protected

- EDITOR
    - **EditorCodingCookieLine** Checks the current buffer for coding cookie. Returns the line number from this or nil.
    - **EditorDeleteLine** Deletes the passed line number from editor. Returns line content if success.
    - **EditorGetCommentChar** Returns the character(s) for a line comment of the passed file type (or default: from current buffer), if defined.
    - **EditorGetEOL** Returns length, mode of EOL and the EOL character(s) in current SciTE buffer
    - **EditorMoveLine** Moves a line in editor up/down by param count (negative=up/positive=down).
    - **EditorTabColPosInLine** Returns column and position of previous/next TAB in passed line

- MISC
    - **PropExt** Asks for propertie specified by filter.extension or extension
    - **EscapeMagic** Escapes all magic characters in a string:  ( ) . % + - * ? [ ^ $
    - **InSensePattern** Creates an insensitive pattern string ("Hallo" --> "[Hh][Aa][Ll][Ll][Oo]"). Ascii chars only!
    - **Power2And** Checks if a passed uint value contains a given power of 2.
    - **Split** Splits a string by the passed delimiter into a table (each character as one element only with ASCII characters)
    - **StringUTF8Len** Get the number of characters (not the number of bytes, like string.len) of a string with UTF8 characters
    - **StringUTF8Split** Splits a string by the passed delimiter into a table (each character as one element with UTF8 characters too)
    - **StripSpaceChar** Strip space characters (%s) from a string.
    - **Ternary** The ternary operator as function (condition, if_true, if_false)
    - **Trim** Trim a count of chars from a strings left or right side
    - **UrlEncode** Returns the given string encoded for use in URL

- AU3 - SPECIFIC
    - **GetIncludePathes** Returns a table with locations of AU3 - include files in the system