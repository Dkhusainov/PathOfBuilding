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
    mod.source = grantedEffect.modSource
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


function processLoadedSkill(key, grantedEffect)
        grantedEffect.id = key
        grantedEffect.modSource = "Skill:"..key
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
            grantedEffect.defaultLevel = (grantedEffect.levels[20] and 20) or (grantedEffect.levels[3][2] and 3) or 1
        end
end

-----------------GemSearch--------------
--GemSelectControl//function GemSelectClass:Draw(viewPort)
function getSearchResult(self)
    if (#self.list == 1 and self.list[1] == "") then
        return {}
    end

    local result = {}
    local t_insert = table.insert
    local gems = self.skillsTab.build.data.gems
    local displaySkillList = self.skillsTab.displayGroup.displaySkillList
    local dpsColor = self.sortCache.dpsColor
    for _, gemId in ipairs(self.list) do
        local gem = gems[gemId]
        local gemData = self.gems[gemId]
        local grantedEffect = gem.grantedEffect
        local searchResultItem = {
            name = gemData.name,
            gemId = gemId,
            okSign = false,
            plusSign = false,
            signColor = colorCodes.NORMAL,
            color = colorCodes.NORMAL
        }
        if grantedEffect then
            if grantedEffect.color == 1 then
                searchResultItem.color = colorCodes.STRENGTH
            elseif grantedEffect.color == 2 then
                searchResultItem.color = colorCodes.DEXTERITY
            elseif grantedEffect.color == 3 then
                searchResultItem.color = colorCodes.INTELLIGENCE
            end
        end
        if grantedEffect then
            if grantedEffect.support and displaySkillList then
                for _, activeSkill in ipairs(displaySkillList) do
                    if calcLib.canGrantedEffectSupportActiveSkill(grantedEffect, activeSkill) then
                        searchResultItem.okSign = true
                        searchResultItem.signColor = dpsColor[gemId]
                        break
                    end
                end
            elseif grantedEffect.hasGlobalEffect then
                searchResultItem.plusSign = true
                searchResultItem.signColor = dpsColor[gemId]
            end
        end
        t_insert(result, searchResultItem)
    end
    return result
end