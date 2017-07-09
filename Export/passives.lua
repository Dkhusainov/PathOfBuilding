loadStatFile("passive_skill_stat_descriptions.txt")

local out = io.open("../Data/3_0/Passives.lua", "w")
out:write('-- This file is automatically generated, do not edit!\n')
out:write('-- Passive skill data (c) Grinding Gear Games\n\nreturn {\n')
for passiveKey = 0, PassiveSkills.maxRow do
	local passive = PassiveSkills[passiveKey]
	out:write('\t[', passive.PassiveSkillGraphId, '] = { ')
	out:write('name = "', passive.Name, '", ')
	if passive.StatsKeys[1] > 0 then
		if passive.GrantedBuff_BuffDefinitionsKey then
			loadStatFile("passive_skill_aura_stat_descriptions.txt")
		else
			loadStatFile("passive_skill_stat_descriptions.txt")
		end
		local stats = { }
		for i, statKey in ipairs(passive.StatsKeys) do
			stats[Stats[statKey].Id] = { min = passive["Stat"..i.."Value"], max = passive["Stat"..i.."Value"] }
		end
		out:write('"', table.concat(describeStats(stats), '", "'), '", ')
	end
	out:write('},\n')
end
out:write('}')
out:close()

print("Passives exported.")