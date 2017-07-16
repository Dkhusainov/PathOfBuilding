--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 16.07.2017
-- Time: 21:45
-- To change this template use File | Settings | File Templates.
--

-----------------Data--------------
function addSkill(key, skill)
    data[liveTargetVersion].skills[key] = skill
end
function removeSkill(key)
    data[liveTargetVersion].skills[key] = nil
end

-----------------Skills-------------
function newSkillGroup()
    build.skillsTab.controls.groupList.controls.new.onClick()
end

function addGemToSkillGroup(name, index)
    build.skillsTab.gemSlots[index].nameSpec.gemChangeFunc(name, false)
end

-----------------Other-------------
function parseMod(line)
    return modLib.parseMod[liveTargetVersion](line)
end