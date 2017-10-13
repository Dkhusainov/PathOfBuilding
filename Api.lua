--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 16.07.2017
-- Time: 21:45
-- To change this template use File | Settings | File Templates.
--

-----------------Data--------------

-----------------Skills

local function processMod(grantedEffect, mod)
    mod.source = "Skill:"..grantedEffect.id
    if type(mod.value) == "table" and mod.value.mod then
        mod.value.mod.source = "Skill:"..grantedEffect.id
    end
    for _, tag in ipairs(mod) do
        if tag.type == "GlobalEffect" then
            grantedEffect.hasGlobalEffect = true
            break
        end
    end
end

function addSkill(key, grantedEffect)
    if not data[liveTargetVersion].skills[key] then
        data[liveTargetVersion].skills[key] = grantedEffect

        grantedEffect.id = key
        -- Add sources for skill mods, and check for global effects
        for _, list in pairs({grantedEffect.baseMods, grantedEffect.qualityMods, grantedEffect.levelMods}) do
            for _, mod in pairs(list) do
                if mod.name then
                    processMod(grantedEffect, mod)
                else
                    for _, mod in ipairs(mod) do
                        processMod(grantedEffect, mod)
                    end
                end
            end
        end

        if grantedEffect.gemTags then
            data[liveTargetVersion].gems[grantedEffect.name] = grantedEffect
            grantedEffect.defaultLevel = (grantedEffect.levels[20] and 20) or (grantedEffect.levels[3][2] and 3) or 1
        end
    end
end

function createUnique(raw)
    local newItem = itemLib.makeItemFromRaw(liveTargetVersion, "Rarity: Unique\n"..raw)
    itemLib.normaliseQuality(newItem)
    return newItem
--    if newItem then
--        itemLib.normaliseQuality(newItem)
--        main.uniqueDB[liveTargetVersion].list[newItem.name] = newItem
--    else
--        ConPrintf("Unique DB unrecognised item of type '%s':\n%s", type, raw)
--    end
end

-----------------GemSearch--------------
--GemSelectControl//function GemSelectClass:Draw(viewPort)
function getSearchResult(self)
    local result = {}
    local t_insert = table.insert
    for _, name in ipairs(self.list) do
        local searchResultItem = {
            name = name,
            okSign = false,
            plusSign = false,
            signColor = colorCodes.NORMAL
        }
        local grantedEffect = self.skillsTab.build.data.gems[name]
        if grantedEffect then
            if grantedEffect.color == 1 then
                searchResultItem.color = colorCodes.STRENGTH
            elseif grantedEffect.color == 2 then
                searchResultItem.color = colorCodes.DEXTERITY
            elseif grantedEffect.color == 3 then
                searchResultItem.color = colorCodes.INTELLIGENCE
            end
        end
        if grantedEffect and self.skillsTab.sortGemsByDPS then
            if grantedEffect.support and self.skillsTab.displayGroup.displaySkillList then
                local gem = { grantedEffect = grantedEffect }
                for _, activeSkill in ipairs(self.skillsTab.displayGroup.displaySkillList) do
                    if calcLib.gemCanSupport(gem, activeSkill) then
                        searchResultItem.okSign = true
                        searchResultItem.signColor = self.sortCache.dpsColor[name]
                        break
                    end
                end
            elseif grantedEffect.hasGlobalEffect then
                searchResultItem.plusSign = true
                searchResultItem.signColor = self.sortCache.dpsColor[name]
            end
        end
        t_insert(result, searchResultItem)
    end
    return result
end