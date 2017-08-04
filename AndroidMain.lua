--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--
local treeText = ...
inspect = require("inspect")
json = require("json")
serpent = require("serpent")
--unpack = require("unpack")
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
function LoadModule(name, ...)
    print("Loading " .. name .. "...")
    local a = assert(loadfile(name..".lua"))
    return a(...)
end

function ConPrintf(text, ...)
    local t = string.format(text, ...)
    print(t)
end

function MakeDir(a) end

function unpack(t, i)
    i = i or 1		--single argument (like below), i defaults to 1
    if t[i] then
        return t[i], unpack(t, i+1)		--recursion
    end
end

function GetTime() return 0 end
function NewImageHandle() return 0 end

defaultTargetVersion = "3_0"
liveTargetVersion = "3_0"
targetVersionList = { "3_0" }

launch = {
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

for _, targetVersion in ipairs(targetVersionList) do
    LoadModule("Data/"..targetVersion.."/ModCache", modLib.parseModCache[targetVersion])
    if treeText ~= nil then
        local ok, tree = serpent.load(treeText)
        main.tree[targetVersion] = tree
    end
end

for _, targetVersion in ipairs(targetVersionList) do
    main.uniqueDB[targetVersion] = { list = { } }
    for type, typeList in pairs(data.uniques) do
        for k, raw in pairs(typeList) do
            local newItem = itemLib.makeItemFromRaw(targetVersion, "Rarity: Unique\n"..raw)
            if newItem then
                itemLib.normaliseQuality(newItem)
                main.uniqueDB[targetVersion].list[newItem.name] = newItem
            else
                ConPrintf("Unique DB unrecognised item of type '%s':\n%s", type, raw)
            end
            typeList[k] = nil
        end
    end
    data.uniques = nil
--    self.rareDB[targetVersion] = { list = { } }
--    for _, raw in pairs(data[targetVersion].rares) do
--        local newItem = itemLib.makeItemFromRaw(targetVersion, "Rarity: Rare\n"..raw)
--        if newItem then
--            itemLib.normaliseQuality(newItem)
--            if newItem.crafted then
--                if newItem.base.implicit and (#newItem.modLines == 0 or newItem.modLines[1].custom) then
--                    newItem.implicitLines = 0
--                    for line in newItem.base.implicit:gmatch("[^\n]+") do
--                        local modList, extra = modLib.parseMod[targetVersion](line)
--                        newItem.implicitLines = newItem.implicitLines + 1
--                        t_insert(newItem.modLines, newItem.implicitLines, { line = line, extra = extra, modList = modList or { } })
--                    end
--                end
--                itemLib.craftItem(newItem)
--            end
--            self.rareDB[targetVersion].list[newItem.name] = newItem
--        else
--            ConPrintf("Rare DB unrecognised item:\n%s", raw)
--        end
--    end
end

build = LoadModule("Modules/Build", launch, main)
build.buildFlag = false
function initBuild(name, xml)
    build:Init("dbFileName", name, xml, liveTargetVersion)
end
function saveBuild()
    return build:SaveDB()
end

function recalculate()
    build.buildFlag = false
    build.calcsTab:BuildOutput()
    build:RefreshStatList()
    return build.controls.statBox.list
end