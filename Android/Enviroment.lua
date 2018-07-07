--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--
local t_insert = table.insert
local generator, skipData = ...

function MakeDir(a) end
function IsKeyDown() return false end
function DrawStringWidth() return 0 end
function DrawStringCursorIndex() return 0 end
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

--POB stuff
defaultTargetVersion = "3_0"
liveTargetVersion = "3_0"
targetVersion = "3_0"
targetVersionList = { "3_0" }

launch = {
    generator = generator,
    skipData = skipData,
    devMode = false,
    ShowErrMsg = function(title, msg) end
}

main = {
    tree = {},
    uniqueDB = { },
    rareDB = { },
    gameAccounts = {},
    showThousandsSidebar = false,
    lastShowThousandsSidebar = false,
    --todo show dialogs
    OpenConfirmPopup = function(main, title, msg, confirmLabel, onConfirm) onConfirm() end,
    OpenMessagePopup = function(title, msg) end
}
main.uniqueDB[liveTargetVersion] = { list = { } }
main.rareDB[liveTargetVersion] = { list = { } }
main.tree[liveTargetVersion] = { nodes = {} }

function main:StatColor(stat, base, limit)
    if limit and stat > limit then
        return colorCodes.NEGATIVE
    elseif base and stat  ~= base then
        return colorCodes.MAGIC
    else
        return "^7"
    end
end

do
    local wrapTable = { }
    function main:WrapString(str, height, width)
        wipeTable(wrapTable)
        local lineStart = 1
        local lastSpace, lastBreak
        while true do
            local s, e = str:find("%s+", lastSpace)
            if not s then
                s = #str + 1
                e = #str + 1
            end
            if DrawStringWidth(height, "VAR", str:sub(lineStart, s - 1)) > width then
                t_insert(wrapTable, str:sub(lineStart, lastBreak))
                lineStart = lastSpace
            end
            if s > #str then
                t_insert(wrapTable, str:sub(lineStart, -1))
                break
            end
            lastBreak = s - 1
            lastSpace = e + 1
        end
        return wrapTable
    end
end

--plcaeholder
modCacheLoader = { loadByLine = function() return nil end }
baseLoader = { all = function() return {} end }
itemsTabDelegate = { PopulateSlots = function() return nil end }

LoadModule("Android/Api")
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
    --"CalcBreakdownControl",
    "SectionControl",
    "GemSelectControl",
    --"PassiveTree",
    "PassiveTreeView",
    "PassiveSpec",
    "PassiveSpecListControl",
    "SliderControl",
    "ItemSlotControl",
    "ItemListControl",
    --"SharedItemListControl",
    --"ItemDBControl",
    "ModStore",
    "ModDB",
    "ModList",
    "SkillList",
    "TreeTab",
    "ConfigTab",
    "SkillsTab",
    "ItemsTab",
    "CalcsTab",
    "ImportTab",
    "Item",
}

for _, className in pairs(classList) do
    LoadModule("Classes/"..className, launch, main)
end

if (generator) then
    for type, typeList in pairs(data.uniques) do
        for _, raw in pairs(typeList) do
            local newItem = common.New("Item", targetVersion, "Rarity: Unique\n"..raw)
            if newItem then
                newItem:NormaliseQuality()
                main.uniqueDB[targetVersion].list[newItem.name] = newItem
            else
                ConPrintf("Unique DB unrecognised item of type '%s':\n%s", type, raw)
            end
        end
    end
end

build = LoadModule("Modules/Build", launch, main)
build.buildFlag = false
function initBuild(name, xml)
    build:Init("dbFileName", name, xml, liveTargetVersion)
    build:OnFrame()
end

function saveBuild()
    return build:SaveDB()
end