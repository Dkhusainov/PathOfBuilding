--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--

local serialized = ...

local ok, tree = serpent.load(serialized.tree)

local deserializeToGlobal = function(name)
    local err, result = serpent.load(serialized[name])
    _G[name] = result
end

-- ModParser
-- Build active skill name lookup
deserializeToGlobal("skillNameList")
deserializeToGlobal("preSkillNameList")

main.tree[liveTargetVersion] = tree
local meta = getmetatable(common.New("ModList"))
for _, node in ipairs(tree.nodes) do
    setmetatable(node.modList, meta)
end

itemsTabDelegate = {
    PopulateSlots = function() return nil end
}
modCacheLoader = {
    loadByLine = function() return nil end
}
baseLoader = {}

function setupLoaders(loaders)

    local addLoaderToTable = function(dataTable, loaderName)
        local loader = loaders[loaderName]
        local meta = {
            __index = function (t,k)
                return loader:get(k)
            end
        }
        setmetatable(dataTable, meta)
    end

    addLoaderToTable(data[targetVersion].gems, "skill")
    addLoaderToTable(data[targetVersion].skills, "skill")
    addLoaderToTable(data[targetVersion].itemBases, "base")

    modCacheLoader = loaders["mod"]
    baseLoader = loaders["base"]
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

serpent = nil