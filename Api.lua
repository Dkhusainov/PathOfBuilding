--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 16.07.2017
-- Time: 21:45
-- To change this template use File | Settings | File Templates.
--

-----------------Data--------------
function addSkill(key, skill)
    if not data[liveTargetVersion].skills[key] then
        data[liveTargetVersion].skills[key] = skill
    end
end
function removeSkill(key)
    data[liveTargetVersion].skills[key] = nil
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