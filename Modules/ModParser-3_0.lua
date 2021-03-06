-- Path of Building
--
-- Module: Mod Parser for 3.0
-- Parser function for modifier names
--

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local band = bit.band
local bor = bit.bor
local bnot = bit.bnot

-- List of modifier forms
local formList = {
	["^(%d+)%% increased"] = "INC",
	["^(%d+)%% faster"] = "INC",
	["^(%d+)%% reduced"] = "RED",
	["^(%d+)%% slower"] = "RED",
	["^(%d+)%% more"] = "MORE",
	["^(%d+)%% less"] = "LESS",
	["^([%+%-][%d%.]+)%%?"] = "BASE",
	["^([%+%-][%d%.]+)%%? to"] = "BASE",
	["^([%+%-]?[%d%.]+)%%? of"] = "BASE",
	["^([%+%-][%d%.]+)%%? base"] = "BASE",
	["^([%+%-]?[%d%.]+)%%? additional"] = "BASE",
	["^you gain ([%d%.]+)"] = "BASE",
	["^gain ([%d%.]+)%% of"] = "BASE",
	["^([%+%-]?%d+)%% chance"] = "CHANCE",
	["^([%+%-]?%d+)%% additional chance"] = "CHANCE",
	["penetrates? (%d+)%%"] = "PEN",
	["penetrates (%d+)%% of"] = "PEN",
	["penetrates (%d+)%% of enemy"] = "PEN",
	["^([%d%.]+) (.+) regenerated per second"] = "REGENFLAT",
	["^([%d%.]+)%% (.+) regenerated per second"] = "REGENPERCENT",
	["^([%d%.]+)%% of (.+) regenerated per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+) (.+) per second"] = "REGENFLAT",
	["^regenerate ([%d%.]+)%% (.+) per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+)%% of (.+) per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+)%% of your (.+) per second"] = "REGENPERCENT",
	["(%d+) to (%d+) additional (%a+) damage"] = "DMG",
	["adds (%d+) to (%d+) (%a+) damage"] = "DMG",
	["adds (%d+)%-(%d+) (%a+) damage"] = "DMG",
	["adds (%d+) to (%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) attack damage"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) attack damage"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+)%-(%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) spell damage"] = "DMGSPELLS",
	["adds (%d+)%-(%d+) (%a+) spell damage"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) damage to attacks and spells"] = "DMGBOTH",
	["adds (%d+)%-(%d+) (%a+) damage to attacks and spells"] = "DMGBOTH",
	["adds (%d+) to (%d+) (%a+) damage to spells and attacks"] = "DMGBOTH", -- o_O
	["adds (%d+)%-(%d+) (%a+) damage to spells and attacks"] = "DMGBOTH", -- o_O
}

-- Map of modifier names
local modNameList = {
	-- Attributes
	["strength"] = "Str",
	["dexterity"] = "Dex",
	["intelligence"] = "Int",
	["strength and dexterity"] = { "Str", "Dex" },
	["strength and intelligence"] = { "Str", "Int" },
	["dexterity and intelligence"] = { "Dex", "Int" },
	["attributes"] = { "Str", "Dex", "Int" },
	["all attributes"] = { "Str", "Dex", "Int" },
	-- Life/mana
	["life"] = "Life",
	["maximum life"] = "Life",
	["mana"] = "Mana",
	["maximum mana"] = "Mana",
	["mana regeneration"] = "ManaRegen",
	["mana regeneration rate"] = "ManaRegen",
	["mana cost"] = "ManaCost",
	["mana cost of skills"] = "ManaCost",
	["mana reserved"] = "ManaReserved",
	["mana reservation"] = "ManaReserved",
	-- Primary defences
	["maximum energy shield"] = "EnergyShield",
	["energy shield recharge rate"] = "EnergyShieldRecharge",
	["energy shield recovery rate"] = "EnergyShieldRecovery",
	["start of energy shield recharge"] = "EnergyShieldRechargeFaster",
	["armour"] = "Armour",
	["evasion"] = "Evasion",
	["evasion rating"] = "Evasion",
	["energy shield"] = "EnergyShield",
	["armour and evasion"] = "ArmourAndEvasion",
	["armour and evasion rating"] = "ArmourAndEvasion",
	["evasion rating and armour"] = "ArmourAndEvasion",
	["armour and energy shield"] = "ArmourAndEnergyShield",
	["evasion and energy shield"] = "EvasionAndEnergyShield",
	["armour, evasion and energy shield"] = "Defences",
	["defences"] = "Defences",
	["chance to evade"] = "EvadeChance",
	["chance to evade attacks"] = "EvadeChance",
	["chance to evade projectile attacks"] = "ProjectileEvadeChance",
	["chance to evade melee attacks"] = "MeleeEvadeChance",
	-- Resistances
	["physical damage reduction"] = "PhysicalDamageReduction",
	["fire resistance"] = "FireResist",
	["maximum fire resistance"] = "FireResistMax",
	["cold resistance"] = "ColdResist",
	["maximum cold resistance"] = "ColdResistMax",
	["lightning resistance"] = "LightningResist",
	["maximum lightning resistance"] = "LightningResistMax",
	["chaos resistance"] = "ChaosResist",
	["fire and cold resistances"] = { "FireResist", "ColdResist" },
	["fire and lightning resistances"] = { "FireResist", "LightningResist" },
	["cold and lightning resistances"] = { "ColdResist", "LightningResist" },
	["elemental resistances"] = "ElementalResist",
	["all elemental resistances"] = "ElementalResist",
	["all resistances"] = { "ElementalResist", "ChaosResist" },
	["all maximum elemental resistances"] = { "FireResistMax", "ColdResistMax", "LightningResistMax" },
	["all maximum resistances"] = { "FireResistMax", "ColdResistMax", "LightningResistMax", "ChaosResistMax" },
	-- Damage taken
	["damage taken"] = "DamageTaken",
	["physical damage taken"] = "PhysicalDamageTaken",
	["lightning damage taken"] = "LightningDamageTaken",
	["cold damage taken"] = "ColdDamageTaken",
	["fire damage taken"] = "FireDamageTaken",
	["chaos damage taken"] = "ChaosDamageTaken",
	["elemental damage taken"] = "ElementalDamageTaken",
	["damage taken from damage over time"] = "DamageTakenOverTime",
	["chaos damage taken over time"] = "ChaosDamageTakenOverTime",
	-- Other defences
	["to dodge attacks"] = "AttackDodgeChance",
	["to dodge spells"] = "SpellDodgeChance",
	["to dodge spell damage"] = "SpellDodgeChance",
	["to block"] = "BlockChance",
	["to block attacks"] = "BlockChance",
	["block chance"] = "BlockChance",
	["block chance with staves"] = { "BlockChance", tag = { type = "Condition", var = "UsingStaff" } },
	["to block with staves"] = { "BlockChance", tag = { type = "Condition", var = "UsingStaff" } },
	["spell block chance"] = "SpellBlockChance",
	["to block spells"] = "SpellBlockChance",
	["chance to block attacks and spells"] = { "BlockChance", "SpellBlockChance" },
	["maximum block chance"] = "BlockChanceMax",
	["block chance applied to spells"] = "BlockChanceConv",
	["to avoid being stunned"] = "AvoidStun",
	["to avoid being shocked"] = "AvoidShock",
	["to avoid being frozen"] = "AvoidFrozen",
	["to avoid being chilled"] = "AvoidChilled",
	["to avoid being ignited"] = "AvoidIgnite",
	["to avoid elemental ailments"] = { "AvoidShock", "AvoidFrozen", "AvoidChilled", "AvoidIgnite" },
	["to avoid elemental status ailments"] = { "AvoidShock", "AvoidFrozen", "AvoidChilled", "AvoidIgnite" },
	["damage is taken from mana before life"] = "DamageTakenFromManaBeforeLife",
	["effect of curses on you"] = "CurseEffectOnSelf",
	["recovery rate of life, mana and energy shield"] = { "LifeRecovery", "ManaRecovery", "EnergyShieldRecovery" },
	-- Stun/knockback modifiers
	["stun recovery"] = "StunRecovery",
	["stun and block recovery"] = "StunRecovery",
	["block and stun recovery"] = "StunRecovery",
	["stun threshold"] = "StunThreshold",
	["block recovery"] = "BlockRecovery",
	["enemy stun threshold"] = "EnemyStunThreshold",
	["stun duration on enemies"] = "EnemyStunDuration",
	["stun duration"] = "EnemyStunDuration",
	["to knock enemies back on hit"] = "EnemyKnockbackChance",
	["knockback distance"] = "EnemyKnockbackDistance",
	-- Auras/curses/buffs
	["aura effect"] = "AuraEffect",
	["effect of non-curse auras you cast"] = "AuraEffect",
	["effect of your curses"] = "CurseEffect",
	["effect of auras on you"] = "AuraEffectOnSelf",
	["effect of auras on your minions"] = { "AuraEffectOnSelf", addToMinion = true },
	["curse effect"] = "CurseEffect",
	["curse duration"] = { "Duration", keywordFlags = KeywordFlag.Curse },
	["radius of auras"] = { "AreaOfEffect", keywordFlags = KeywordFlag.Aura },
	["radius of curses"] = { "AreaOfEffect", keywordFlags = KeywordFlag.Curse },
	["buff effect"] = "BuffEffect",
	["effect of buffs on you"] = "BuffEffectOnSelf",
	["effect of buffs granted by your golems"] = { "BuffEffect", tag = { type = "SkillType", skillType = SkillType.Golem } },
	["effect of buffs granted by socketed golem skills"] = { "BuffEffect", addToSkill = { type = "SocketedIn", keyword = "golem" } },
	["effect of the buff granted by your stone golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Stone Golem" } },
	["effect of the buff granted by your lightning golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Lightning Golem" } },
	["effect of the buff granted by your ice golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Ice Golem" } },
	["effect of the buff granted by your flame golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["effect of the buff granted by your chaos golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Chaos Golem" } },
	["effect of offering spells"] = { "BuffEffect", tag = { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } } },
	["warcry effect"] = { "BuffEffect", keywordFlags = KeywordFlag.Warcry },
	-- Charges
	["maximum power charge"] = "PowerChargesMax",
	["maximum power charges"] = "PowerChargesMax",
	["power charge duration"] = "PowerChargesDuration",
	["maximum frenzy charge"] = "FrenzyChargesMax",
	["maximum frenzy charges"] = "FrenzyChargesMax",
	["frenzy charge duration"] = "FrenzyChargesDuration",
	["maximum endurance charge"] = "EnduranceChargesMax",
	["maximum endurance charges"] = "EnduranceChargesMax",
	["endurance charge duration"] = "EnduranceChargesDuration",
	["endurance, frenzy and power charge duration"] = { "PowerChargesDuration", "FrenzyChargesDuration", "EnduranceChargesDuration" },
	-- On hit/kill/leech effects
	["life gained on kill"] = "LifeOnKill",
	["mana gained on kill"] = "ManaOnKill",
	["life gained for each enemy hit by attacks"] = { "LifeOnHit", flags = ModFlag.Attack },
	["life gained for each enemy hit by your attacks"] = { "LifeOnHit", flags = ModFlag.Attack },
	["life gained for each enemy hit by spells"] = { "LifeOnHit", flags = ModFlag.Spell },
	["life gained for each enemy hit by your spells"] = { "LifeOnHit", flags = ModFlag.Spell },
	["mana gained for each enemy hit by attacks"] = { "ManaOnHit", flags = ModFlag.Attack },
	["mana gained for each enemy hit by your attacks"] = { "ManaOnHit", flags = ModFlag.Attack },
	["energy shield gained for each enemy hit by attacks"] = { "EnergyShieldOnHit", flags = ModFlag.Attack },
	["energy shield gained for each enemy hit by your attacks"] = { "EnergyShieldOnHit", flags = ModFlag.Attack },
	["life and mana gained for each enemy hit"] = { "LifeOnHit", "ManaOnHit", flags = ModFlag.Attack },
	["damage as life"] = "DamageLifeLeech",
	["life leeched per second"] = "LifeLeechRate",
	["mana leeched per second"] = "ManaLeechRate",
	["maximum life per second to maximum life leech rate"] = "MaxLifeLeechRate",
	["maximum mana per second to maximum mana leech rate"] = "MaxManaLeechRate",
	-- Projectile modifiers
	["projectile"] = "ProjectileCount",
	["projectiles"] = "ProjectileCount",
	["projectile speed"] = "ProjectileSpeed",
	["arrow speed"] = { "ProjectileSpeed", flags = ModFlag.Bow },
	-- Totem/trap/mine modifiers
	["totem placement speed"] = "TotemPlacementSpeed",
	["totem life"] = "TotemLife",
	["totem duration"] = "TotemDuration",
	["trap throwing speed"] = "TrapThrowingSpeed",
	["trap trigger area of effect"] = "TrapTriggerAreaOfEffect",
	["trap duration"] = "TrapDuration",
	["cooldown recovery speed for throwing traps"] = { "CooldownRecovery", keywordFlags = KeywordFlag.Trap },
	["mine laying speed"] = "MineLayingSpeed",
	["mine detonation area of effect"] = "MineDetonationAreaOfEffect",
	["mine duration"] = "MineDuration",
	-- Minion modifiers
	["maximum number of skeletons"] = "ActiveSkeletonLimit",
	["maximum number of zombies"] = "ActiveZombieLimit",
	["number of zombies allowed"] = "ActiveZombieLimit",
	["maximum number of spectres"] = "ActiveSpectreLimit",
	["maximum number of golems"] = "ActiveGolemLimit",
	["skeleton duration"] = { "Duration", tag = { type = "SkillName", skillName = "Summon Skeletons" } },
	-- Other skill modifiers
	["radius"] = "AreaOfEffect",
	["radius of area skills"] = "AreaOfEffect",
	["area of effect radius"] = "AreaOfEffect",
	["area of effect"] = "AreaOfEffect",
	["area of effect of skills"] = "AreaOfEffect",
	["area of effect of area skills"] = "AreaOfEffect",
	["duration"] = "Duration",
	["skill effect duration"] = "Duration",
	["chaos skill effect duration"] = { "Duration", keywordFlags = KeywordFlag.Chaos },
	["cooldown recovery"] = "CooldownRecovery",
	["cooldown recovery speed"] = "CooldownRecovery",
	["weapon range"] = "WeaponRange",
	["melee weapon and unarmed range"] = { "MeleeWeaponRange", "UnarmedRange" },
	["to deal double damage"] = "DoubleDamageChance",
	-- Buffs
	["onslaught effect"] = "OnslaughtEffect",
	["fortify duration"] = "FortifyDuration",
	["effect of fortify on you"] = "FortifyEffectOnSelf",
	-- Basic damage types
	["damage"] = "Damage",
	["physical damage"] = "PhysicalDamage",
	["lightning damage"] = "LightningDamage",
	["cold damage"] = "ColdDamage",
	["fire damage"] = "FireDamage",
	["chaos damage"] = "ChaosDamage",
	["elemental damage"] = "ElementalDamage",
	-- Other damage forms
	["attack damage"] = { "Damage", flags = ModFlag.Attack },
	["attack physical damage"] = { "PhysicalDamage", flags = ModFlag.Attack },
	["physical attack damage"] = { "PhysicalDamage", flags = ModFlag.Attack },
	["physical weapon damage"] = { "PhysicalDamage", flags = ModFlag.Weapon },
	["physical melee damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["melee physical damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["projectile damage"] = { "Damage", flags = ModFlag.Projectile },
	["projectile attack damage"] = { "Damage", flags = bor(ModFlag.Projectile, ModFlag.Attack) },
	["bow damage"] = { "Damage", flags = ModFlag.Bow },
	["wand damage"] = { "Damage", flags = ModFlag.Wand },
	["wand physical damage"] = { "PhysicalDamage", flags = ModFlag.Wand },
	["claw physical damage"] = { "PhysicalDamage", flags = ModFlag.Claw },
	["sword physical damage"] = { "PhysicalDamage", flags = ModFlag.Sword },
	["damage over time"] = { "Damage", flags = ModFlag.Dot },
	["physical damage over time"] = { "PhysicalDamage", flags = ModFlag.Dot },
	["burning damage"] = { "FireDamage", flags = ModFlag.Dot },
	-- Crit/accuracy/speed modifiers
	["critical strike chance"] = "CritChance",
	["critical strike multiplier"] = "CritMultiplier",
	["accuracy rating"] = "Accuracy",
	["attack speed"] = { "Speed", flags = ModFlag.Attack },
	["cast speed"] = { "Speed", flags = ModFlag.Cast },
	["attack and cast speed"] = "Speed",
	-- Elemental ailments
	["to shock"] = "EnemyShockChance",
	["shock chance"] = "EnemyShockChance",
	["to freeze"] = "EnemyFreezeChance",
	["freeze chance"] = "EnemyFreezeChance",
	["to ignite"] = "EnemyIgniteChance",
	["ignite chance"] = "EnemyIgniteChance",
	["to freeze, shock and ignite"] = { "EnemyFreezeChance", "EnemyShockChance", "EnemyIgniteChance" },
	["shock duration"] = "EnemyShockDuration",
	["freeze duration"] = "EnemyFreezeDuration",
	["chill duration"] = "EnemyChillDuration",
	["ignite duration"] = "EnemyIgniteDuration",
	["duration of elemental ailments"] = { "EnemyShockDuration", "EnemyFreezeDuration", "EnemyChillDuration", "EnemyIgniteDuration" },
	["duration of elemental status ailments"] = { "EnemyShockDuration", "EnemyFreezeDuration", "EnemyChillDuration", "EnemyIgniteDuration" },
	-- Other ailments
	["to poison"] = "PoisonChance",
	["to poison on hit"] = "PoisonChance",
	["poison duration"] = { "EnemyPoisonDuration" },
	["to cause bleeding"] = "BleedChance",
	["to cause bleeding on hit"] = "BleedChance",
	["bleed duration"] = { "EnemyBleedDuration" },
	-- Misc modifiers
	["movement speed"] = "MovementSpeed",
	["attack, cast and movement speed"] = { "Speed", "MovementSpeed" },
	["light radius"] = "LightRadius",
	["rarity of items found"] = "LootRarity",
	["quantity of items found"] = "LootQuantity",
	["strength requirement"] = "StrRequirement",
	["dexterity requirement"] = "DexRequirement",
	["intelligence requirement"] = "IntRequirement",
	["attribute requirements"] = { "StrRequirement", "DexRequirement", "IntRequirement" },
	-- Flask modifiers
	["effect"] = "FlaskEffect",
	["effect of flasks"] = "FlaskEffect",
	["amount recovered"] = "FlaskRecovery",
	["life recovered"] = "FlaskRecovery",
	["mana recovered"] = "FlaskRecovery",
	["life recovery from flasks"] = "FlaskLifeRecovery",
	["mana recovery from flasks"] = "FlaskManaRecovery",
	["flask effect duration"] = "FlaskDuration",
	["recovery speed"] = "FlaskRecoveryRate",
	["flask recovery speed"] = "FlaskRecoveryRate",
	["flask life recovery rate"] = "FlaskLifeRecoveryRate",
	["flask mana recovery rate"] = "FlaskManaRecoveryRate",
	["extra charges"] = "FlaskCharges",
	["maximum charges"] = "FlaskCharges",
	["charges used"] = "FlaskChargesUsed",
	["flask charges used"] = "FlaskChargesUsed",
	["flask charges gained"] = "FlaskChargesGained",
	["charge recovery"] = "FlaskChargeRecovery",
}

-- List of modifier flags
local modFlagList = {
	-- Weapon types
	["with axes"] = { flags = ModFlag.Axe },
	["with bows"] = { flags = ModFlag.Bow },
	["with claws"] = { flags = ModFlag.Claw },
	["dealt with claws"] = { flags = ModFlag.Claw },
	["with daggers"] = { flags = ModFlag.Dagger },
	["with maces"] = { flags = ModFlag.Mace },
	["with staves"] = { flags = ModFlag.Staff },
	["with swords"] = { flags = ModFlag.Sword },
	["with wands"] = { flags = ModFlag.Wand },
	["unarmed"] = { flags = ModFlag.Unarmed },
	["with one handed weapons"] = { flags = ModFlag.Weapon1H },
	["with one handed melee weapons"] = { flags = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee) },
	["with two handed weapons"] = { flags = ModFlag.Weapon2H },
	["with two handed melee weapons"] = { flags = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee) },
	["with ranged weapons"] = { flags = ModFlag.WeaponRanged },
	-- Skill types
	["spell"] = { flags = ModFlag.Spell },
	["with spells"] = { flags = ModFlag.Spell },
	["for spells"] = { flags = ModFlag.Spell },
	["with attacks"] = { keywordFlags = KeywordFlag.Attack },
	["with attack skills"] = { keywordFlags = KeywordFlag.Attack },
	["for attacks"] = { flags = ModFlag.Attack },
	["weapon"] = { flags = ModFlag.Weapon },
	["with weapons"] = { flags = ModFlag.Weapon },
	["melee"] = { flags = ModFlag.Melee },
	["with melee attacks"] = { flags = ModFlag.Melee },
	["on melee hit"] = { flags = ModFlag.Melee },
	["with hits"] = { keywordFlags = KeywordFlag.Hit },
	["with hits and ailments"] = { keywordFlags = bor(KeywordFlag.Hit, KeywordFlag.Ailment) },
	["with poison"] = { keywordFlags = KeywordFlag.Poison },
	["with bleeding"] = { keywordFlags = KeywordFlag.Bleed },
	["area"] = { flags = ModFlag.Area },
	["mine"] = { keywordFlags = KeywordFlag.Mine },
	["with mines"] = { keywordFlags = KeywordFlag.Mine },
	["trap"] = { keywordFlags = KeywordFlag.Trap },
	["with traps"] = { keywordFlags = KeywordFlag.Trap },
	["for traps"] = { keywordFlags = KeywordFlag.Trap },
	["totem"] = { keywordFlags = KeywordFlag.Totem },
	["with totem skills"] = { keywordFlags = KeywordFlag.Totem },
	["for skills used by totems"] = { keywordFlags = KeywordFlag.Totem },
	["of aura skills"] = { tag = { type = "SkillType", skillType = SkillType.Aura } },
	["of curse skills"] = { keywordFlags = KeywordFlag.Curse },
	["of minion skills"] = { tag = { type = "SkillType", skillType = SkillType.Minion } },
	["for curses"] = { keywordFlags = KeywordFlag.Curse },
	["warcry"] = { keywordFlags = KeywordFlag.Warcry },
	["vaal"] = { keywordFlags = KeywordFlag.Vaal },
	["vaal skill"] = { keywordFlags = KeywordFlag.Vaal },
	["with movement skills"] = { keywordFlags = KeywordFlag.Movement },
	["with lightning skills"] = { keywordFlags = KeywordFlag.Lightning },
	["with cold skills"] = { keywordFlags = KeywordFlag.Cold },
	["with fire skills"] = { keywordFlags = KeywordFlag.Fire },
	["with elemental skills"] = { keywordFlags = bor(KeywordFlag.Lightning, KeywordFlag.Cold, KeywordFlag.Fire) },
	["with chaos skills"] = { keywordFlags = KeywordFlag.Chaos },
	["zombie"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie" } },
	["raised zombie"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie" } },
	["raised spectre"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre" } },
	["golem"] = { },
	["chaos golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem" } },
	["flame golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["increased flame golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["ice golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem" } },
	["lightning golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem" } },
	["stone golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem" } },
	["animated guardian"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Guardian" } },
	-- Other
	["global"] = { tag = { type = "Global" } },
	["from equipped shield"] = { tag = { type = "SlotName", slotName = "Weapon 2" } },
}

-- List of modifier flags/tags that appear at the start of a line
local preFlagList = {
	["^hits deal "] = { keywordFlags = KeywordFlag.Hit },
	["^critical strikes deal "] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["^minions "] = { addToMinion = true },
	["^minions [hd][ae][va][el] "] = { addToMinion = true },
	["^minions leech "] = { addToMinion = true },
	["^minions' attacks deal "] = { addToMinion = true, flags = ModFlag.Attack },
	["^golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillType", skillType = SkillType.Golem } },
	["^golem skills have "] = { tag = { type = "SkillType", skillType = SkillType.Golem } },
	["^zombies [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie" } },
	["^skeletons [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Skeletons" } },
	["^raging spirits [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Raging Spirit" } },
	["^spectres [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre" } },
	["^chaos golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem" } },
	["^flame golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["^ice golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem" } },
	["^lightning golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem" } },
	["^stone golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem" } },
	["^blink arrow and blink arrow clones [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Blink Arrow" } },
	["^mirror arrow and mirror arrow clones [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Mirror Arrow" } },
	["^animated weapons [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Weapon" } },
	["^animated guardians [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Guardian" } },
	["^attacks used by totems have "] = { keywordFlags = KeywordFlag.Totem },
	["^spells cast by totems have "] = { keywordFlags = KeywordFlag.Totem },
	["^attacks with this weapon "] = { tag = { type = "Condition", var = "XHandAttack" } },
	["^attacks with this weapon have "] = { tag = { type = "Condition", var = "XHandAttack" } },
	["^attacks have "] = { flags = ModFlag.Attack },
	["^melee attacks have "] = { flags = ModFlag.Melee },
	["^movement attack skills have "] = { flags = ModFlag.Attack, keywordFlags = KeywordFlag.Movement },
	["^trap and mine damage "] = { keywordFlags = bor(KeywordFlag.Trap, KeywordFlag.Mine) },
	["^left ring slot: "] = { tag = { type = "SlotNumber", num = 1 } },
	["^right ring slot: "] = { tag = { type = "SlotNumber", num = 2 } },
	["^socketed gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn" } },
	["^socketed curse gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", keyword = "curse" } },
	["^socketed melee gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", keyword = "melee" } },
	["^socketed golem gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", keyword = "golem" } },
	["^socketed golem skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", keyword = "golem" } },
	["^your flasks grant "] = { },
	["^when hit, "] = { },
	["^you and allies [hgd][ae][via][enl] "] = { },
	["^auras you cast grant "] = { addToAura = true },
	["^you and nearby allies [hgd][ae][via][enl] "] = { newAura = true },
	["^nearby allies [hgd][ae][via][enl] "] = { newAura = true, newAuraOnlyAllies = true },
	["^you and allies affected by your auras have "] = { affectedByAura = true },
	["^take "] = { modSuffix = "Taken" },
}

-- List of modifier tags
local modTagList = {
	["on enemies"] = { },
	["while active"] = { },
	[" on critical strike"] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["while affected by auras you cast"] = { affectedByAura = true },
	-- Multipliers
	["per power charge"] = { tag = { type = "Multiplier", var = "PowerCharge" } },
	["per frenzy charge"] = { tag = { type = "Multiplier", var = "FrenzyCharge" } },
	["per endurance charge"] = { tag = { type = "Multiplier", var = "EnduranceCharge" } },
	["per level"] = { tag = { type = "Multiplier", var = "Level" } },
	["for each normal item you have equipped"] = { tag = { type = "Multiplier", var = "NormalItem" } },
	["for each magic item you have equipped"] = { tag = { type = "Multiplier", var = "MagicItem" } },
	["for each rare item you have equipped"] = { tag = { type = "Multiplier", var = "RareItem" } },
	["for each unique item you have equipped"] = { tag = { type = "Multiplier", var = "UniqueItem" } },
	["per buff on you"] = { tag = { type = "Multiplier", var = "BuffOnSelf" } },
	["per curse on enemy"] = { tag = { type = "Multiplier", var = "CurseOnEnemy" } },
	["per curse on you"] = { tag = { type = "Multiplier", var = "CurseOnSelf" } },
	["to you and allies"] = { },
	-- Per stat
	["per (%d+) strength"] = function(num) return { tag = { type = "PerStat", stat = "Str", div = num } } end,
	["per (%d+) dexterity"] = function(num) return { tag = { type = "PerStat", stat = "Dex", div = num } } end,
	["per (%d+) intelligence"] = function(num) return { tag = { type = "PerStat", stat = "Int", div = num } } end,
	["per (%d+) evasion rating"] = function(num) return { tag = { type = "PerStat", stat = "Evasion", div = num } } end,
	["per (%d+) accuracy rating"] = function(num) return { tag = { type = "PerStat", stat = "Accuracy", div = num } } end,
	["per (%d+)%% block chance"] = function(num) return { tag = { type = "PerStat", stat = "BlockChance", div = num } } end,
	["per (%d+) of the lowest of armour and evasion rating"] = function(num) return { tag = { type = "PerStat", stat = "LowestOfArmourAndEvasion", div = num } } end,
	-- Stat conditions
	["with (%d+) or more strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["with at least (%d+) strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["with arrows that pierce"] = { flags = ModFlag.Bow, tag = { type = "StatThreshold", stat = "PierceCount", threshold = 1 } },
	-- Slot conditions
	["when in main hand"] = { tag = { type = "SlotNumber", num = 1 } },
	["when in off hand"] = { tag = { type = "SlotNumber", num = 2 } },
	["in main hand"] = { tag = { type = "InSlot", num = 1 } },
	["in off hand"] = { tag = { type = "InSlot", num = 2 } },
	["with main hand"] = { tag = { type = "Condition", var = "MainHandAttack" } },
	["with off hand"] = { tag = { type = "Condition", var = "OffHandAttack" } },
	["with this weapon"] = { tag = { type = "Condition", var = "XHandAttack" } }, -- The X is replaced when the item modifiers are generated
	-- Equipment conditions
	["while holding a shield"] = { tag = { type = "Condition", var = "UsingShield" } },
	["with shields"] = { tag = { type = "Condition", var = "UsingShield" } },
	["while dual wielding"] = { tag = { type = "Condition", var = "DualWielding" } },
	["while dual wielding claws"] = { tag = { type = "Condition", var = "DualWieldingClaws" } },
	["while dual wielding or holding a shield"] = { tag = { type = "Condition", varList = { "DualWielding", "UsingShield" } } },
	["while wielding a staff"] = { tag = { type = "Condition", var = "UsingStaff" } },
	["while unarmed"] = { tag = { type = "Condition", var = "Unarmed" } },
	["with a normal item equipped"] = { tag = { type = "Condition", var = "UsingNormalItem" } },
	["with a magic item equipped"] = { tag = { type = "Condition", var = "UsingMagicItem" } },
	["with a rare item equipped"] = { tag = { type = "Condition", var = "UsingRareItem" } },
	["with a unique item equipped"] = { tag = { type = "Condition", var = "UsingUniqueItem" } },
	["if you wear no corrupted items"] = { tag = { type = "Condition", var = "NotUsingCorruptedItem" } },
	["if no worn items are corrupted"] = { tag = { type = "Condition", var = "NotUsingCorruptedItem" } },
	["if all worn items are corrupted"] = { tag = { type = "Condition", var = "UsingAllCorruptedItems" } },
	-- Player status conditions
	["wh[ie][ln]e? on low life"] = { tag = { type = "Condition", var = "LowLife" } },
	["wh[ie][ln]e? not on low life"] = { tag = { type = "Condition", var = "LowLife", neg = true } },
	["wh[ie][ln]e? on full life"] = { tag = { type = "Condition", var = "FullLife" } },
	["wh[ie][ln]e? not on full life"] = { tag = { type = "Condition", var = "FullLife", neg = true } },
	["wh[ie][ln]e? no mana is reserved"] = { tag = { type = "Condition", var = "NoManaReserved" } },
	["wh[ie][ln]e? on full energy shield"] = { tag = { type = "Condition", var = "FullEnergyShield" } },
	["wh[ie][ln]e? not on full energy shield"] = { tag = { type = "Condition", var = "FullEnergyShield", neg = true } },
	["while stationary"] = { tag = { type = "Condition", var = "Stationary" } },
	["while you have no power charges"] = { tag = { type = "Condition", var = "HaveNoPowerCharges" } },
	["while you have no frenzy charges"] = { tag = { type = "Condition", var = "HaveNoFrenzyCharges" } },
	["while you have no endurance charges"] = { tag = { type = "Condition", var = "HaveNoEnduranceCharges" } },
	["while at maximum power charges"] = { tag = { type = "Condition", var = "AtMaxPowerCharges" } },
	["while at maximum frenzy charges"] = { tag = { type = "Condition", var = "AtMaxFrenzyCharges" } },
	["while at maximum endurance charges"] = { tag = { type = "Condition", var = "AtMaxEnduranceCharges" } },
	["while you have a totem"] = { tag = { type = "Condition", var = "HaveTotem" } },
	["while you have fortify"] = { tag = { type = "Condition", var = "Fortify" } },
	["during onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while you have onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while phasing"] = { tag = { type = "Condition", var = "Phasing" } },
	["while leeching"] = { tag = { type = "Condition", var = "Leeching" } },
	["while using a flask"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during flask effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["while on consecrated ground"] = { tag = { type = "Condition", var = "OnConsecratedGround" } },
	["on burning ground"] = { tag = { type = "Condition", var = "OnBurningGround" } },
	["on chilled ground"] = { tag = { type = "Condition", var = "OnChilledGround" } },
	["on shocked ground"] = { tag = { type = "Condition", var = "OnShockedGround" } },
	["while ignited"] = { tag = { type = "Condition", var = "Ignited" } },
	["while frozen"] = { tag = { type = "Condition", var = "Frozen" } },
	["while shocked"] = { tag = { type = "Condition", var = "Shocked" } },
	["while not ignited, frozen or shocked"] = { tag = { type = "Condition", varList = { "Ignited", "Frozen", "Shocked" }, neg = true } },
	["while cursed"] = { tag = { type = "Condition", var = "Cursed" } },
	["while not cursed"] = { tag = { type = "Condition", var = "Cursed", neg = true } },
	["if you[' ]h?a?ve hit recently"] = { tag = { type = "Condition", var = "HitRecently" } },
	["if you[' ]h?a?ve crit recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you[' ]h?a?ve dealt a critical strike recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you haven't crit recently"] = { tag = { type = "Condition", var = "CritRecently", neg = true } },
	["if you[' ]h?a?ve dealt a non%-critical strike recently"] = { tag = { type = "Condition", var = "NonCritRecently" } },
	["if you[' ]h?a?ve killed recently"] = { tag = { type = "Condition", var = "KilledRecently" } },
	["if you haven't killed recently"] = { tag = { type = "Condition", var = "KilledRecently", neg = true } },
	["if you or your totems have killed recently"] = { tag = { type = "Condition", varList = {"KilledRecently","TotemsKilledRecently"} } },
	["if you[' ]h?a?ve killed a maimed enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "EnemyCondition", var = "Maimed" } } },
	["if you[' ]h?a?ve killed a cursed enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "EnemyCondition", var = "Cursed" } } },
	["if you[' ]h?a?ve killed a bleeding enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "EnemyCondition", var = "Bleeding" } } },
	["if you[' ]h?a?ve killed an enemy affected by your damage over time recently"] = { tag = { type = "Condition", var = "KilledAffectedByDotRecently" } },
	["if you[' ]h?a?ve frozen an enemy recently"] = { tag = { type = "Condition", var = "FrozenEnemyRecently" } },
	["if you[' ]h?a?ve ignited an enemy recently"] = { tag = { type = "Condition", var = "IgnitedEnemyRecently" } },
	["if you[' ]h?a?ve been hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you were hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you were damaged by a hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you[' ]h?a?ve taken a critical strike recently"] = { tag = { type = "Condition", var = "BeenCritRecently" } },
	["if you[' ]h?a?ve taken a savage hit recently"] = { tag = { type = "Condition", var = "BeenSavageHitRecently" } },
	["if you have ?n[o']t been hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently", neg = true } },
	["if you[' ]h?a?ve taken no damage from hits recently"] = { tag = { type = "Condition", var = "BeenHitRecently", neg = true } },
	["if you[' ]h?a?ve blocked recently"] = { tag = { type = "Condition", varList = { "BlockedAttackRecently", "BlockedSpellRecently" } } },
	["if you[' ]h?a?ve blocked an attack recently"] = { tag = { type = "Condition", var = "BlockedAttackRecently" } },
	["if you[' ]h?a?ve blocked a spell recently"] = { tag = { type = "Condition", var = "BlockedSpellRecently" } },
	["if you[' ]h?a?ve blocked a hit from a unique enemy recently"] = { tag = { type = "Condition", var = "BlockedHitFromUniqueEnemyRecently" } },
	["if you[' ]h?a?ve attacked recently"] = { tag = { type = "Condition", var = "AttackedRecently" } },
	["if you[' ]h?a?ve cast a spell recently"] = { tag = { type = "Condition", var = "CastSpellRecently" } },
	["if you[' ]h?a?ve consumed a corpse recently"] = { tag = { type = "Condition", var = "ConsumedCorpseRecently" } },
	["if you[' ]h?a?ve taunted an enemy recently"] = { tag = { type = "Condition", var = "TauntedEnemyRecently" } },
	["if you[' ]h?a?ve used a warcry recently"] = { tag = { type = "Condition", var = "UsedWarcryRecently" } },
	["if you[' ]h?a?ve used a fire skill recently"] = { tag = { type = "Condition", var = "UsedFireSkillRecently" } },
	["if you[' ]h?a?ve used a cold skill recently"] = { tag = { type = "Condition", var = "UsedColdSkillRecently" } },
	["if you[' ]h?a?ve used a fire skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedFireSkillInPast10Sec" } },
	["if you[' ]h?a?ve used a cold skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedColdSkillInPast10Sec" } },
	["if you[' ]h?a?ve used a lightning skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedLightningSkillInPast10Sec" } },
	["if you[' ]h?a?ve summoned a totem recently"] = { tag = { type = "Condition", var = "SummonedTotemRecently" } },
	["if you[' ]h?a?ve used a movement skill recently"] = { tag = { type = "Condition", var = "UsedMovementSkillRecently" } },
	["if you detonated mines recently"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["if you[' ]h?a?ve crit in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if energy shield recharge has started recently"] = { tag = { type = "Condition", var = "EnergyShieldRechargeRecently" } },
	-- Enemy status conditions
	["at close range"] = { tag = { type = "Condition", var = "AtCloseRange" }, flags = ModFlag.Hit },
	["against rare and unique enemies"] = { tag = { type = "Condition", var = "EnemyRareOrUnique" }, keywordFlags = KeywordFlag.Hit },
	["against enemies on full life"] = { tag = { type = "EnemyCondition", var = "FullLife" }, keywordFlags = KeywordFlag.Hit },
	["against enemies that are on full life"] = { tag = { type = "EnemyCondition", var = "FullLife" }, keywordFlags = KeywordFlag.Hit },
	["against enemies on low life"] = { tag = { type = "EnemyCondition", var = "LowLife" }, keywordFlags = KeywordFlag.Hit },
	["against enemies that are on low life"] = { tag = { type = "EnemyCondition", var = "LowLife" }, keywordFlags = KeywordFlag.Hitt },
	["against cursed enemies"] = { tag = { type = "EnemyCondition", var = "Cursed" }, keywordFlags = KeywordFlag.Hit },
	["against taunted enemies"] = { tag = { type = "EnemyCondition", var = "Taunted" }, keywordFlags = KeywordFlag.Hit },
	["against bleeding enemies"] = { tag = { type = "EnemyCondition", var = "Bleeding" }, keywordFlags = KeywordFlag.Hit },
	["against poisoned enemies"] = { tag = { type = "EnemyCondition", var = "Poisoned" }, keywordFlags = KeywordFlag.Hit },
	["against hindered enemies"] = { tag = { type = "EnemyCondition", var = "Hindered" }, keywordFlags = KeywordFlag.Hit },
	["against blinded enemies"] = { tag = { type = "EnemyCondition", var = "Blinded" }, keywordFlags = KeywordFlag.Hit },
	["against burning enemies"] = { tag = { type = "EnemyCondition", var = "Burning" }, keywordFlags = KeywordFlag.Hit },
	["against ignited enemies"] = { tag = { type = "EnemyCondition", var = "Ignited" }, keywordFlags = KeywordFlag.Hit },
	["against shocked enemies"] = { tag = { type = "EnemyCondition", var = "Shocked" }, keywordFlags = KeywordFlag.Hit },
	["against frozen enemies"] = { tag = { type = "EnemyCondition", var = "Frozen" }, keywordFlags = KeywordFlag.Hit },
	["against chilled enemies"] = { tag = { type = "EnemyCondition", var = "Chilled" }, keywordFlags = KeywordFlag.Hit },
	["enemies which are chilled"] = { tag = { type = "EnemyCondition", var = "Chilled" }, keywordFlags = KeywordFlag.Hit },
	["against frozen, shocked or ignited enemies"] = { tag = { type = "EnemyCondition", varList = {"Frozen","Shocked","Ignited"} }, keywordFlags = KeywordFlag.Hit },
	["against enemies affected by elemental ailments"] = { tag = { type = "EnemyCondition", varList = {"Frozen","Chilled","Shocked","Ignited"} }, keywordFlags = KeywordFlag.Hit },
	["against enemies that are affected by elemental ailments"] = { tag = { type = "EnemyCondition", varList = {"Frozen","Chilled","Shocked","Ignited"} }, fkeywordFlags = KeywordFlag.Hit },
	["against enemies that are affected by no elemental ailments"] = { tagList = { { type = "EnemyCondition", varList = {"Frozen","Chilled","Shocked","Ignited"}, neg = true }, { type = "Condition", var = "Effective" } }, keywordFlags = KeywordFlag.Hit },
	["per freeze, shock and ignite on enemy"] = { tag = { type = "Multiplier", var = "FreezeShockIgniteOnEnemy" }, keywordFlags = KeywordFlag.Hit },
}

local mod = modLib.createMod
local function flag(name, ...)
	return mod(name, "FLAG", true, ...)
end

local gemNameLookup = { }
for name, grantedEffect in pairs(data["3_0"].skills) do
	if not grantedEffect.hidden then
		gemNameLookup[grantedEffect.name:lower()] = grantedEffect.name
	elseif grantedEffect.fromItem then
		gemNameLookup[grantedEffect.name:lower()] = grantedEffect.id
	end
end
local function extraSkill(name, level, noSupports)
	name = name:gsub(" skill","")
	if gemNameLookup[name] then
		return { 
			mod("ExtraSkill", "LIST", { name = gemNameLookup[name], level = level, noSupports = noSupports }) 
		}
	end
end

-- List of special modifiers
local specialModList = {
	-- Keystones
	["your hits can't be evaded"] = { flag("CannotBeEvaded") },
	["never deal critical strikes"] = { flag("NeverCrit") },
	["no critical strike multiplier"] = { flag("NoCritMultiplier") },
	["no damage multiplier for ailments from critical strikes"] = { flag("NoCritDegenMultiplier") },
	["the increase to physical damage from strength applies to projectile attacks as well as melee attacks"] = { flag("IronGrip") },
	["converts all evasion rating to armour%. dexterity provides no bonus to evasion rating"] = { flag("IronReflexes") },
	["30%% chance to dodge attacks%. 50%% less armour and energy shield, 30%% less chance to block spells and attacks"] = { 
		mod("AttackDodgeChance", "BASE", 30), 
		mod("Armour", "MORE", -50), 
		mod("EnergyShield", "MORE", -50), 
		mod("BlockChance", "MORE", -30),
		mod("SpellBlockChance", "MORE", -30) 
	},
	["maximum life becomes 1, immune to chaos damage"] = { flag("ChaosInoculation") },
	["life regeneration is applied to energy shield instead"] = { flag("ZealotsOath") },
	["gain life from leech instantly%. life regeneration has no effect%."] = { flag("InstantLifeLeech"), flag("NoLifeRegen") },
	["deal no non%-fire damage"] = { flag("DealNoPhysical"), flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoChaos") },
	["(%d+)%% of physical, cold and lightning damage converted to fire damage"] = function(num) return {
		mod("PhysicalDamageConvertToFire", "BASE", num), 
		mod("LightningDamageConvertToFire", "BASE", num),
		mod("ColdDamageConvertToFire", "BASE", num) 
	} end,
	["removes all mana%. spend life instead of mana for skills"] = { mod("Mana", "MORE", -100), flag("BloodMagic") },
	["enemies you hit with elemental damage temporarily get (%+%d+)%% resistance to those elements and (%-%d+)%% resistance to other elements"] = function(plus, _, minus)
		minus = tonumber(minus)
		return {
			flag("ElementalEquilibrium"),
			mod("EnemyModifier", "LIST", { mod = mod("FireResist", "BASE", plus, { type = "Condition", var = "HitByFireDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("FireResist", "BASE", minus, { type = "Condition", var = "HitByFireDamage", neg = true }, { type = "Condition", varList={"HitByColdDamage","HitByLightningDamage"} }) }),
			mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "BASE", plus, { type = "Condition", var = "HitByColdDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "BASE", minus, { type = "Condition", var = "HitByColdDamage", neg = true }, { type = "Condition", varList={"HitByFireDamage","HitByLightningDamage"} }) }),
			mod("EnemyModifier", "LIST", { mod = mod("LightningResist", "BASE", plus, { type = "Condition", var = "HitByLightningDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("LightningResist", "BASE", minus, { type = "Condition", var = "HitByLightningDamage", neg = true }, { type = "Condition", varList={"HitByFireDamage","HitByColdDamage"} }) }),
		}
	end,
	["projectile attacks deal up to 50%% more damage to targets at the start of their movement, dealing less damage to targets as the projectile travels farther"] = { flag("PointBlank") },
	["life leech is applied to energy shield instead"] = { flag("GhostReaver") },
	["minions explode when reduced to low life, dealing 33%% of their maximum life as fire damage to surrounding enemies"] = { flag("MinionInstability") },
	["all bonuses from an equipped shield apply to your minions instead of you"] = { }, -- The node itself is detected by the code that handles it
	["spend energy shield before mana for skill costs"] = { },
	["energy shield protects mana instead of life"] = { flag("EnergyShieldProtectsMana") },
	["modifiers to critical strike multiplier also apply to damage multiplier for ailments from critical strikes at (%d+)%% of their value"] = function(num) return { mod("CritMultiplierAppliesToDegen", "BASE", num) } end,
	-- Ascendancy notables
	["can allocate passives from the %a+'s starting point"] = { },
	["movement skills cost no mana"] = { mod("ManaCost", "MORE", -100, nil, 0, KeywordFlag.Movement) },
	["projectiles pierce all nearby targets"] = { flag("PierceAllTargets") },
	["always poison on hit while using a flask"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["armour received from body armour is doubled"] = { flag("Unbreakable") },
	["you have fortify"] = { flag("Condition:Fortify") },
	["(%d+)%% increased damage of each damage type for which you have a matching golem"] = function(num) return {
		mod("PhysicalDamage", "INC", num, { type = "Condition", var = "HavePhysicalGolem"}), 
		mod("LightningDamage", "INC", num, { type = "Condition", var = "HaveLightningGolem"}), 
		mod("ColdDamage", "INC", num, { type = "Condition", var = "HaveColdGolem"}), 
		mod("FireDamage", "INC", num, { type = "Condition", var = "HaveFireGolem"}), 
		mod("ChaosDamage", "INC", num, { type = "Condition", var = "HaveChaosGolem"}) 
	} end,
	["(%d+)%% increased effect of buffs granted by your elemental golems"] = function(num) return { 
		mod("BuffEffect", "INC", num, { type = "SkillType", skillType = SkillType.Golem }, { type = "SkillType", skillType = SkillType.FireSkill }),
		mod("BuffEffect", "INC", num, { type = "SkillType", skillType = SkillType.Golem }, { type = "SkillType", skillType = SkillType.ColdSkill }),
		mod("BuffEffect", "INC", num, { type = "SkillType", skillType = SkillType.Golem }, { type = "SkillType", skillType = SkillType.LightningSkill }),
	} end,
	["every 10 seconds, gain (%d+)%% increased elemental damage for 4 seconds"] = function(num) return { mod("ElementalDamage", "INC", num, { type = "Condition", var = "PendulumOfDestruction" }) } end,
	["every 10 seconds, gain (%d+)%% increased area of effect of area skills for 4 seconds"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "Condition", var = "PendulumOfDestruction" }) } end,
	["enemies you curse take (%d+)%% increased damage"] = function(num) return { mod("AffectedByCurseMod", "LIST", { mod = mod("DamageTaken", "INC", num) }) } end,
	["enemies you curse have (%-%d+)%% to chaos resistance"] = function(num) return { mod("AffectedByCurseMod", "LIST", { mod = mod("ChaosResist", "BASE", num) }) } end,
	["nearby enemies have (%-%d+)%% to chaos resistance"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("ChaosResist", "BASE", num) }) } end,
	["nearby enemies take (%d+)%% increased elemental damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("ElementalDamageTaken", "INC", num) }) } end,
	["enemies near your totems take (%d+)%% increased physical and fire damage"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("PhysicalDamageTaken", "INC", num) }), 
		mod("EnemyModifier", "LIST", { mod = mod("FireDamageTaken", "INC", num) }) 
	} end,
	["grants armour equal to (%d+)%% of your reserved life to you and nearby allies"] = function(num) return { mod("GrantReservedLifeAsAura", "LIST", { mod = mod("Armour", "BASE", num / 100) }) } end,
	["grants maximum energy shield equal to (%d+)%% of your reserved mana to you and nearby allies"] = function(num) return { mod("GrantReservedManaAsAura", "LIST", { mod = mod("EnergyShield", "BASE", num / 100) }) } end,
	["skills from your helmet penetrate (%d+)%% elemental resistances"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ElementalPenetration", "BASE", num) }, { type = "SocketedIn", slotName = "Helmet" }) } end,
	["skills from your gloves have (%d+)%% increased area of effect"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("AreaOfEffect", "INC", num) }, { type = "SocketedIn", slotName = "Gloves" }) } end,
	["skills from your boots leech (%d+)%% of damage as life"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("DamageLifeLeech", "BASE", num) }, { type = "SocketedIn", slotName = "Boots" }) } end,
	["skills in your helm can have up to (%d+) additional totems? summoned at a time"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ActiveTotemLimit", "BASE", num) }, { type = "SocketedIn", slotName = "Helmet" }) } end,
	["(%d+)%% less totem damage per totem"] = function(num) return { mod("Damage", "MORE", -num, nil, 0, KeywordFlag.Totem, { type = "PerStat", stat = "ActiveTotemLimit", div = 1 }) } end,
	["poison you inflict with critical strikes deals (%d+)%% more damage"] = function(num) return { mod("Damage", "MORE", num, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "CriticalStrike" }) } end,
	["bleeding you inflict on maimed enemies deals (%d+)%% more damage"] = function(num) return { mod("Damage", "MORE", num, nil, 0, KeywordFlag.Bleed, { type = "EnemyCondition", var = "Maimed"}) } end,
	["critical strikes ignore enemy monster elemental resistances"] = { flag("IgnoreElementalResistances", { type = "Condition", var = "CriticalStrike" }) },
	["non%-critical strikes penetrate (%d+)%% of enemy elemental resistances"] = function(num) return { mod("ElementalPenetration", "BASE", num, { type = "Condition", var = "CriticalStrike", neg = true }) } end,
	["movement speed cannot be modified to below base value"] = { flag("MovementSpeedCannotBeBelowBase") },
	["your offering skills also affect you"] = { mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "buffNotPlayer", value = false }) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } }) },
	["consecrated ground you create grants (%d+)%% increased damage to you and allies"] = function(num) return { mod("Damage", "INC", num, { type = "Condition", var = "OnConsecratedGround" }) } end,
	["for each element you've been hit by damage of recently, (%d+)%% increased damage of that element"] = function(num) return { 
		mod("FireDamage", "INC", num, { type = "Condition", var = "HitByFireDamageRecently" }),
		mod("ColdDamage", "INC", num, { type = "Condition", var = "HitByColdDamageRecently" }),
		mod("LightningDamage", "INC", num, { type = "Condition", var = "HitByLightningDamageRecently" })
	} end,
	["for each element you've been hit by damage of recently, (%d+)%% reduced damage taken of that element"] = function(num) return { 
		mod("FireDamageTaken", "INC", -num, { type = "Condition", var = "HitByFireDamageRecently" }), 
		mod("ColdDamageTaken", "INC", -num, { type = "Condition", var = "HitByColdDamageRecently" }), 
		mod("LightningDamageTaken", "INC", -num, { type = "Condition", var = "HitByLightningDamageRecently" })
	} end,
	["when you kill an enemy, for each curse on that enemy, gain (%d+)%% of non%-chaos damage as extra chaos damage for 4 seconds"] = function(num) return { 
		mod("PhysicalDamageGainAsChaos", "BASE", num, { type = "Condition", var = "KilledRecently" }, { type = "Multiplier", var = "CurseOnEnemy" }), 
		mod("ElementalDamageGainAsChaos", "BASE", num, { type = "Condition", var = "KilledRecently" }, { type = "Multiplier", var = "CurseOnEnemy" }), 
	} end,
	["warcries cost no mana"] = { mod("ManaCost", "MORE", -100, nil, 0, KeywordFlag.Warcry) },
	["enemies you taunt take (%d+)%% increased damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Condition", var = "Taunted" }) }) } end,
	["you have phasing while at maximum frenzy charges"] = { flag("Condition:Phasing", { type = "Condition", var = "AtMaxFrenzyCharges" }) },
	["you have phasing while you have onslaught"] = { flag("Condition:Phasing", { type = "Condition", var = "Onlaught" }) },
	["you have onslaught while on full frenzy charges"] = { flag("Condition:Phasing", { type = "Condition", var = "AtMaxFrenzyCharges" }) },
	["your minions spread caustic cloud on death, dealing 10%% of their maximum life as chaos damage per second"] = { flag("MinionCausticCloudOnDeath") },
	["you and your minions have (%d+)%% physical damage reduction"] = function(num) return { mod("PhysicalDamageReduction", "BASE", num), mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageReduction", "BASE", num) }) } end,
	["every %d+ seconds:"] = { },
	["gain chilling conflux for %d seconds"] = { },
	["gain shocking conflux for %d seconds"] = { },
	["gain igniting conflux for %d seconds"] = { },
	["gain chilling, shocking and igniting conflux for %d seconds"] = { },
	["(%d+)%% additional block chance for %d second every %d seconds"] = function(num) return { mod("BlockChance", "BASE", num, { type = "Condition", var = "BastionOfHope" }) } end,
	-- Item local modifiers
	["has no sockets"] = { },
	["has 1 socket"] = { },
	["no physical damage"] = { mod("WeaponData", "LIST", { key = "PhysicalMin" }), mod("WeaponData", "LIST", { key = "PhysicalMax" }), mod("WeaponData", "LIST", { key = "PhysicalDPS" }) },
	["all attacks with this weapon are critical strikes"] = { mod("WeaponData", "LIST", { key = "CritChance", value = 100 }) },
	["counts as dual wielding"] = { mod("WeaponData", "LIST", { key = "countsAsDualWielding", value = true}) },
	["counts as all one handed melee weapon types"] = { mod("WeaponData", "LIST", { key = "countsAsAll1H", value = true }) },
	["no block chance"] = { mod("ArmourData", "LIST", { key = "BlockChance", value = 0 }) },
	["hits can't be evaded"] = { flag("CannotBeEvaded", { type = "Condition", var = "XHandAttack" }) },
	["causes bleeding on hit"] = { mod("BleedChance", "BASE", 100, { type = "Condition", var = "XHandAttack" }) },
	["poisonous hit"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "XHandAttack" }) },
	["attacks with this weapon deal double damage to chilled enemies"] = { mod("Damage", "MORE", 100, nil, ModFlag.Hit, { type = "Condition", var = "XHandAttack" }, { type = "EnemyCondition", var = "Chilled" }) },
	["life leech from hits with this weapon applies instantly"] = { flag("InstantLifeLeech", { type = "Condition", var = "XHandAttack" }) },
	["gain life from leech instantly from hits with this weapon"] = { flag("InstantLifeLeech", { type = "Condition", var = "XHandAttack" }) },
	["instant recovery"] = {  mod("FlaskInstantRecovery", "BASE", 100) },
	["(%d+)%% of recovery applied instantly"] = function(num) return { mod("FlaskInstantRecovery", "BASE", num) } end,
	-- Socketed gem modifiers
	["%+(%d+) to level of socketed gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "all", key = "level", value = num }, { type = "SocketedIn" }) } end,
	["%+(%d+) to level of socketed (%a+) gems"] = function(num, _, type) return { mod("GemProperty", "LIST", { keyword = type, key = "level", value = num }, { type = "SocketedIn" }) } end,
	["%+(%d+)%% to quality of socketed (%a+) gems"] = function(num, _, type) return { mod("GemProperty", "LIST", { keyword = type, key = "quality", value = num }, { type = "SocketedIn" }) } end,
	["%+(%d+) to level of active socketed skill gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "active_skill", key = "level", value = num }, { type = "SocketedIn" }) } end,
	["socketed gems fire an additional projectile"] = { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", 1) }, { type = "SocketedIn" }) },
	["socketed gems fire (%d+) additional projectiles"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SocketedIn" }) } end,
	["socketed gems reserve no mana"] = { mod("ManaReserved", "MORE", -100, { type = "SocketedIn" }) },
	["socketed skill gems get a (%d+)%% mana multiplier"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ManaCost", "MORE", num - 100) }, { type = "SocketedIn" }) } end,
	["socketed gems have blood magic"] = { flag("SkillBloodMagic", { type = "SocketedIn" }) },
	["socketed gems gain (%d+)%% of physical damage as extra lightning damage"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("PhysicalDamageGainAsLightning", "BASE", num) }, { type = "SocketedIn" }) } end,
	["socketed red gems get (%d+)%% physical damage as extra fire damage"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("PhysicalDamageGainAsFire", "BASE", num) }, { type = "SocketedIn", keyword = "strength" }) } end,
	-- Extra skill/support
	["grants level (%d+) (.+)"] = function(num, _, skill) return extraSkill(skill, num) end,
	["casts level (%d+) (.+) when equipped"] = function(num, _, skill) return extraSkill(skill, num) end,
	["casts level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num) end,
	["use level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num) end,
	["cast level (%d+) (.+) when you deal a critical strike"] = function(num, _, skill) return extraSkill(skill, num) end,
	["cast level (%d+) (.+) when hit"] = function(num, _, skill) return extraSkill(skill, num) end,
	["cast level (%d+) (.+) when you kill an enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to attack with level (%d+) (.+) on melee hit"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to cast level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num) end,
	["attack with level (%d+) (.+) when you kill a bleeding enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["curse enemies with (%D+) on %a+"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["curse enemies with level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num, true) end,
	["cast (.+) on %a+"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["attack with (.+) on %a+"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["cast (.+) when hit"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["attack with (.+) when hit"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["cast (.+) when your skills or minions kill"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["attack with (.+) when you take a critical strike"] = function( _, skill) return extraSkill(skill, 1, true) end,
	["socketed [%a+]* ?gems a?r?e? ?supported by level (%d+) (.+)"] = function(num, _, support) return { mod("ExtraSupport", "LIST", { name = gemNameLookup[support] or gemNameLookup[support:gsub("^increased ","")] or "Unknown", level = num }, { type = "SocketedIn" }) } end,
	-- Conversion
	["increases and reductions to minion damage also affects? you"] = { flag("MinionDamageAppliesToPlayer") },
	["increases and reductions to spell damage also apply to attacks"] = { flag("SpellDamageAppliesToAttacks") },
	["modifiers to claw damage also apply to unarmed"] = { flag("ClawDamageAppliesToUnarmed") },
	["modifiers to claw attack speed also apply to unarmed"] = { flag("ClawAttackSpeedAppliesToUnarmed") },
	["modifiers to claw critical strike chance also apply to unarmed"] = { flag("ClawCritChanceAppliesToUnarmed") },
	["gain (%d+)%% of bow physical damage as extra damage of each element"] = function(num) return { mod("PhysicalDamageGainAsLightning", "BASE", num, nil, ModFlag.Bow), mod("PhysicalDamageGainAsCold", "BASE", num, nil, ModFlag.Bow), mod("PhysicalDamageGainAsFire", "BASE", num, nil, ModFlag.Bow) } end,
	-- Crit
	["your critical strike chance is lucky"] = { flag("CritChanceLucky") },
	["your critical strikes do not deal extra damage"] = { flag("NoCritMultiplier") },
	["critical strikes deal no damage"] = { mod("Damage", "MORE", -100, { type = "Condition", var = "CriticalStrike" }) },
	["critical strike chance is increased by uncapped lightning resistance"] = { mod("CritChance", "INC", 1, { type = "PerStat", stat = "LightningResistTotal", div = 1 }) },
	["non%-critical strikes deal (%d+)%% damage"] = function(num) return { mod("Damage", "MORE", -100+num, nil, ModFlag.Hit, { type = "Condition", var = "CriticalStrike", neg = true }) } end,
	-- Elemental Ailments
	["your cold damage can ignite"] = { flag("ColdCanIgnite") },
	["your fire damage can shock but not ignite"] = { flag("FireCanShock"), flag("FireCannotIgnite") },
	["your cold damage can ignite but not freeze or chill"] = { flag("ColdCanIgnite"), flag("ColdCannotFreeze"), flag("ColdCannotChill") },
	["your lightning damage can freeze but not shock"] = { flag("LightningCanFreeze"), flag("LightningCannotShock") },
	["your chaos damage can shock"] = { flag("ChaosCanShock") },
	["your physical damage can chill"] = { flag("PhysicalCanChill") },
	["your physical damage can shock"] = { flag("PhysicalCanShock") },
	["you always ignite while burning"] = { mod("EnemyIgniteChance", "BASE", 100, { type = "Condition", var = "Burning" }) },
	["critical strikes do not always freeze"] = { flag("CritsDontAlwaysFreeze") },
	["you can inflict up to (%d+) ignites on an enemy"] = { flag("IgniteCanStack") },
	["enemies chilled by you take (%d+)%% increased burning damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("FireDamageTakenOverTime", "INC", num) }, { type = "EnemyCondition", var = "Chilled" }) } end,
	["ignited enemies burn (%d+)%% faster"] = function(num) return { mod("IgniteBurnRate", "INC", num) } end,
	["enemies ignited by an attack burn (%d+)%% faster"] = function(num) return { mod("IgniteBurnRate", "INC", num, nil, ModFlag.Attack) } end,
	-- Bleed
	["melee attacks cause bleeding"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Melee) },
	["attacks cause bleeding when hitting cursed enemies"] = { mod("BleedChance", "BASE", 100, { type = "EnemyCondition", var = "Cursed" }) },
	["melee critical strikes cause bleeding"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) },
	["causes bleeding on melee critical strike"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) },
	["melee critical strikes have (%d+)%% chance to cause bleeding"] = function(num) return { mod("BleedChance", "BASE", num, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) } end,
	-- Poison
	["your chaos damage poisons enemies"] = { mod("ChaosPoisonChance", "BASE", 100) },
	["your chaos damage has (%d+)%% chance to poison enemies"] = function(num) return { mod("ChaosPoisonChance", "BASE", num) } end,
	["melee attacks poison on hit"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Melee) },
	["melee critical strikes have (%d+)%% chance to poison the enemy"] = function(num) return { mod("PoisonChance", "BASE", num, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) } end,
	["critical strikes with daggers have a (%d+)%% chance to poison the enemy"] = function(num) return { mod("PoisonChance", "BASE", num, nil, ModFlag.Dagger, { type = "Condition", var = "CriticalStrike" }) } end,
	["poison cursed enemies on hit"] = { mod("PoisonChance", "BASE", 100, { type = "EnemyCondition", var = "Cursed" }) },
	["wh[ie][ln]e? at maximum frenzy charges, attacks poison enemies"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Attack, { type = "Condition", var = "AtMaxFrenzyCharges" }) },
	["traps and mines have a (%d+)%% chance to poison on hit"] = function(num) return { mod("PoisonChance", "BASE", num, nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	-- Buffs/debuffs
	["phasing"] = { flag("Condition:Phasing") },
	["onslaught"] = { flag("Condition:Onslaught") },
	["you have phasing if you've killed recently"] = { flag("Condition:Phasing", { type = "Condition", var = "KilledRecently" }) },
	["your aura buffs do not affect allies"] = { flag("SelfAurasCannotAffectAllies") },
	["allies' aura buffs do not affect you"] = { flag("AlliesAurasCannotAffectSelf") },
	["enemies can have 1 additional curse"] = { mod("EnemyCurseLimit", "BASE", 1) },
	["nearby enemies have (%d+)%% increased effect of curses on them"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("CurseEffectOnSelf", "INC", num) }) } end,
	["your hits inflict decay, dealing (%d+) chaos damage per second for %d+ seconds"] = function(num) return { mod("SkillData", "LIST", { key = "decay", value = num, merge = "MAX" }) } end,
	-- Traps, Mines and Totems
	["traps and mines deal (%d+)%-(%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["traps and mines deal (%d+) to (%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["can have up to (%d+) additional traps? placed at a time"] = function(num) return { mod("ActiveTrapLimit", "BASE", num) } end,
	["can have up to (%d+) additional remote mines? placed at a time"] = function(num) return { mod("ActiveMineLimit", "BASE", num) } end,
	["can have up to (%d+) additional totems? summoned at a time"] = function(num) return { mod("ActiveTotemLimit", "BASE", num) } end,
	["attack skills can have (%d+) additional totems? summoned at a time"] = function(num) return { mod("ActiveTotemLimit", "BASE", num, nil, 0, KeywordFlag.Attack) } end,
	["can [hs][au][vm][em]o?n? 1 additional siege ballista totem per (%d+) dexterity"] = function(num) return { mod("ActiveTotemLimit", "BASE", 1, { type = "SkillName", skillName = "Siege Ballista" }, { type = "PerStat", stat = "Dex", div = num }) } end,
	["totems fire (%d+) additional projectiles"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, 0, KeywordFlag.Totem) } end,
	["([%d%.]+)%% of damage dealt by y?o?u?r? ?totems is leeched to you as life"] = function(num) return { mod("DamageLifeLeechToPlayer", "BASE", num, nil, 0, KeywordFlag.Totem) } end,
	-- Minions
	["your strength is added to your minions"] = { flag("StrengthAddedToMinions") },
	["minions poison enemies on hit"] = { mod("MinionModifier", "LIST", { mod = mod("PoisonChance", "BASE", 100) }) },
	["minions have (%d+)%% chance to poison enemies on hit"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PoisonChance", "BASE", num) }) } end,
	["(%d+)%% increased minion damage if you have hit recently"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "Condition", var = "HitRecently" }) } end,
	["(%d+)%% increased minion attack speed per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", num, nil, ModFlag.Attack) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["(%d+)%% increased minion movement speed per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "INC", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["minions deal (%d+)%% increased damage per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["(%d+)%% increased golem damage for each type of golem you have summoned"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ParentCondition", var = "HavePhysicalGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ParentCondition", var = "HaveLightningGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ParentCondition", var = "HaveColdGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ParentCondition", var = "HaveFireGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ParentCondition", var = "HaveChaosGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
	} end,
	["can summon up to (%d) additional golems? at a time"] = function(num) return { mod("ActiveGolemLimit", "BASE", num) } end,
	["if you have 3 primordial jewels, can summon up to (%d) additional golems? at a time"] = function(num) return { mod("ActiveGolemLimit", "BASE", num, { type = "MultiplierThreshold", var = "PrimordialJewel", threshold = 3 }) } end,
	["golems regenerate (%d)%% of their maximum life per second"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "SkillType", skillType = SkillType.Golem }) } end,
	-- Projectiles
	["skills chain %+(%d) times"] = function(num) return { mod("ChainCount", "BASE", num) } end,
	["skills chain an additional time while at maximum frenzy charges"] = { mod("ChainCount", "BASE", 1, { type = "Condition", var = "AtMaxFrenzyCharges" }) },
	["adds an additional arrow"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack) },
	["(%d+) additional arrows"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, ModFlag.Attack) } end,
	["skills fire an additional projectile"] = { mod("ProjectileCount", "BASE", 1) },
	["spells have an additional projectile"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Spell) },
	["projectiles pierce an additional target"] = { mod("PierceCount", "BASE", 1) },
	["projectiles pierce (%d+) targets?"] = function(num) return { mod("PierceCount", "BASE", num) } end,
	["projectiles pierce (%d+) additional targets while you have phasing"] = function(num) return { mod("PierceCount", "BASE", num, { type = "Condition", var = "Phasing" }) } end,
	["arrows pierce one target"] = { mod("PierceCount", "BASE", 1, nil, ModFlag.Attack) },
	["arrows pierce (%d+) targets?"] = function(num) return { mod("PierceCount", "BASE", num, nil, ModFlag.Attack) } end,
	["arrows always pierce"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows pierce all targets"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows that pierce cause bleeding"] = { flag("ArrowsThatPierceCauseBleeding") },
	["arrows deal (%d+)%% increased damage to targets they pierce"] = function(num) return { mod("Damage", "INC", num, nil, ModFlag.Attack, { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) } end,
	["arrows deal (%d+)%% increased damage against pierced targets"] = function(num) return { mod("Damage", "INC", num, nil, ModFlag.Attack, { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) } end,
	-- Leech
	["cannot leech life"] = { flag("CannotLeechLife") },
	["cannot leech mana"] = { flag("CannotLeechMana") },
	["cannot leech when on low life"] = { flag("CannotLeechLife", { type = "Condition", var = "LowLife" }), flag("CannotLeechMana", { type = "Condition", var = "LowLife" }) },
	["cannot leech life from critical strikes"] = { flag("CannotLeechLife", { type = "Condition", var = "CriticalStrike" }) },
	["leech applies instantly on critical strike"] = { flag("InstantLifeLeech", { type = "Condition", var = "CriticalStrike" }), flag("InstantManaLeech", { type = "Condition", var = "CriticalStrike" }) },
	["gain life and mana from Leech instantly on critical strike"] = { flag("InstantLifeLeech", { type = "Condition", var = "CriticalStrike" }), flag("InstantManaLeech", { type = "Condition", var = "CriticalStrike" }) },
	["leech applies instantly during flask effect"] = { flag("InstantLifeLeech", { type = "Condition", var = "UsingFlask" }), flag("InstantManaLeech", { type = "Condition", var = "UsingFlask" }) },
	["with 5 corrupted items equipped: life leech recovers based on your chaos damage instead"] = { flag("LifeLeechBasedOnChaosDamage", { type = "MultiplierThreshold", var = "CorruptedItem", threshold = 5 }) },
	-- Defences
	["cannot evade enemy attacks"] = { flag("CannotEvade") },
	["cannot block attacks"] = { flag("CannotBlockAttacks") },
	["you have no life regeneration"] = { flag("NoLifeRegen") },
	["you cannot be shocked while at maximum endurance charges"] = { mod("AvoidShock", "BASE", 100, { type = "Condition", var = "AtMaxEnduranceCharges" }) },
	["armour is increased by uncapped fire resistance"] = { mod("Armour", "INC", 1, { type = "PerStat", stat = "FireResistTotal", div = 1 }) },
	["evasion rating is increased by uncapped cold resistance"] = { mod("Evasion", "INC", 1, { type = "PerStat", stat = "ColdResistTotal", div = 1 }) },
	["reflects (%d+) physical damage to melee attackers"] = { },
	["ignore all movement penalties from armour"] = { flag("Condition:IgnoreMovementPenalties") },
	["cannot be stunned"] = { mod("AvoidStun", "BASE", 100) },
	["cannot be shocked"] = { mod("AvoidShock", "BASE", 100) },
	["cannot be frozen"] = { mod("AvoidFreeze", "BASE", 100) },
	["cannot be chilled"] = { mod("AvoidChill", "BASE", 100) },
	["cannot be ignited"] = { mod("AvoidIgnite", "BASE", 100) },
	["you are immune to bleeding"] = { mod("AvoidBleed", "BASE", 100) },
	["immunity to shock during flask effect"] = { mod("AvoidShock", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immunity to freeze and chill during flask effect"] = { mod("AvoidFreeze", "BASE", 100, { type = "Condition", var = "UsingFlask" }), mod("AvoidChill", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immunity to ignite during flask effect"] = { mod("AvoidIgnite", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immunity to bleeding during flask effect"] = { mod("AvoidBleed", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immune to poison during flask effect"] = { mod("AvoidPoison", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immune to curses during flask effect"] = { mod("AvoidCurse", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	-- Knockback
	["cannot knock enemies back"] = { flag("CannotKnockback") },
	["knocks back enemies if you get a critical strike with a staff"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Staff, { type = "Condition", var = "CriticalStrike" }) },
	["knocks back enemies if you get a critical strike with a bow"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Bow, { type = "Condition", var = "CriticalStrike" }) },
	["bow knockback at close range"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Bow, { type = "Condition", var = "AtCloseRange" }) },
	["adds knockback during flask effect"] = { mod("EnemyKnockbackChance", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["adds knockback to melee attacks during flask effect"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Melee, { type = "Condition", var = "UsingFlask" }) },
	-- Flasks
	["flasks do not apply to you"] = { flag("FlasksDoNotApplyToPlayer") },
	["flasks apply to your zombies and spectres"] = { flag("FlasksApplyToMinion", { type = "SkillName", skillNameList = { "Raise Zombie", "Raise Spectre" } }) },
	["creates a smoke cloud on use"] = { },
	["creates chilled ground on use"] = { },
	["creates consecrated ground on use"] = { },
	["gain unholy might during flask effect"] = { flag("Condition:UnholyMight", { type = "Condition", var = "UsingFlask" }) },
	["zealot's oath during flask effect"] = { mod("ZealotsOath", "FLAG", true, { type = "Condition", var = "UsingFlask" }) },
	["grants level (%d+) (.+) curse aura during flask effect"] = function(num, _, skill) return { mod("ExtraCurse", "LIST", { name = gemNameLookup[skill:gsub(" skill","")] or "Unknown", level = num }, { type = "Condition", var = "UsingFlask" }) } end,
	["during flask effect, (%d+)%% reduced damage taken of each element for which your uncapped elemental resistance is lowest"] = function(num) return {
		mod("LightningDamageTaken", "INC", -num, { type = "Condition", var = "UncappedLightningResistIsLowest" }),
		mod("ColdDamageTaken", "INC", -num, { type = "Condition", var = "UncappedColdResistIsLowest" }),
		mod("FireDamageTaken", "INC", -num, { type = "Condition", var = "UncappedFireResistIsLowest" }),
	} end,
	["during flask effect, damage penetrates (%d+)%% o?f? ?resistance of each element for which your uncapped elemental resistance is highest"] = function(num) return {
		mod("LightningPenetration", "BASE", num, { type = "Condition", var = "UncappedLightningResistIsHighest" }),
		mod("ColdPenetration", "BASE", num, { type = "Condition", var = "UncappedColdResistIsHighest" }),
		mod("FirePenetration", "BASE", num, { type = "Condition", var = "UncappedFireResistIsHighest" }),
	} end,
	["(%d+)%% of maximum life taken as chaos damage per second"] = function(num) return { mod("ChaosDegen", "BASE", num/100, { type = "PerStat", stat = "Life", div = 1 }) } end,
	-- Jewels
	["passives in radius can be allocated without being connected to your tree"] = { mod("JewelData", "LIST", { key = "intuitiveLeap", value = true }) },
	["(%d+)%% increased elemental damage per grand spectrum"] = function(num) return { 
		mod("ElementalDamage", "INC", num, { type = "Multiplier", var = "GrandSpectrum" }), 
		mod("Multiplier:GrandSpectrum", "BASE", 1) 
	} end,
	["gain (%d+) armour per grand spectrum"] = function(num) return { 
		mod("Armour", "BASE", num, { type = "Multiplier", var = "GrandSpectrum" }), 
		mod("Multiplier:GrandSpectrum", "BASE", 1) 
	} end,
	["gain (%d+) mana per grand spectrum"] = function(num) return {
		mod("Mana", "BASE", num, { type = "Multiplier", var = "GrandSpectrum" }),
		mod("Multiplier:GrandSpectrum", "BASE", 1) 
	} end,
	["primordial"] = { mod("Multiplier:PrimordialJewel", "BASE", 1) },
	-- Misc
	["iron will"] = { flag("IronWill") },
	["deal no physical damage"] = { flag("DealNoPhysical") },
	["deal no elemental damage"] = { flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoFire") },
	["attacks have blood magic"] = { flag("SkillBloodMagic", nil, ModFlag.Attack) },
	["(%d+)%% chance to cast a? ?socketed lightning spells? on hit"] = function(num) return { mod("ExtraSupport", "LIST", { name = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn" }) } end,
	["cast a socketed lightning spell on hit"] = { mod("ExtraSupport", "LIST", { name = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn" }) },
	["cast a socketed cold s[pk][ei]ll on melee critical strike"] = { mod("ExtraSupport", "LIST", { name = "SupportUniqueCosprisMaliceColdSpellsCastOnMeleeCriticalStrike", level = 1 }, { type = "SocketedIn" }) },
	["your curses can apply to hexproof enemies"] = { flag("CursesIgnoreHexproof") },
	["you have onslaught while you have fortify"] = { flag("Condition:Onslaught", { type = "Condition", var = "Fortify" }) },
	["reserves (%d+)%% of life"] = function(num) return { mod("ExtraLifeReserved", "BASE", num) } end,
	["items and gems have (%d+)%% reduced attribute requirements"] = function(num) return { mod("GlobalAttributeRequirements", "INC", -num) } end,
	-- Skill-specific enchantment modifiers
	["(%d+)%% increased decoy totem life"] = function(num) return { mod("TotemLife", "INC", num, { type = "SkillName", skillName = "Decoy Totem" }) } end,
	["(%d+)%% increased ice spear critical strike chance in second form"] = function(num) return { mod("CritChance", "INC", num, { type = "SkillName", skillName = "Ice Spear" }, { type = "SkillPart", skillPart = 2 }) } end,
	["(%d+)%% increased incinerate damage for each stage"] = function(num) return { mod("Damage", "INC", num * 3, { type = "SkillName", skillName = "Incinerate" }, { type = "SkillPart", skillPart = 2 }) } end,
	["shock nova ring deals (%d+)%% increased damage"] = function(num) return { mod("Damage", "INC", num, { type = "SkillName", skillName = "Shock Nova" }, { type = "SkillPart", skillPart = 1 }) } end,
	-- Display-only modifiers
	["prefixes:"] = { },
	["suffixes:"] = { },
	["socketed lightning spells have (%d+)%% increased spell damage if triggered"] = { },
	["manifest dancing dervish disables both weapon slots"] = { },
	["manifest dancing dervish dies when rampage ends"] = { },
}
local keystoneList = {
	-- List of keystones that can be found on uniques
	"Acrobatics",
	"Ancestral Bond",
	"Arrow Dancing",
	"Avatar of Fire",
	"Blood Magic",
	"Conduit",
	"Eldritch Battery",
	"Elemental Equilibrium",
	"Elemental Overload",
	"Ghost Reaver",
	"Iron Grip",
	"Iron Reflexes",
	"Mind Over Matter",
	"Minion Instability",
	"Pain Attunement",
	"Perfect Agony",
	"Phase Acrobatics",
	"Point Blank",
	"Resolute Technique",
	"Unwavering Stance",
	"Vaal Pact",
	"Zealot's Oath",
}
for _, name in pairs(keystoneList) do
	specialModList[name:lower()] = { mod("Keystone", "LIST", name) }
end
local oldList = specialModList
specialModList = { }
for k, v in pairs(oldList) do
	specialModList["^"..k.."$"] = v
end

-- Modifiers that are recognised but unsupported
local unsupportedModList = {
	["culling strike"] = true,
	["properties are doubled while in a breach"] = true,
}

-- Special lookups used for various modifier forms
local suffixTypes = {
	["as extra lightning damage"] = "GainAsLightning",
	["added as lightning damage"] = "GainAsLightning",
	["gained as extra lightning damage"] = "GainAsLightning",
	["as extra cold damage"] = "GainAsCold",
	["added as cold damage"] = "GainAsCold",
	["gained as extra cold damage"] = "GainAsCold",
	["as extra fire damage"] = "GainAsFire",
	["added as fire damage"] = "GainAsFire",
	["gained as extra fire damage"] = "GainAsFire",
	["as extra chaos damage"] = "GainAsChaos",
	["added as chaos damage"] = "GainAsChaos",
	["gained as extra chaos damage"] = "GainAsChaos",
	["converted to lightning"] = "ConvertToLightning",
	["converted to lightning damage"] = "ConvertToLightning",
	["converted to cold damage"] = "ConvertToCold",
	["converted to fire damage"] = "ConvertToFire",
	["converted to chaos damage"] = "ConvertToChaos",
	["added as energy shield"] = "GainAsEnergyShield",
	["as extra maximum energy shield"] = "GainAsEnergyShield",
	["converted to energy shield"] = "ConvertToEnergyShield",
	["as physical damage"] = "AsPhysical",
	["as lightning damage"] = "AsLightning",
	["as cold damage"] = "AsCold",
	["as fire damage"] = "AsFire",
	["as chaos damage"] = "AsChaos",
	["leeched as life and mana"] = "Leech",
	["leeched as life"] = "LifeLeech",
	["leeched as mana"] = "ManaLeech",
}
local dmgTypes = {
	["physical"] = "Physical",
	["lightning"] = "Lightning",
	["cold"] = "Cold",
	["fire"] = "Fire",
	["chaos"] = "Chaos",
}
local penTypes = {
	["lightning resistance"] = "LightningPenetration",
	["cold resistance"] = "ColdPenetration",
	["fire resistance"] = "FirePenetration",
	["elemental resistance"] = "ElementalPenetration",
	["elemental resistances"] = "ElementalPenetration",
}
local regenTypes = {
	["life"] = "LifeRegen",
	["maximum life"] = "LifeRegen",
	["life and mana"] = { "LifeRegen", "ManaRegen" },
	["mana"] = "ManaRegen",
	["energy shield"] = "EnergyShieldRegen",
	["maximum mana and energy shield"] = { "ManaRegen", "EnergyShieldRegen" },
}

-- Build active skill name lookup
local skillNameList = { }
local preSkillNameList = { }
for skillName, grantedEffect in pairs(data["3_0"].gems) do
	if not grantedEffect.hidden and not grantedEffect.support then
		skillNameList[" "..skillName:lower().." "] = { tag = { type = "SkillName", skillName = skillName } }
		preSkillNameList["^"..skillName:lower().." has ?a? "] = { tag = { type = "SkillName", skillName = skillName } }
		if grantedEffect.gemTags.totem then
			preSkillNameList["^"..skillName:lower().." totem deals "] = { tag = { type = "SkillName", skillName = skillName } }
			preSkillNameList["^"..skillName:lower().." totem grants "] = { addToSkill = { type = "SkillName", skillName = skillName }, tag = { type = "GlobalEffect", effectType = "Buff" } }
		end
		if grantedEffect.skillTypes[SkillType.Buff] or grantedEffect.baseFlags.buff then
			preSkillNameList["^"..skillName:lower().." grants "] = { addToSkill = { type = "SkillName", skillName = skillName }, tag = { type = "GlobalEffect", effectType = "Buff" } }
			preSkillNameList["^"..skillName:lower().." grants a?n? ?additional "] = { addToSkill = { type = "SkillName", skillName = skillName }, tag = { type = "GlobalEffect", effectType = "Buff" } }
		end
	end	
end

local function getSimpleConv(srcList, dst, type, remove, factor)
	return function(nodeMods, out, data)
		if nodeMods then
			for _, src in pairs(srcList) do
				for _, mod in ipairs(nodeMods) do
					if mod.name == src and mod.type == type then
						if remove then
							out:NewMod(src, type, -mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(mod))
						end
						if factor then
							out:NewMod(dst, type, math.floor(mod.value * factor), "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(mod))
						else
							out:NewMod(dst, type, mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(mod))
						end
					end
				end	
			end
		end
	end
end
local function getPerStat(dst, modType, flags, stat, factor)
	return function(nodeMods, out, data)
		if nodeMods then
			data[stat] = (data[stat] or 0) + nodeMods:Sum("BASE", nil, stat)
		else
			out:NewMod(dst, modType, math.floor(data[stat] * factor + 0.5), "Tree:Jewel", flags)
		end
	end
end
local function getThreshold(attrib, name, modType, value, ...)
	local mod = mod(name, modType, value, "Tree:Jewel", ...)
	if type(value) == "table" and value.mod then
		value.mod.source = mod.source
	end
	return function(nodeMods, out, data, attributes)
		if not nodeMods and attributes[attrib] >= 40 then
			out:AddMod(mod)
		end
	end
end
-- List of radius jewel functions
local jewelFuncs = {
-- Conversion jewels
	["Strength from Passives in Radius is Transformed to Dexterity"] = getSimpleConv({"Str"}, "Dex", "BASE", true),
	["Dexterity from Passives in Radius is Transformed to Strength"] = getSimpleConv({"Dex"}, "Str", "BASE", true),
	["Strength from Passives in Radius is Transformed to Intelligence"] = getSimpleConv({"Str"}, "Int", "BASE", true),
	["Intelligence from Passives in Radius is Transformed to Strength"] = getSimpleConv({"Int"}, "Str", "BASE", true),
	["Dexterity from Passives in Radius is Transformed to Intelligence"] = getSimpleConv({"Dex"}, "Int", "BASE", true),
	["Intelligence from Passives in Radius is Transformed to Dexterity"] = getSimpleConv({"Int"}, "Dex", "BASE", true),
	["Increases and Reductions to Life in Radius are Transformed to apply to Energy Shield"] = getSimpleConv({"Life"}, "EnergyShield", "INC", true),
	["Increases and Reductions to Energy Shield in Radius are Transformed to apply to Armour at 200% of their value"] = getSimpleConv({"EnergyShield"}, "Armour", "INC", true, 2),
	["Increases and Reductions to Life in Radius are Transformed to apply to Mana at 200% of their value"] = getSimpleConv({"Life"}, "Mana", "INC", true, 2),
	["Increases and Reductions to Physical Damage in Radius are Transformed to apply to Cold Damage"] = getSimpleConv({"PhysicalDamage"}, "ColdDamage", "INC", true),
	["Increases and Reductions to Cold Damage in Radius are Transformed to apply to Physical Damage"] = getSimpleConv({"ColdDamage"}, "PhysicalDamage", "INC", true),
	["Increases and Reductions to other Damage Types in Radius are Transformed to apply to Fire Damage"] = getSimpleConv({"PhysicalDamage","ColdDamage","LightningDamage","ChaosDamage"}, "FireDamage", "INC", true),
	["Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Chance to Block Spells at 35% of its value"] = getSimpleConv({"LightningResist","ElementalResist"}, "SpellBlockChance", "BASE", false, 0.35),
	["Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Dodge Attacks at 35% of its value"] = getSimpleConv({"ColdResist","ElementalResist"}, "AttackDodgeChance", "BASE", false, 0.35),
	["Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Chance to Block at 35% of its value"] = getSimpleConv({"FireResist","ElementalResist"}, "BlockChance", "BASE", false, 0.35),
	["Melee and Melee Weapon Type modifiers in Radius are Transformed to Bow Modifiers"] = function(nodeMods, out, data)
		if nodeMods then
			local mask1 = bor(ModFlag.Axe, ModFlag.Claw, ModFlag.Dagger, ModFlag.Mace, ModFlag.Staff, ModFlag.Sword, ModFlag.Melee)
			local mask2 = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee)
			local mask3 = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee)
			for _, mod in ipairs(nodeMods) do
				if band(mod.flags, mask1) ~= 0 or band(mod.flags, mask2) == mask2 or band(mod.flags, mask3) == mask3 then
					out:NewMod(mod.name, mod.type, -mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(mod))
					out:NewMod(mod.name, mod.type, mod.value, "Tree:Jewel", bor(band(mod.flags, bnot(bor(mask1, mask2, mask3))), ModFlag.Bow), mod.keywordFlags, unpack(mod))
				elseif mod[1] then
					for _, tag in ipairs(mod) do
						if tag.type == "Condition" and tag.var == "UsingStaff" then
							local newTagList = copyTable(mod)
							for _, tag in ipairs(newTagList) do
								if tag.type == "Condition" and tag.var == "UsingStaff" then
									tag.var = "UsingBow"
									break
								end
							end
							out:NewMod(mod.name, mod.type, -mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(mod))
							out:NewMod(mod.name, mod.type, mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(newTagList))
							break
						end
					end
				end
			end
		end
	end,
-- Per stat jewels
	["Adds 1 to maximum Life per 3 Intelligence in Radius"] = getPerStat("Life", "BASE", 0, "Int", 1 / 3),
	["Adds 1 to Maximum Life per 3 Intelligence Allocated in Radius"] = getPerStat("Life", "BASE", 0, "Int", 1 / 3),
	["1% increased Evasion Rating per 3 Dexterity Allocated in Radius"] = getPerStat("Evasion", "INC", 0, "Dex", 1 / 3),
	["1% increased Claw Physical Damage per 3 Dexterity Allocated in Radius"] = getPerStat("PhysicalDamage", "INC", ModFlag.Claw, "Dex", 1 / 3),
	["1% increased Melee Physical Damage while Unarmed per 3 Dexterity Allocated in Radius"] = getPerStat("PhysicalDamage", "INC", ModFlag.Unarmed, "Dex", 1 / 3),
	["3% increased Totem Life per 10 Strength in Radius"] = getPerStat("TotemLife", "INC", 0, "Str", 3 / 10),
	["3% increased Totem Life per 10 Strength Allocated in Radius"] = getPerStat("TotemLife", "INC", 0, "Str", 3 / 10),
	["Adds 1 maximum Lightning Damage to Attacks per 1 Dexterity Allocated in Radius"] = getPerStat("LightningMax", "BASE", ModFlag.Attack, "Dex", 1),
	["5% increased Chaos damage per 10 Intelligence from Allocated Passives in Radius"] = getPerStat("ChaosDamage", "INC", 0, "Int", 5 / 10),
	["Dexterity and Intelligence from passives in Radius count towards Strength Melee Damage bonus"] = function(nodeMods, out, data)
		if nodeMods then
			data.Dex = (data.Dex or 0) + nodeMods:Sum("BASE", nil, "Dex")
			data.Int = (data.Int or 0) + nodeMods:Sum("BASE", nil, "Int")
		else
			out:NewMod("DexIntToMeleeBonus", "BASE", data.Dex + data.Int, "Tree:Jewel")
		end
	end,
-- Threshold jewels
	["With at least 40 Dexterity in Radius, Frost Blades Melee Damage Penetrates 15% Cold Resistance"] = getThreshold("Dex", "ColdPenetration", "BASE", 15, ModFlag.Melee, { type = "SkillName", skillName = "Frost Blades" }),
	["With at least 40 Dexterity in Radius, Melee Damage dealt by Frost Blades Penetrates 15% Cold Resistance"] = getThreshold("Dex", "ColdPenetration", "BASE", 15, ModFlag.Melee, { type = "SkillName", skillName = "Frost Blades" }),
	["With at least 40 Dexterity in Radius, Frost Blades has 25% increased Projectile Speed"] = getThreshold("Dex", "ProjectileSpeed", "INC", 25, { type = "SkillName", skillName = "Frost Blades" }),
	["With at least 40 Dexterity in Radius, Ice Shot has 25% increased Area of Effect"] = getThreshold("Dex", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Ice Shot" }),
	["Ice Shot Pierces 5 additional Targets with 40 Dexterity in Radius"] = getThreshold("Dex", "PierceCount", "BASE", 5, { type = "SkillName", skillName = "Ice Shot" }),
	["With at least 40 Intelligence in Radius, Frostbolt fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Frostbolt" }),
	["With at least 40 Intelligence in Radius, Magma Orb fires an additional Projectile"] = getThreshold("Int", "ProjectileCount", "BASE", 1, { type = "SkillName", skillName = "Magma Orb" }),
	["With at least 40 Dexterity in Radius, Shrapnel Shot has 25% increased Area of Effect"] = getThreshold("Dex", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Shrapnel Shot" }),
	["With at least 40 Dexterity in Radius, Shrapnel Shot's cone has a 50% chance to deal Double Damage"] = getThreshold("Dex", "DoubleDamageChance", "BASE", 50, { type = "SkillName", skillName = "Shrapnel Shot" }, { type = "SkillPart", skillPart = 2 }),
	["With at least 40 Intelligence in Radius, Freezing Pulse fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Freezing Pulse" }),
	["With at least 40 Dexterity in Radius, Ethereal Knives fires 10 additional Projectiles"] = getThreshold("Dex", "ProjectileCount", "BASE", 10, { type = "SkillName", skillName = "Ethereal Knives" }),
	["With at least 40 Strength in Radius, Molten Strike fires 2 additional Projectiles"] = getThreshold("Str", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Molten Strike" }),
	["With at least 40 Strength in Radius, Molten Strike has 25% increased Area of Effect"] = getThreshold("Str", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Molten Strike" }),
	["With at least 40 Strength in Radius, 25% of Glacial Hammer Physical Damage converted to Cold Damage"] = getThreshold("Str", "PhysicalDamageConvertToCold", "BASE", 25, { type = "SkillName", skillName = "Glacial Hammer" }),
	["With at least 40 Strength in Radius, Heavy Strike has a 20% chance to deal Double Damage"] = getThreshold("Str", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Heavy Strike" }),
	["With at least 40 Strength in Radius, Heavy Strike has a 20% chance to deal Double Damage."] = getThreshold("Str", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Heavy Strike" }),
	["With at least 40 Dexterity in Radius, Dual Strike has a 20% chance to deal Double Damage with the Main-Hand Weapon"] = getThreshold("Dex", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Dual Strike" }, { type = "Condition", var = "MainHandAttack" }),
	["With at least 40 Intelligence in Radius, Raised Zombies' Slam Attack has 100% increased Cooldown Recovery Speed"] = getThreshold("Int", "MinionModifier", "LIST", { mod = mod("CooldownRecovery", "INC", 100, { type = "SkillId", skillId = "ZombieSlam" }) }),
	["With at least 40 Intelligence in Radius, Raised Zombies' Slam Attack deals 30% increased Damage"] = getThreshold("Int", "MinionModifier", "LIST", { mod = mod("Damage", "INC", 30, { type = "SkillId", skillId = "ZombieSlam" }) }),
	["With at least 40 Dexterity in Radius, Viper Strike deals 2% increased Attack Damage for each Poison on the Enemy"] = getThreshold("Dex", "Damage", "INC", 2, ModFlag.Attack, { type = "SkillName", skillName = "Viper Strike" }, { type = "Multiplier", var = "PoisonOnEnemy" }),
	["With at least 40 Dexterity in Radius, Viper Strike deals 2% increased Damage with Hits and Poison for each Poison on the Enemy"] = getThreshold("Dex", "Damage", "INC", 2, 0, bor(KeywordFlag.Hit, KeywordFlag.Poison), { type = "SkillName", skillName = "Viper Strike" }, { type = "Multiplier", var = "PoisonOnEnemy" }),
	--[""] = getThreshold("", "", "", , { type = "SkillName", skillName = "" }),
}
local jewelFuncList = { }
for k, v in pairs(jewelFuncs) do
	jewelFuncList[k:lower()] = v
end

-- Scan a line for the earliest and longest match from the pattern list
-- If a match is found, returns the corresponding value from the pattern list, plus the remainder of the line and a table of captures
local function scan(line, patternList, plain)
	local bestIndex, bestEndIndex
	local bestPattern = ""
	local bestVal, bestStart, bestEnd, bestCaps
	local lineLower = line:lower()
	for pattern, patternVal in pairs(patternList) do
		local index, endIndex, cap1, cap2, cap3, cap4, cap5 = lineLower:find(pattern, 1, plain)
		if index and (not bestIndex or index < bestIndex or (index == bestIndex and (endIndex > bestEndIndex or (endIndex == bestEndIndex and #pattern > #bestPattern)))) then
			bestIndex = index
			bestEndIndex = endIndex
			bestPattern = pattern
			bestVal = patternVal
			bestStart = index
			bestEnd = endIndex
			bestCaps = { cap1, cap2, cap3, cap4, cap5 }
		end
	end
	if bestVal then
		return bestVal, line:sub(1, bestStart - 1) .. line:sub(bestEnd + 1, -1), bestCaps
	else
		return nil, line
	end
end

local function parseMod(line, order)
	-- Check if this is a special modifier
	local specialMod, specialLine, cap = scan(line, specialModList)
	if specialMod and #specialLine == 0 then
		if type(specialMod) == "function" then
			return specialMod(tonumber(cap[1]), unpack(cap))
		else
			return copyTable(specialMod)
		end
	end
	local lineLower = line:lower()
	local jewelFunc = jewelFuncList[lineLower]
	if jewelFunc then
		return { mod("JewelFunc", "LIST", jewelFunc) }
	end
	if unsupportedModList[lineLower] then
		return { }, line
	end

	-- Check for a flag/tag specification at the start of the line
	local preFlag
	preFlag, line = scan(line, preFlagList)

	-- Check for skill name at the start of the line
	local skillTag
	skillTag, line = scan(line, preSkillNameList)

	-- Scan for modifier form
	local modForm, formCap
	modForm, line, formCap = scan(line, formList)
	if not modForm then
		return nil, line
	end
	local num = tonumber(formCap[1])

	-- Check for tags (per-charge, conditionals)
	local modTag, modTag2, tagCap
	modTag, line, tagCap = scan(line, modTagList)
	if type(modTag) == "function" then
		modTag = modTag(tonumber(tagCap[1]), unpack(tagCap))
	end
	if modTag then
		modTag2, line, tagCap = scan(line, modTagList)
		if type(modTag2) == "function" then
			modTag2 = modTag2(tonumber(tagCap[1]), unpack(tagCap))
		end
	end
	
	-- Scan for modifier name and skill name
	local modName
	if order == 2 and not skillTag then
		skillTag, line = scan(line, skillNameList, true)
	end
	if modForm == "PEN" then
		modName, line = scan(line, penTypes, true)
		if not modName then
			return { }, line
		end
		local _
		_, line = scan(line, modNameList, true)
	else
		modName, line = scan(line, modNameList, true)
	end
	if order == 1 and not skillTag then
		skillTag, line = scan(line, skillNameList, true)
	end
	
	-- Scan for flags
	local modFlag
	modFlag, line = scan(line, modFlagList, true)

	-- Find modifier value and type according to form
	local modValue = num
	local modType = "BASE"
	local modSuffix
	if modForm == "INC" then
		modType = "INC"
	elseif modForm == "RED" then
		modValue = -num
		modType = "INC"
	elseif modForm == "MORE" then
		modType = "MORE"
	elseif modForm == "LESS" then
		modValue = -num
		modType = "MORE"
	elseif modForm == "BASE" then
		modSuffix, line = scan(line, suffixTypes, true)
	elseif modForm == "CHANCE" then
	elseif modForm == "REGENPERCENT" then
		modName = regenTypes[formCap[2]]
		modSuffix = "Percent"
	elseif modForm == "REGENFLAT" then
		modName = regenTypes[formCap[2]]
	elseif modForm == "DMG" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }
		modName = { damageType.."Min", damageType.."Max" }
	elseif modForm == "DMGATTACKS" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }
		modName = { damageType.."Min", damageType.."Max" }
		modFlag = modFlag or { keywordFlags = KeywordFlag.Attack }
	elseif modForm == "DMGSPELLS" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }		
		modName = { damageType.."Min", damageType.."Max" }
		modFlag = modFlag or { keywordFlags = KeywordFlag.Spell }
	elseif modForm == "DMGBOTH" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }		
		modName = { damageType.."Min", damageType.."Max" }
		modFlag = modFlag or { keywordFlags = bor(KeywordFlag.Attack, KeywordFlag.Spell) }
	end
	if not modName then
		return { }, line
	end

	-- Combine flags and tags
	local flags = 0
	local keywordFlags = 0
	local tagList = { }
	local misc = { }
	for _, data in pairs({ modName, preFlag, modFlag, modTag, modTag2, skillTag }) do
		if type(data) == "table" then
			flags = bor(flags, data.flags or 0)
			keywordFlags = bor(keywordFlags, data.keywordFlags or 0)
			if data.tag then
				t_insert(tagList, copyTable(data.tag))
			elseif data.tagList then
				for _, tag in ipairs(data.tagList) do
					t_insert(tagList, copyTable(tag))
				end
			end
			for k, v in pairs(data) do
				misc[k] = v
			end
		end
	end

	-- Generate modifier list
	local nameList = modName
	local modList = { }
	for i, name in ipairs(type(nameList) == "table" and nameList or { nameList }) do
		modList[i] = {
			name = name .. (modSuffix or misc.modSuffix or ""),
			type = modType,
			value = type(modValue) == "table" and modValue[i] or modValue,
			flags = flags,
			keywordFlags = keywordFlags,
			unpack(tagList)
		}
	end
	if modList[1] then
		-- Special handling for various modifier types
		if misc.addToAura then
			-- Modifiers that add effects to your auras
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("ExtraAuraEffect", "LIST", { mod = effectMod })
			end
		elseif misc.newAura then
			-- Modifiers that add extra auras
			for i, effectMod in ipairs(modList) do
				local tagList = { }
				for i, tag in ipairs(effectMod) do
					tagList[i] = tag
					effectMod[i] = nil
				end
				modList[i] = mod("ExtraAura", "LIST", { mod = effectMod, onlyAllies = misc.newAuraOnlyAllies }, unpack(tagList))
			end
		elseif misc.affectedByAura then
			-- Modifiers that apply to actors affected by your auras
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("AffectedByAuraMod", "LIST", { mod = effectMod })
			end
		elseif misc.addToMinion then
			-- Minion modifiers
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("MinionModifier", "LIST", { mod = effectMod }, misc.addToMinionTag)
			end
		elseif misc.addToSkill then
			-- Skill enchants or socketed gem modifiers that add additional effects
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("ExtraSkillMod", "LIST", { mod = effectMod }, misc.addToSkill)
			end
		end
	end
	return modList, line:match("%S") and line
end

local cache = { }
local unsupported = { }
local count = 0
--local foo = io.open("../unsupported.txt", "w")
--foo:close()
return function(line, isComb)
	if not cache[line] then
		local modList, extra = parseMod(line, 1)
		if modList and extra then
			modList, extra = parseMod(line, 2)
		end
		cache[line] = { modList, extra }
		if foo and not isComb and not cache[line][1] then
			local form = line:gsub("[%+%-]?%d+%.?%d*","{num}")
			if not unsupported[form] then
				unsupported[form] = true
				count = count + 1
				foo = io.open("../unsupported.txt", "a+")
				foo:write(count, ': ', form, '\n')
				foo:close()
			end
		end
	end
	return unpack(copyTable(cache[line]))
end, cache