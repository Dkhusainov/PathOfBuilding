--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--

local tree = main.tree[liveTargetVersion]
local modList = getmetatable(new("ModList"))
local modStore = getmetatable(new("ModStore"))
for _, node in pairs(tree.nodes) do
    setmetatable(node.modList, modList)
    setmetatable(node.modList.ModStore, modStore)
end

launch.DownloadPage = function(_, url, callback, cookies)
    local input = {}
    table.insert(input, url)
    table.insert(input, callback)
    table.insert(input, cookies)
    httpDelegate:DownloadPage(input)
end

httpDelegate = {}
eventBusDelegate = {}
debugDelegate = {}
sha1Delegate = {}

modCacheLoader = {
    loadByLine = function() return nil end
}
baseLoader = {}

common.sha1 = function(input)
    return sha1Delegate:sha1(input)
end

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

    addLoaderToTable(data[targetVersion].skills, "skill")
    addLoaderToTable(data[targetVersion].itemBases, "base")
    addLoaderToTable(data[targetVersion].minions, "minions")

    modCacheLoader = loaders["mod"]
    baseLoader = loaders["base"]
end