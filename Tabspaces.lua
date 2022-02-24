-- TIME_STAMP   2022-02-24 14:20:19   v 0.2
-- coding:utf-8

--[[
    Load with "SciTEStartup.lua"
    Require: "CommonTools.lua" ( https://autoit.de/thread/87485-scite-commontools/?postID=704965#post704965 )
            min. version: v 0.6

    To use with spaces as tab (property "use.tabs.$(file.pattern.EXT)=0" or "use.tabs.EXT=0"). Don't use "use.tabs=0"!
    If the property is set to ">0", the script will not respond.
    For use with values other than the default, see remarks.

    Additional functions        <Shift+Backspace>                                       <Shift+Del>
        single caret         :  Delete chars from caret until previous tab position     Delete chars from caret until next tab position
        rectangular selection:              As above, but in each line of selection
                                            The rectangular selection remains after the operation.
                                <Alt+Arrow_Left>                                        <Alt+Arrow_Right>
        single caret            Skip to previous Tab position                           Skip to next Tab position


    Remarks:
        The default Tab size is 4. You can change this setting specified for your file types. The following properties need changes:
        tab.size.$(file.pattern.EXT)=VALUE
        indent.size.$(file.patterns.EXT)=VALUE

        The (not file type specific) values:
        tab.indents=1
        backspace.unindents=1
        should also set.
        If tab.indents is set then pressing tab within indentation whitespace indents by indent.size rather than inserting a tab character.
        If backspace.unindents then pressing backspace within indentation whitespace unindents by indent.size rather than deleting the character before the caret.
]]

--  v 0.2   changed:    SCRIPT BREAKING CHANCE - Now only file specific properties ("use.tabs.$(file.pattern.EXT)=0" or "use.tabs.EXT=0") are considered!


local ct = require 'CommonTools'

Tabspaces = EventClass:new(Common)

-- Gets the carets column and position
Tabspaces.Caret = function(self)
    local pos = editor.CurrentPos
    local col = editor.Column[editor.CurrentPos]
    return col, pos
end


-- Gets a table with {{line,pos}} for rectangular selection without selected text [caret only!]
Tabspaces.GetRect = function(self)
    local tRet = {}
    local selLines = editor.Selections
    if (editor.SelectionMode == 0) or
        (selLines < 2) or (editor.SelectionIsRectangle == false) then
        return false, {}
    end
    local s_start = editor.SelectionStart
    local s_end = editor.SelectionEnd
    if s_start > s_end then s_start, s_end = s_end, s_start end
    local line, s, e = editor:LineFromPosition(s_start)
    repeat
        s = editor:GetLineSelStartPosition(line)
        e = editor:GetLineSelEndPosition(line)
        if s ~= e then return false, {} end   -- don't use with selected text
        table.insert(tRet, {line,s})
        line = line +1
        selLines = selLines -1
    until selLines == 0
    return true, tRet
end


-- Deletes all characters left/right from cursor until the previous/next Tab position in line from caret
-- left side,  keys: <Shift+Backspace>
-- right side, keys: <Shift+Del>
Tabspaces.DeleteLine = function(self, b_right)
    local colCaret, posCaret = self:Caret()
    local colTab, posTab
    if b_right then
        colTab, posTab = ct:EditorTabColPosInLine()     -- next Tab
        local posLast = editor.LineEndPosition[editor:LineFromPosition(posCaret)]
        if posTab > posLast then posTab = posLast end
    else
        colTab, posTab = ct:EditorTabColPosInLine(true) -- previous Tab
    end
    editor:SetSelection(posTab, posCaret)
    editor:ReplaceSel('')
end


-- Performs the deletion in the selected line(s) on the right or left side
Tabspaces.DeleteLeftRight = function(self, b_right)
    local bRect, tRect = self:GetRect()
    if bRect then
        for i = #tRect, 1, -1  do
            editor.CurrentPos = tRect[i][2]
            self:DeleteLine(b_right)
        end
        scite.MenuCommand(IDM_SAVE)
        local col = editor.Column[editor.CurrentPos]
        editor.RectangularSelectionAnchor = editor:FindColumn(tRect[1][1], col)
        for i = 2, #tRect  do
            editor.RectangularSelectionCaret = editor:FindColumn(tRect[i][1], col)
        end
    else
        self:DeleteLine(b_right)
    end
end

-- Skip to previous/next Tab position
-- left side,  keys: <Alt+Arrow_Left>
-- right side, keys: <Alt+Arrow_Right>
Tabspaces.SkipLeftRight = function(self, b_right)
    local colCaret, posCaret = self:Caret()
    local posTab
    if b_right then
        _, posTab = ct:EditorTabColPosInLine()     -- next Tab
        local posLast = editor.LineEndPosition[editor:LineFromPosition(posCaret)]
        if posTab > posLast then posTab = posLast end
    else
        _, posTab = ct:EditorTabColPosInLine(true) -- previous Tab
    end
    editor:SetSelection(posTab, posTab)
end

Tabspaces.OnKey = function(self, _keycode, _shift, _ctrl, _alt)
    if ct:PropExt('use.tabs.', props['FileExt']) == '0' then    -- file type specific setting is required
        local tKeys = {[8]='backspace',[37]='ar_left', [39]='ar_right', [46]='delete'}
        local key = tKeys[_keycode]
        if key == nil then return nil end
        if _shift and not _ctrl and not _alt then
            if key == 'backspace' then
                self:DeleteLeftRight()
                return true
            elseif key == 'delete' then
                self:DeleteLeftRight(true)
                return true
            else
                return nil
            end
        elseif not _shift and not _ctrl and _alt then
            if key == 'ar_left' then
                self:SkipLeftRight()
                return true
            elseif key == 'ar_right' then
                self:SkipLeftRight(true)
                return true
            else
                return nil
            end
        end
    end
    return nil
end





