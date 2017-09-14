--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--

local treeText = ...
require("Enviroment")

local ok, tree = serpent.load(treeText)
main.tree[liveTargetVersion] = tree
for _, node in ipairs(tree.nodes) do
    local modList = common.New("ModList")
    for k, v in ipairs(node.modList) do
        modList[k] = v
    end
    node.modList = modList
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

function loadUnique(raw)
    local newItem = itemLib.makeItemFromRaw(liveTargetVersion, "Rarity: Unique\n"..raw)
    if newItem then
        itemLib.normaliseQuality(newItem)
        main.uniqueDB[liveTargetVersion].list[newItem.name] = newItem
    else
        ConPrintf("Unique DB unrecognised item of type '%s':\n%s", type, raw)
    end
end

function removeUnique(name)
    main.uniqueDB[liveTargetVersion].list[name] = nil
end