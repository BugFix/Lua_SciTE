-- TIME_STAMP   2021-04-14 17:56:37   v 0.10

--[[  Toggle Block Comments   ©BugFix ( autoit[at]bug-fix.info )

	For toggeling its required to detect, what the user want to do.

	Rules for detection:
	    UNSET COMMENT BLOCK
		- NEW:
		  NONE SELECTION IS REQUIRED!
		  There must exist an comment block near the cursor position (cursor inside the .start line or above).
		  The script detects automatically the "comment.box.start" and the corresponding "comment.box.end" (also if nested) and works until this line.

		SET COMMENT BLOCK
		- Some text must selected (at minimum one character)
		- Starts and/or ends the selection inside of a line, the selection will expanded to full line.
		- Ends the selection in a line with text, but at line start position so will this line ignored!
		- Leading and trailing empty lines in selection will ignored!

	Properties:
		It is recommended to write all block comment settings into SciTEUser.properties.
		The setting "comment.box.end.au3" from "au3.properties" is wrong and must be corrected.

		comment.box.start.au3=#cs
		#~ If you want characters or tab in each line of comment block (middle lines), define it here.
		#~ If TAB should used as box.middle, set it so: comment.box.middle.au3=@Tab
		#~ "@Tab" is replaced by a tabulator by the script.
		comment.box.middle.au3=
		comment.box.end.au3=#ce

		additional [optional] property:
		#~ message for comment block set or unset - output/none (1/0), default=0 (none output)
		#~ e.g.: "++ COMMENT BLOCK - UNSET [line 103-106]"
		#~ SET  : current line numbers of commented text including the lines with .start .end
		#~ UNSET: current line number(s) of text that was commented
		comment.box.output=0

	Example with AutoIt comment:
	  "SelectionStart" = [S]   "SelectionEnd" = [E]
	----------------------------------------------------------------------
	selection:						or								or
		1 [S]line with some text[E]		1 [S]							1 lin[S]e with some text[E]
										2 line with some text[E]
	or								or								or
		1 [S]							1 [S]line with some text		1 [S]
		2 line with some text			2 [E]							2 line with so[E]me text
		3 [E]
	or                            	or
	    1 [S]							1 [S]
		... empty lines					2	line with some text
		5								... empty lines
		6 line with some text			6
		7 [E]							7 [E]

					result for all:
						1 #cs
						2 line with some text
						3 #ce
	----------------------------------------------------------------------

]]

--[[ History
	v 0.10
	- fixed: If last selected line is also last line in editor, the comment.end was set in this line and so was this line deleted if has toggled.
	v 0.9
	- removed: comment.box.ignore.empty.before/after - was not very usefull
	- added:   detection (and excluding) of leading and/or trailing empty lines in selection
	v 0.8
	- fixed: Problem with selection starts/ends in the middle of a line or ends at the first position of the line with text
	v 0.7
	- added: Automatic detection for comment blocks, NO SELECTION REQUIRED to unset a comment block
	- added: properties
	    comment.box.ignore.empty.before: if first selected line is empty -- don't include in comment block
	    comment.box.ignore.empty.after:  if last selected line is empty  -- don't include in comment block
	    comment.box.output:              if "1" -- write result of proceeding to console, default is "0"
	- changed: minimum required selection to start block comment: 1 character
	v 0.6
	- fixed: if selection for uncommenting is wrong, leading/trailing empty line will removed
	v 0.5
	- fixed: the trailing line break from comment.end while uncommenting will not removed
	v 0.4
	- added: detection for uncommenting if selection is wrong (starts/ends in empty line)
	v 0.3
	- project new designed (object syntax)
	v 0.2
	- fixed: missed adding of middle marker in first line

]]


local BlockComment = {
	-- variables
	ext,          -- file extension
	boxStart,     -- property: comment.box.start
	boxMiddle,    -- property: comment.box.middle
	boxEnd,       -- property: comment.box.end
	bMiddle,      -- bool: boxMiddle is defined
	lenEOL,       -- length of line break character(s) from file in editor
	eol,          -- the end of line character(s) in this file
	msg = {},     -- store line numbers (start, end) for proceeding message
	selS = {},    -- selection start
	selE = {},    -- selection end
	-- selection table fields:
	--   .pos,    -- selection position
	--   .line,   -- selection line number

	newText,	  -- the text that replaces the selection

	-- initialize variables
	Init = function(self)
		self.ext = props["FileExt"]
		self.boxStart        = props["comment.box.start."..self.ext]
		self.boxMiddle       = props["comment.box.middle."..self.ext]
		self.bMiddle         = not (self.boxMiddle == "")
		self.boxEnd          = props["comment.box.end."..self.ext]
		if self.boxMiddle == "@Tab" then self.boxMiddle = "\t" end
		self.selS = self:SelLineData(editor.SelectionStart)
		self.selE = self:SelLineData(editor.SelectionEnd)
		self.lenEOL = self:GetEOL()
		self.eol = "\n"
		if self.lenEOL == 2 then self.eol = "\r\n" end
		self.newText   = ""
	end,

	-- stores #pos and #line from selection position
	SelLineData = function(self, _selPos) -- _selPos: editor.SelectionStart or editor.SelectionEnd
		local t = {}
		t.pos  = _selPos
		t.line = editor:LineFromPosition(t.pos)
		return t
	end,

	-- returns position from start and end (behind last visible char) of a line
	LineStartEndPos = function(self, _line)
		local startP = editor:PositionFromLine(_line)
		local endP = editor.LineEndPosition[_line]
		return startP, endP
	end,

	-- returns the length of EOL (default) or with "_getMode=true": LF/CRLF
	-- asking the property "eol.mode.type" is not safe, maybe not set and the global value may differ from the file in the editor
	GetEOL = function(self, _getMode)
		-- It is possible that another program makes entries (e.g.: version number) at the beginning of the file..
		-- ..with a different EOL mode, therefore the second last line (last line with line break) of the file is checked.
		local l = editor.LineCount -2
		local lenEOL
		if l < 0 then -- the eol.mode from properties will used instead (but not sure, if exists)
			local mode = props["eol.mode."..self.ext]       -- mode for file type (if declared)
			if mode == "" then mode = props["eol.mode"] end -- otherwise the global mode
			if mode == "LF" then lenEOL = 1 else lenEOL = 2 end
		else
			local textEnd = editor.LineEndPosition[l]       -- pos after last visible character
			local posLineStart = editor:PositionFromLine(l) -- first pos in line
			local textLen = textEnd - posLineStart          -- pure text length
			local len = editor:LineLength(l)                -- length of line including the line break characters
			lenEOL = len - textLen                          -- length of line line break characters
		end
		if _getMode then
			if lenEOL == 1 then return "LF" else return "CRLF" end
		else
			return lenEOL
		end
	end,

	-- detects if is/not selection
	IsSelection = function(self)
		return (self.selS.pos ~= self.selE.pos)
	end,

	-- mask magic characters
	MaskMagic = function(self, _s)
		if _s == nil then return "" end
		return _s:gsub('([%(%)%.%%%+%-%*%?%[%^%$])', '%%%1')
	end,

	-- checks if line is empty (has only a line break)
	LineIsEmpty = function(self, _line) -- _line: number or text from "editor:GetLine"
		if type(_line) == "string" then return (_line:len() == self.lenEOL) end
		if _line == nil then return true end
		local len = editor:LineLength(_line)
		return (len <= self.lenEOL)
	end,

	-- checks if line starts with/has box.start
	-- detects it also, if nested and middle marker(s) before the start marker
	LineHasStart = function(self, _line)
		if self:LineIsEmpty(_line) then return false end
		if type(_line) == "number" then _line = editor:GetLine(_line) end
		local pattern
		if self.boxMiddle == '' then pattern = self:MaskMagic(self.boxStart)
		else pattern = self:MaskMagic(self.boxMiddle)..'*'..self:MaskMagic(self.boxStart) end
		local n = _line:find(pattern)
		return (n ~= nil)
	end,

	-- checks if line starts with/has box.end
	-- detects it also if nested, and middle marker(s) before the end marker
	LineHasEnd = function(self, _line)
		if self:LineIsEmpty(_line) then return false end
		if type(_line) == "number" then _line = editor:GetLine(_line) end
		local pattern
		if self.boxMiddle == '' then pattern = self:MaskMagic(self.boxEnd)
		else pattern = self:MaskMagic(self.boxMiddle)..'*'..self:MaskMagic(self.boxEnd) end
		local n = _line:find(pattern)
		return (n ~= nil)
	end,

	-- remove middle marker/add line
	UncommentMiddleLine = function(self, _bMiddle, _text)
		if _bMiddle then self.newText = self.newText.._text:gsub("^("..self:MaskMagic(self.boxMiddle)..")", "")
		else self.newText = self.newText.._text end
	end,

	-- checks if passed line is last line in editor AND selection ends not at line start position
	IsLastLine = function(self, _line)
		return (editor.LineCount == (_line + 1)) and (editor:PositionFromLine(_line) ~= self.selE.pos)
	end,

	-- the ternary operator
	ternary = function(self, _condition, _ifTrue, _ifFalse)
		if _condition == true then return _ifTrue
		else return _ifFalse end
	end,

	-- creates the text to toggle and replace the selection with it
	Toggle = function(self)
		self:Init()
		local firstVisibleLine = editor.FirstVisibleLine
		local countNesting, bStart, nStart, text, nLine, replS, replE = 0, false, -1
		local lineStart, lineEnd, bLastLine
		local sStart, sEnd = self:MaskMagic(self.boxStart), self:MaskMagic(self.boxEnd)
		local sMiddle = self:MaskMagic(self.boxMiddle)
		local bUsedMiddle = false  -- (for uncommenting) check if first line after comment.start, starts with comment.box.middle marker
		local insertMiddle = ""
		if self.bMiddle then insertMiddle = self.boxMiddle end

		-- error check
		if self.boxStart == "" or self.boxEnd == "" then
		return print("! ERROR - The comment.box properties for *."..self.ext.." files are missing or incomplete.") end

		-- check for set comment block
		if (not self:IsSelection()) then                          -- none selection - means: Unset CommentBlock
			-- start unset
			self.msg.action = 'COMMENT BLOCK - UNSET'
			nLine = self.selS.line
			while nLine < editor.LineCount do
				text = editor:GetLine(nLine)     -- line with eol

				if (not bStart) and self:LineHasStart(text) then  -- first line with comment.box.start
					bStart = true
					self.msg.starts = nLine
					nStart = nLine
					replS = editor:PositionFromLine(nLine) -- save the start position for replacing
				end

				if nLine == nStart +1 then       -- first line after comment.box.start
					if self.bMiddle then -- check if comment.box.middle is used, if defined
						local n = text:find(sMiddle)
						if n == 1 then bUsedMiddle = true end  -- true, if starts with it
					end
				end

				if self:LineIsEmpty(text) then   -- do nothing with empty lines, add them only if start was detected before
					if bStart then self.newText = self.newText..text end  -- text is only a line break
				else
					if self:LineHasEnd(text) then       -- the box.end or a nested box.end
						countNesting = countNesting -1  -- decrease nesting counter
						if countNesting == 0 then       -- it's the corresponding end position
							self.newText = self.newText:sub(1, -(self.lenEOL +1))  -- ignore text from this line and delete line break from stored line before
							replE = editor.LineEndPosition[nLine]                  -- save the end position (w.o. line break) for replacing
							self.msg.ends = nLine -2
							break                       -- leave the loop
						else  -- will be treated as middle line (it's a nested comment.box.end)
							self:UncommentMiddleLine(bUsedMiddle, text)
						end
					elseif self:LineHasStart(text) then
						countNesting = countNesting +1 -- increase nesting counter
 						-- countNesting == 1              it's the real start of block comment --> ignore this line
						if countNesting > 1 then self:UncommentMiddleLine(bUsedMiddle, text) end -- treat it like a middle line
					else  -- all other cases are middle lines but if not start was detected - ignore this line
						if bStart then self:UncommentMiddleLine(bUsedMiddle, text) end
					end
				end
				nLine = nLine +1
			end
			if (not bStart) then
				return print("! ERROR - None comment block starts near the cursor.")  -- text near Cursor isn't comment block start marker
			end
		else
			-- set comment block
			self.msg.action = 'COMMENT BLOCK - SET'
			if self.selS.line == self.selE.line then                   -- selection is in one line
				text = editor:GetLine(self.selS.line)
				lineStart = editor:PositionFromLine(self.selS.line)
				lineEnd = editor.LineEndPosition[self.selS.line] + self.lenEOL
				editor:SetSel(lineStart, lineEnd)                      -- select all text in line
				bLastLine = self:IsLastLine(self.selE.line)
				if bLastLine then self.boxEnd = self.eol..self.boxEnd end
				self.newText = self.boxStart..self.eol..insertMiddle..text..self.boxEnd..self:ternary(bLastLine, '', self.eol)
				self.msg.starts = self.selS.line
				self.msg.ends = self.selS.line +2
			else
				-- as 1.: find the last line with text in selection, possibly blank lines are selected at the end
				local iLineLastText = -1
				for i = self.selE.line, self.selS.line, -1 do
					if (not self:LineIsEmpty(i)) then
						iLineLastText = i
						break
					end
				end
				-- none text selected
				if iLineLastText == -1 then return print("! ERROR - Only empty lines selected.") end
				if iLineLastText ~= self.selE.line then
					self.selE.line = iLineLastText
					self.selE.pos = editor.LineEndPosition[self.selE.line]
				end
				bLastLine = self:IsLastLine(self.selE.line)
				if bLastLine then self.boxEnd = self.eol..self.boxEnd end

				for i = self.selS.line, self.selE.line do
					text = editor:GetLine(i)
					if i == self.selS.line then                        -- selection start line
						if (not self:LineIsEmpty(text)) then
							lineStart = editor:PositionFromLine(self.selS.line)
							if lineStart ~= self.selS.pos then
								self.selS.pos = lineStart
								editor:SetSel(self.selS.pos, self.selE.pos)
							end
							self.newText = self.boxStart..self.eol..insertMiddle..text
							self.msg.starts = i
						else
							-- start line is empty - do nothing
						end
					elseif i == self.selE.line then                    -- selection end line
						if self.newText == "" then                     -- the last line is the 1st line with text in selection
							self.newText = self.boxStart..self.eol
							self.selS.pos = editor:PositionFromLine(i)
							self.msg.starts = i
						end
						lineStart = editor:PositionFromLine(i)
						lineEnd = editor.LineEndPosition[i]
						if lineStart == self.selE.pos then                      -- selection ends at line start position
							self.newText = self.newText..self.boxEnd..self.eol  -- ignore this line
							self.msg.ends = i +2
							break
						end
						if lineEnd == self.selE.pos then                        -- selection ends behind last visible char
							self.newText = self.newText..insertMiddle..text..self.boxEnd  -- without EOL
							self.msg.ends = i +2
							break
						end
						if lineEnd > self.selE.pos then                         -- selection ends inside the line, line will used
							self.selE.pos = lineEnd + self.lenEOL               -- set selE.pos to line end for correct replacing
						end
						self.newText = self.newText..insertMiddle..text..self.boxEnd..self:ternary(bLastLine, '', self.eol)
						self.msg.ends = i +2
					else                                                        -- middle lines
						if (not self:LineIsEmpty(i)) and self.newText == "" then -- may be only empty lines in selection before
							self.newText = self.boxStart..self.eol
							self.selS.pos = editor:PositionFromLine(i)
							self.msg.starts = i
						end
						if self.newText ~= "" then self.newText = self.newText..insertMiddle..text end
					end
				end
				editor:SetSel(self.selS.pos, self.selE.pos)
			end
		end

		-- replace the selection with the new toggled text
		if bStart then editor:SetSel(replS, replE) end  -- for uncommenting exists none selection - do it here
		editor:ReplaceSel(self.newText)                 -- replace the next
		editor:SetSel(self.selS.pos,self.selS.pos)      -- set the cursor to start position
		editor.FirstVisibleLine = firstVisibleLine      -- make the first visible line visible again
		if props["comment.box.output"] == "1" then
			print(string.format('++ %s [line %d-%d]', self.msg.action, self.msg.starts +1, self.msg.ends +1))
		end
	end
}

BlockComment:Toggle()
