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