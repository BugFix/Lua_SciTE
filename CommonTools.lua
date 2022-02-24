-- TIME_STAMP   2022-02-24 10:57:39   v 0.7
-- coding:utf-8

--[[
USAGE
    load module:	module = require "ModuleName"
    function call:	module:FunctionName()

REQUIRES    module "conversion.lua"     ( https://github.com/BugFix/Conversion/blob/master/conversion.lua )
                                        ( https://autoit.de/thread/86555-konvertieren-zwischen-zahlensystemen-in-lua/?postID=695947#post695947 )

    Content
SYSTEM
    FileExists                          Checks if a file exists
    FolderCreate                        Creates a folder (if not exists)
    FolderExists                        Checks if a folder exists
    GetCurrentDir                       Returns the script directory
    GetFilesRecursive                   Returns a table with all recursive files (full path name) from given root. You can use filter for file type and attributes.
    GetFolderRecursive                  Returns a table with all recursive sub folders (full path name) from given root. You can use filter for attributes.
    OSNow                               Returns a table with date & time fields from now
    OSDate                              Returns a string with the current date as "YYYY-MM-DD"
    OSTime                              Returns a string with the current time as "hh:mm:ss"
    require_protected                   Load library protected

EDITOR
    EditorCodingCookieLine              Checks the current buffer for coding cookie. Returns the line number from this or nil.
    EditorDeleteLine                    Deletes the passed line number from editor. Returns line content if success.
    EditorGetCommentChar                Returns the character(s) for a line comment of the passed file type (or default: from current buffer), if defined.
    EditorGetEOL                        Returns length, mode of EOL and the EOL character(s) in current SciTE buffer
    EditorMoveLine                      Moves a line in editor up/down by param count (negative=up/positive=down).
    EditorTabColPosInLine               Returns column and position of previous/next TAB in passed line

MISC
    ASCIIcompare                        Comparison of two ASCII strings, optionally case-insensitive (default: case-sensitive). Return of both strings in sorted order.
    EscapeMagic                         Escapes all magic characters in a string:  ( ) . % + - * ? [ ^ $
    InSensePattern                      Creates an insensitive pattern string ("Hallo" --> "[Hh][Aa][Ll][Ll][Oo]"). Ascii chars only!
    Power2And                           Checks if a passed uint value contains a given power of 2.
    PropExt                             Asks for propertie specified by filter.extension or extension
    Split                               Splits a string by the passed delimiter into a table (each character as one element only with ASCII characters)
    StringUTF8Len                       Get the number of characters (not the number of bytes, like string.len) of a string with UTF8 characters
    StringUTF8Split                     Splits a string by the passed delimiter into a table (each character as one element with UTF8 characters too)
    StripSpaceChar                      Strip space characters (%s) from a string.
    Ternary                             The ternary operator as function (condition, if_true, if_false)
    Trim                                Trim a count of chars from a strings left or right side
    UrlEncode                           Returns the given string encoded for use in URL

AU3 - SPECIFIC
    GetIncludePathes                    Returns a table with locations of AU3 - include files in the system
]]

-- v 0.7    added:      ASCIIcompare()
-- v 0.6    changed:    Detection of tab size with language specific "tab.size.filter_ext/ext" instead of global "tabsize"
--          added:      PropExt()
-- v 0.5    added:      Power2And()
--          changed:    StripSpaceChar(), now using Power2And() for flag check
-- v 0.4    added:      EditorTabColPosInLine()
--          added:      StripSpaceChar()
--          changed:    Split(), additional parameter to strip possible leading and trailing space characters from splitted items


do
    local conv = require "conversion"
    local CommonTools = {}

    ------------------------------------------------------------------------------------ SYSTEM ----
    --[[
        Checks if file exists (true / false)
        _file       The file path to check
        Returns:    true / false
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.FileExists = function(self, _file)
        if _file == nil then return false end
        local shell = self:require_protected('shell')
        if shell then
            return shell.fileexists(_file)
        else
            local fh = io.open(_file)
            if fh ~= nil then fh:close() return true
            else return false end
        end
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Creates folder if not exists
        Returns:	true, 'EXISTS'      - folder exists
                    true, 'SUCCESSFULL' - creation was successfull
                    false, 'FAILED'     - creation has failed
                    false, 'NO_PARAM'   - none folder was passed
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.FolderCreate = function(self, _folder)
        if _folder == nil then return false, 'NO_PARAM' end
        if self:FolderExists(_folder) then return true, 'EXISTS' end
        local shell, ret = self:require_protected('shell')
        if shell then
            ret = shell.exec('CMD /C MD "' .. _folder .. '"', nil, true, true)
        else
            ret = os.execute('CMD /C MD "' .. _folder .. '"')
        end
        if ret == 0 then return true, 'SUCCESSFULL' else return false, 'FAILED' end
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Checks if folder exists (true / false)
        _folder     The folder path to check
        Returns:    true / false
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.FolderExists = function(self, _folder)
        if _folder == nil then return false end
        local shell = self:require_protected('shell')
        if shell then
            return shell.fileexists(_folder)
        else
            local file = _folder..'/CommonTools_Folder.Exists'
            local fh = io.open(file, 'w+')  -- try to write to passed folder
            if fh ~= nil then fh:close() os.remove(file) return true
            else return false end
        end
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns the script directory
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.GetCurrentDir = function(self)
        local sFullPathCurrent = debug.getinfo(1).short_src
        local pos = sFullPathCurrent:find('\\[^\\]*$')
        if pos == nil then pos = sFullPathCurrent:find('/[^/]*$') end
        return sFullPathCurrent:sub(1, pos-1)
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns a table with all recursive files (full path name) from given root
        _rootpath       The directory to start, if nil: the script dir will used
        _filetype       Filter by parameter "_filetype", i.e. "lua" or "lua dll" or "lua dll any_other"
                        if nil: gets all files
        _exclude_attrib	Files can excluded by their attrib, i.e. "hs" or "rs"
                        Possible values:
                        H-hidden, S-system, L-reparse points, R-read only, A-archive, I-not content indexed
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.GetFilesRecursive = function(self, _rootpath, _filetype, _exclude_attrib)
        local tFiles, shell, pfile, pos, ext = {}, self:require_protected('shell')
        _rootpath = _rootpath or self:GetCurrentDir()
        _filetype = _filetype or '*'
        _exclude_attrib = _exclude_attrib or ''
        _exclude_attrib = _exclude_attrib:gsub('(.)', '-%1')

        -- write file types into table
        local tFiletype = {}
        if _filetype ~= '*' then
            for v in string.gmatch(_filetype, "%S+") do
                table.insert(tFiletype, v)
            end
        end

        -- function to insert file pathes in output table by filtering
        local function insert(_file)
            if #tFiletype == 0 then
                table.insert(tFiles, _file)
            else
                pos = _file:find('\.[^\.]+$')
                ext = _file:sub(pos+1)
                for i,v in ipairs(tFiletype) do
                    if v == ext then table.insert(tFiles, _file) end
                end
            end
        end

        -- get all files recursively from _rootpath and filter it
        if shell then -- use shell library, if exists
            _, result = shell.exec('CMD /c dir "'.._rootpath..'" /b /o:N /s /a-d'.._exclude_attrib, nil, true, true)
            local tResult = {}
            for v in result:gmatch("[^\n]+") do
                table.insert(tResult, (v:gsub('\r', ''):gsub('\n', '')))
            end
            -- check if files found
            if #tResult == 1 then if not shell.fileexists(tResult[1]) then return {} end end
            for i,file in ipairs(tResult) do
                insert(file)
            end
        else
            local pfile = io.popen('dir "'.._rootpath..'" /b /o:N /s /a-d'.._exclude_attrib)
            local firstfile = true
            for file in pfile:lines() do
                if firstfile then
                    if not self:FileExists(file) then break
                    else firstfile = false
                    end
                end
                insert(file)
            end
            pfile:close()
        end

        return tFiles
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns a table with all recursive sub folders (full path name) from given root
        _rootpath       The directory to start, if nil: the script dir will used
        _exclude_attrib Folder can excluded by their attrib, i.e. "hs" or "rs"
                        Possible values:
                        H-hidden, S-system, L-reparse points, R-read only, A-archive, I-not content indexed
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.GetFolderRecursive = function(self, _rootpath, _exclude_attrib)
        local tsub, shell = {}, self:require_protected('shell')
        _rootpath = _rootpath or self:GetCurrentDir()
        _exclude_attrib = _exclude_attrib or ''
        _exclude_attrib = _exclude_attrib:gsub('(.)', '-%1')

        if shell then
            _, result = shell.exec('CMD /c dir "'.._rootpath..'" /b /o:N /s /a:d'.._exclude_attrib, nil, true, true)
            for v in result:gmatch("[^\n]+") do
                table.insert(tsub, (v:gsub('\r', ''):gsub('\n', '')))
            end
        else
            local pfile = io.popen('dir "'.._rootpath..'" /b /o:N /s /a:d'.._exclude_attrib)
            for folder in pfile:lines() do
                table.insert(tsub, folder)
            end
            pfile:close()
        end

        return tsub
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns table: .year .month .day .hour .min .sec .wday(1=sunday) .yday .isdst(daylight saving flag)
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.OSNow = function(self) return os.date("*t", os.time()) end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns date as "YYYY-MM-DD"
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.OSDate = function(self)
        local tNow = self:OSNow()
        return ('%s-%02s-%02s'):format(tNow.year, tNow.month, tNow.day)
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns time as "hh:mm:ss"
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.OSTime = function(self)
        local tNow = self:OSNow()
        return ('%02s:%02s:%02s'):format(tNow.hour, tNow.min, tNow.sec)
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Load library protected
        Try to load a dll library. If it fails returns 'nil', otherwise the lib handler.
        NOTE: Some libraries are written wrong and can't accessed by the returned handler. In this
            case use the called name instead.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.require_protected = function(self, _lib)
        local loaded_lib
        if pcall(function() loaded_lib = require(_lib)  end) then return loaded_lib
        else return nil end
    end
    ------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------- /SYSTEM ----


    ------------------------------------------------------------------------------------ EDITOR ----
    --[[
        Checks the current buffer for coding cookie. Returns the line number from this or nil.
        Optional is a parameter for the maximum line number up to which to search (default is the first two lines).
        It may be that the cookie line has been moved by inserting other text before.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.EditorCodingCookieLine = function(self, _maxLine)
        local cookieLine = nil
        _maxLine = _maxLine or 1  -- default search in the 1st two lines
        if _maxLine > editor.LineCount -1 then _maxLine = editor.LineCount -1 end
        for i=0, _maxLine do
            lineTxt = editor:GetLine(i)
            if lineTxt == nil then break end
--             if lineTxt:find("coding[:=]%s-['\"]-utf%-8") then
            if lineTxt:find("coding[:=]%s-['\"]-") then
                cookieLine = i break
            end
        end
        return cookieLine
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Deletes the passed line number from editor. Returns line content if success.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.EditorDeleteLine = function(self, _l)
        local line, len = editor:GetLine(_l)
        if line == nil then return false end
        local posLineStart = editor:PositionFromLine(_l)
        editor:DeleteRange(posLineStart, len)
        return line
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns the character(s) for a line comment of the passed file type
        (or default: from current buffer), if defined.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.EditorGetCommentChar = function(self, _ext)
        _ext = _ext or props['FileExt']
        local char = props['comment.block.'.._ext]
        if char == '' then -- if not defined by extension, try the lexer
            local lex = props['lexer.$(file.patterns.'.._ext..')']
            char = props['comment.block.'..lex]
        end
        return char
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns the length of EOL character(s), the mode "LF / CRLF" and the EOL character(s) from
        file in the current SciTE buffer.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.EditorGetEOL = function(self)
        -- It is possible that another program makes entries (e.g.: version number) at the beginning of the file..
        -- ..with a different EOL mode, therefore the second last line (last line with line break) of the file is checked.
        local l = editor.LineCount -2
        local mode, eol, lenEOL = "CRLF", "\r\n"            -- "\r" as single break exists only for Mac
        if l < 0 then -- the eol.mode from properties will used instead (but not sure, if exists)
            mode = props["eol.mode."..props['FileExt']]    		   	-- mode for file type (if declared)
            if mode == "" then mode = props["eol.mode"] end -- otherwise the global mode
            if mode == "LF" then lenEOL = 1 eol = "\n" else lenEOL = 2 end
        else
            local textEnd = editor.LineEndPosition[l]       -- pos after last visible character
            local posLineStart = editor:PositionFromLine(l) -- first pos in line
            local textLen = textEnd - posLineStart          -- pure text length
            local len = editor:LineLength(l)                -- length of line including the line break characters
            lenEOL = len - textLen                          -- length of line break characters
            if lenEOL == 1 then mode = "LF" eol = "\n" end
        end
        return lenEOL, mode, eol
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Moves a line in editor up/down by param count (negative=up/positive=down).
        Returns:    success     true, #lineToMoved
                    failed      false, nil          passed #line doesn't exist
                                false, #line        passed #line is target line
        Note:       Will the count param exeeds the range of lines (before 1st / behind last)
                    1st/last line will used instead.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.EditorMoveLine = function(self, _l, _count)
        local lastLine = editor.LineCount -1
        if _l > lastLine then return false, nil end
        local line, len = editor:GetLine(_l)
        local delStart = editor:PositionFromLine(_l)
        local lineToMove = _l + (_count)
        if _count > 0 then lineToMove = lineToMove + 1 end
        if lineToMove < 0 then lineToMove = 0 end
        if lineToMove > lastLine then lineToMove = lastLine end
        if lineToMove == _l then return false, _l end
        local targetStart = editor:PositionFromLine(lineToMove)
        if _count < 0 then
            delStart = delStart + len
            -- if _l is last line, may be it has none eol -> add this
            if _l == lastLine and (not line:find('[\r\n]$')) then
                local lPrev = editor:GetLine(_l -1)
                local eol = lPrev:match('([\r\n]+)$')
                line = line..eol
            end
        end
        editor:InsertText(targetStart, line)
        editor:DeleteRange(delStart, len)
        return true, lineToMove
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns column and position of previous/next TAB in passed line
        _bPrev      true=previous tab, false/nil(default)=next tab
        _iLine      editor line number, nil(default)=current line
        _iCol       editor column (not position!) in line, nil(default)=current column
        Returns:    #column, #position
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.EditorTabColPosInLine = function(self, _bPrev, _iLine, _iCol)
        local iTabsize = self:PropExt('tab.size.', props['FileExt'])    -- 1st check for file type specific setting
        if iTabsize == '' then iTabsize = props['tabsize'] end          -- .. then check global
        iTabsize = tonumber(iTabsize)
        _iLine = _iLine or editor:LineFromPosition(editor.CurrentPos)
        local iCol, iColStart
        if _bPrev then
            iCol = _iCol or editor.Column[editor.CurrentPos]
            iColStart = 0
        else
            iCol = 0
            iColStart = _iCol or editor.Column[editor.CurrentPos]
        end
        if _bPrev then
            if iCol % iTabsize > 0 then iCol = iCol + (iTabsize - (iCol % iTabsize)) end
            if iCol >= iTabsize then iCol = iCol - iTabsize end
        else
            while iCol <= iColStart do iCol = iCol + iTabsize end
        end
        local posTab = editor:FindColumn(_iLine, iCol)
        return iCol, posTab
    end
    ------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------- /EDITOR ----


    -------------------------------------------------------------------------------------- MISC ----

    --[[
        Comparison of two ASCII strings, optionally case-insensitive (default: case-sensitive).
        Return of both strings in sorted order.
    ]]
    CommonTools.ASCIIcompare = function(self, _s1, _s2, _bSensitive)
        if _bSensitive == nil then _bSensitive = true end -- default
        local ByteSensitive = function(_i)
            local a, b = _s1:sub(_i,_i):byte(), _s2:sub(_i,_i):byte()
            if not _bSensitive then
                if a >= 65 and a <= 90 then a = a + 32 end
                if b >= 65 and b <= 90 then b = b + 32 end
            end
            return a, b
        end
        local len1, len2 = _s1:len(), _s2:len()
        local min, sShort, sLong = len1, _s1, _s2
        if len2 < len1 then
            min = len2
            sShort, sLong = sLong, sShort
        end
        for i=1, min do
            local a, b = ByteSensitive(i)
            if a < b then return _s1, _s2 end
            if a > b then return _s2, _s1 end
            if (a == b) and (i == min) then return sShort, sLong end
        end
        return _s1, _s2
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Escapes all magic characters in a string
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.EscapeMagic = function(self, _s)
        if _s == nil then return nil end
        return _s:gsub('(.)', function(_c) return _c:gsub('([%(%)%.%%%+%-%*%?%[%^%$])', '%%%1') end)
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Creates an insensitive pattern string (combination of upper and lower chars: "[aA][bB]")
        NOTE: Takes only effect with ascii chars.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.InSensePattern = function(self, _s)
        _s = _s:gsub("%a", function(_c) return string.format("[%s%s]", _c:upper(),_c:lower()) end) return _s
    end
    ------------------------------------------------------------------------------------------------


    --[[
        Checks if a passed uint value contains a given power of 2.
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.Power2And = function(self, _uint, _powerof2)
        local uint2power = function(_uint)
            local tPower2 = {}
            repeat
                table.insert(tPower2, (_uint % 2))
                _uint = math.floor(_uint/2)
            until _uint == 0
            return tPower2
        end

        local tindex, pow, temp = {}, 0
        repeat
            temp = 2^pow
            tindex[temp] = pow +1
            pow = pow +1
        until (temp == _powerof2)
        local tpow = uint2power(_uint)
        return (tpow[tindex[_powerof2]] == 1)
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Asks for property specified by
            1. PROP.$(file.patterns.EXT)    if result is: ""
            2. PROP.EXT
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.PropExt = function(self, _sProp, _sExt)
        if not _sProp:find('%.$') then _sProp = _sProp..'.' end
        if _sExt:find('^%.') then _sExt = _sExt:sub(2) end
        local val = props[_sProp..'$(file.patterns.'.._sExt..')']
        if val == '' then val = props[_sProp.._sExt] end
        return val
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Splits a string by the passed delimiter
        If _delim ~= nil AND _bTrimSpaces=true, the possible leading and trailing space characters
        of the splitted items will trimmed.
        If _delim == nil each character will be returned as an element (default) - only ASCII
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.Split = function(self, _s, _delim, _bTrimSpaces)
        local tRes, _delim = {}, self:EscapeMagic(_delim)
        if _delim == nil then
            for match in _s:gmatch("(.)") do
                table.insert(tRes, match)
            end
        else
            for match in (_s.._delim):gmatch("(.-)".._delim) do
                if match ~= '' then
                    if _bTrimSpaces then
                        table.insert(tRes, self:StripSpaceChar(match, 3))
                    else
                        table.insert(tRes, match)
                    end
                end
            end
        end
        return tRes
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Counts the characters in a string, also UTF8 (not the length of the string --> count of bytes)
        Returns: count, table for each character ([n][1]=startpos, [n][2]=endpos)
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.StringUTF8Len = function(self, _s)
        local butf8, bskip, cbyte = false, false
        local nCount, nPos, tPosLen, bin, utf8len = 0, 0, {}

        for c in _s:gmatch("(.)") do
            nPos = nPos +1
            bskip = false
            cbyte = c:byte()
            if cbyte > 128 then
                bin = conv:dec2bin(cbyte)
                if bin:sub(1,2) == '11' then  -- start byte
                    utf8len = bin:find('0') -1
                    butf8 = true
                    bskip = true
                    nCount = nCount +1
                    tPosLen[nCount] = {nPos,nPos}
                end
            end
            if bskip == false then
                if butf8 == true then
                    utf8len = utf8len -1
                    if utf8len == 1 then
                        tPosLen[nCount][2] = nPos
                        butf8 = false
                    end
                else
                    nCount = nCount +1
                    tPosLen[nCount] = {nPos,nPos}
                end
            end
        end
        return nCount, tPosLen
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Splits a string by the passed delimiter
        If _delim == nil each character will be returned as an element (default) - UTF8 too
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.StringUTF8Split = function(self, _s, _delim)
        local bytes2char = function(_tchar)
            if #_tchar == 2 then return string.char(_tchar[1], _tchar[2])
            elseif #_tchar == 3 then return string.char(_tchar[1], _tchar[2], _tchar[3])
            elseif #_tchar == 4 then return string.char(_tchar[1], _tchar[2], _tchar[3], _tchar[4])
            end
        end
        local tRes, _delim = {}, self:EscapeMagic(_delim)
        local butf8, bskip, tchar, cbyte, bin, utf8len = false, false, {}

        if _delim == nil then
            for c in _s:gmatch("(.)") do
                bskip = false
                cbyte = c:byte()
                if cbyte > 128 then
                    bin = conv:dec2bin(cbyte)
                    if bin:sub(1,2) == '11' then  -- start byte
                        utf8len = bin:find('0') -1
                        butf8 = true
                        bskip = true
                        table.insert(tchar, cbyte)
                    end
                end
                if bskip == false then
                    if butf8 == true then
                        table.insert(tchar, cbyte)
                        utf8len = utf8len -1
                        if utf8len == 1 then
                            table.insert(tRes, bytes2char(tchar))
                            tchar = {}
                            butf8 = false
                        end
                    else
                        table.insert(tRes, c)
                    end
                end
            end
        else
            for match in (_s.._delim):gmatch("(.-)".._delim) do
                if match ~= '' then table.insert(tRes, match) end
            end
        end
        return tRes
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Strip space characters (%s) from a string
        _iFlag	one or combination of:
                1 = strip leading space characters
                2 = strip trailing space characters
                4 = strip double (or more) space characters between words
                8 = strip all space characters (over-rides all other flags)
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.StripSpaceChar = function(self, _s, _iFlag)
        if _s == nil then return nil end
        if _iFlag == nil then return _s end
        local tPatt = {[1]={'^%s*',''},[2]={'%s*$',''},[4]={'(%S)%s+(%S)','%1 %2'},[8]={'%s+',''}}
        if _iFlag > 7 then return _s:gsub(tPatt[8][1],tPatt[8][2]) end  -- treats combinations with 8 as 8
        for i=0,3 do
            local j = 2^i
            if self:Power2And(_iFlag, j) then _s = _s:gsub(tPatt[j][1],tPatt[j][2]) end
        end
        return _s
    end
    ------------------------------------------------------------------------------------------------

    --[[
        The ternary operator as function
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.Ternary = function(self, _condition, _ifTrue, _ifFalse)
        if _condition == true then return _ifTrue
        else return _ifFalse end
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Trim _i chars from string _s
        Positive integer trims from left, negative from right side
        _s      String to trim
        _i      Number of chars to trim
        _bSpace  "true" deletes after trimming existing space chars on trimming side
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.Trim = function(self, _s, _i, _bSpace)
        local iLen, tPatt, iPatt = _s:len(), {'^%s*', '%s*$'}, 1   -- {leftPatt,rightPatt}
        local sTrim
        if _i == nil then _i = 1 end
        if _i >= iLen then return '' end
        if _i == 0 then return _s
        elseif _i < 0 then sTrim = _s:sub(1, iLen + _i) iPatt = 2  -- trim from right
        else sTrim = _s:sub(_i + 1, -1) end                        -- trim from left
        if _bSpace then sTrim = sTrim:gsub(tPatt[iPatt], '') end
        return sTrim
    end
    ------------------------------------------------------------------------------------------------

    --[[
        Returns the given string encoded for use in URL
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.UrlEncode = function(self, _s)
        local tEscape = {[' ']='%%20',['!']='%%21',['"']='%%22',['#']='%%23',['%$']='%%24',['&']='%%26',["'"]='%%27',
        ['%(']='%%28',['%)']='%%29',['%*']='%%2A',['%+']='%%2B',[',']='%%2C',['/']='%%2F',[':']='%%3A',[';']='%%3B',
        ['<']='%%3C',['=']='%%3D',['>']='%%3E',['%?']='%%3F',['@']='%%40',['%[']='%%5B',['\\']='%%5C',[']']='%%5D',
        ['{']='%%7B',['|']='%%7C',['}']='%%7D'}
        _s = _s:gsub('%%','%%25')
        for k, v in pairs(tEscape) do _s = _s:gsub(k, v) end
        return _s
    end
    ------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------- /MISC ----


    ---------------------------------------------------------------------------- AU3 - SPECIFIC ----

    --[[
        Returns a table with locations of AU3 - include files in the system
    ]]
    ------------------------------------------------------------------------------------------------
    CommonTools.GetIncludePathes = function(self)
        return self:Split(props['openpath.$(au3)'], ';')
    end
    ------------------------------------------------------------------------------------------------


    --------------------------------------------------------------------------- /AU3 - SPECIFIC ----

    return CommonTools
end