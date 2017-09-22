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
local meta = getmetatable(common.New("ModList"))
for _, node in ipairs(tree.nodes) do
    setmetatable(node.modList, meta)
end

--LoadModule("Data/"..liveTargetVersion.."/ModCache", modLib.parseModCache[liveTargetVersion])
modCacheLoader = {}--load mods form disk

skillLoader = {}

build = LoadModule("Modules/Build", launch, main)
build.buildFlag = false
function initBuild(name, xml)
    build:Init("dbFileName", name, xml, liveTargetVersion)
    build:OnFrame()
end
function saveBuild()
    return build:SaveDB()
end