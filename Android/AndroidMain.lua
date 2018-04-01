--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--

local tree = main.tree[liveTargetVersion]
local meta = getmetatable(common.New("ModList"))
for _, node in ipairs(tree.nodes) do
    setmetatable(node.modList, meta)
end

launch.DownloadPage = function(_, url, callback, cookies)
    local input = {}
    table.insert(input, url)
    table.insert(input, callback)
    table.insert(input, cookies)
    httpDelegate:DownloadPage(input)
end

httpDelegate = {}

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
    addLoaderToTable(data[targetVersion].minions, "minions")

    modCacheLoader = loaders["mod"]
    baseLoader = loaders["base"]
end

function saveBuild()
    return build:SaveDB()
end