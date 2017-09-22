--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--
inspect = require("inspect")
json = require("json")
serpent = require("serpent")
function printTable(t, depth)
    local file = io.open("debug.txt", "w")
    io.output(file)
    io.write("\n")
    local options = {
        depth = depth or 10,
        --        process = true
    }
    local result = inspect.inspect(t, options)
    print(result)
    io.write(result)
    io.write("\n")
    io.close(file)
end

function tableToJson(t)
    return json.encode(t)
end

-- all the hacks for luaj to work
bit = bit32
function MakeDir(a) end
function GetTime() return 0 end
function NewImageHandle() return 0 end
function LoadModule(name, ...)
    print("Loading " .. name .. "...")
    local a = assert(loadfile(name..".lua"))
    return a(...)
end

function ConPrintf(text, ...)
--    local t = string.format(text, ...)
    print(text)
end

function unpack(t, i)
    i = i or 1		--single argument (like below), i defaults to 1
    if t[i] then
        return t[i], unpack(t, i+1)		--recursion
    end
end

--POB stuff
defaultTargetVersion = "3_0"
liveTargetVersion = "3_0"
targetVersion = "3_0"
targetVersionList = { "3_0" }

launch = {
    loadSkills = false,
    loadUniques = false,
    devMode = false,
    ShowErrMsg = function(title, msg) end
}

main = {
    tree = {},
    uniqueDB = { },
    rareDB = { },
    showThousandsSidebar = false,
    lastShowThousandsSidebar = false,
    --todo show dialogs
    OpenConfirmPopup = function(main, title, msg, confirmLabel, onConfirm) onConfirm() end,
    OpenMessagePopup = function(title, msg) end
}
main.uniqueDB[liveTargetVersion] = { list = { } }
main.rareDB[liveTargetVersion] = { list = { } }

--plcaeholder
modCacheLoader = { loadByLine = function() return nil end }
skillLoader = { loadByLine = function() return nil end }

LoadModule("Api")
LoadModule("Modules/Common")
LoadModule("Modules/Data", launch)
LoadModule("Modules/ModTools", launch)
LoadModule("Modules/ItemTools", launch)
LoadModule("Modules/CalcTools", launch)

local classList = {
    "Control",
    "Tooltip",
    "TooltipHost",
    "ControlHost",
    "UndoHandler",
    "ScrollBarControl",
    "ButtonControl",
    "ListControl",
    "TextListControl",
    "DropDownControl",
    "EditControl",
    "LabelControl",
    "CheckBoxControl",
    "CalcSectionControl",
    "CalcBreakdownControl",
    "SectionControl",
    "GemSelectControl",
    "PassiveTree",
    "PassiveTreeView",
    "PassiveSpec",
    "PassiveSpecListControl",
    "PassiveTreeView",
    "SliderControl",
    "ItemSlotControl",
    "ItemListControl",
    "SharedItemListControl",
    "ItemDBControl",
    "ModDB",
    "ModList",
    "SkillList",
    "TreeTab",
    "ConfigTab",
    "SkillsTab",
    "ItemsTab",
    "CalcsTab"
}

for _, className in pairs(classList) do
    LoadModule("Classes/"..className, launch, main)
end
