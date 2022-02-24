### About
Useful extension if spaces are used instead of tabs in SciTE4AutoIt.
### Current
v 0.2
### Requires
[CommonTools.lua](CommonTools.lua)
### Usage
- Load the file with "SciTEStartup.lua"
- New entry in SciTEUser.properties:<br />
	<span style='font-family:"Courier New"'>use.tabs.$(file.pattern.EXT)=0</span>&nbsp;&nbsp;or&nbsp;&nbsp;<span style='font-family:"Courier New"'>use.tabs.EXT=0</span> .<br />Don't use&nbsp;&nbsp;<span style='font-family:"Courier New"'>use.tabs=0</span>&nbsp;&nbsp;!<br />
    If the property is set to&nbsp;&nbsp;<span style='font-family:"Courier New"'>>0</span>&nbsp;&nbsp;, the script will not respond.
    For use with values other than the default, see remarks.
### Functions
<table style='font-family:"Courier New"'>
<tr><td><b>Key Sequence</b></td><td><b>Single Caret</b></td><td><b>Rectangular Selection</b></td></tr>
<tr><td>Shift+Backspace</td><td>Delete chars from caret until previous tab position</td><td>The same in each line of selection. The rectangular selection remains after the operation.</td></tr>
<tr><td>Shift+Del</td><td>Delete chars from caret until next tab position</td><td>The same in each line of selection. The rectangular selection remains after the operation.</td></tr>
<tr><td>Alt+Arrow_Left</td><td>Skip to previous Tab position                          </td><td>--</td></tr>
<tr><td>Alt+Arrow_Right</td><td>Skip to next Tab position</td><td>--</td></tr>
</table>

### Remarks
The default Tab size is 4. You can change this setting specified for your file types. The following properties need changes:

	tab.size.$(file.pattern.EXT)=VALUE
	indent.size.$(file.patterns.EXT)=VALUE
The (not file type specific) values:

	tab.indents=1
	backspace.unindents=1
should also set.<br />
If&nbsp;&nbsp;<span style='font-family:"Courier New"'>tab.indents</span>&nbsp;&nbsp;is set then pressing tab within indentation whitespace indents by indent.size rather than inserting a tab character.
If&nbsp;&nbsp;<span style='font-family:"Courier New"'>backspace.unindents</span>&nbsp;&nbsp;then pressing backspace within indentation whitespace unindents by indent.size rather than deleting the character before the caret.