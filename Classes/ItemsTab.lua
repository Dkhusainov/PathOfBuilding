-- Path of Building
--
-- Module: Items Tab
-- Items tab for the current build.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format
local m_max = math.max
local m_min = math.min
local m_ceil = math.ceil
local m_floor = math.floor
local m_modf = math.modf

local rarityDropList = { 
	{ label = colorCodes.NORMAL.."Normal", rarity = "NORMAL" },
	{ label = colorCodes.MAGIC.."Magic", rarity = "MAGIC" },
	{ label = colorCodes.RARE.."Rare", rarity = "RARE" },
	{ label = colorCodes.UNIQUE.."Unique", rarity = "UNIQUE" },
	{ label = colorCodes.RELIC.."Relic", rarity = "RELIC" }
}

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }

local ItemsTabClass = common.NewClass("ItemsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build
	
--	self.socketViewer = common.New("PassiveTreeView")

	self.items = { }
	self.itemOrderList = { }

	-- Build lists of item bases, separated by type
	self.baseLists = { }
	for name, base in pairs(self.build.data.itemBases) do
		if not base.hidden then
			local type = base.type
			if base.subType then
				type = type .. ": " .. base.subType
			end
			self.baseLists[type] = self.baseLists[type] or { }
			t_insert(self.baseLists[type], { label = name:gsub(" %(.+%)",""), name = name, base = base })
		end
	end
	self.baseTypeList = { }
	for type, list in pairs(self.baseLists) do
		t_insert(self.baseTypeList, type)
		table.sort(list, function(a, b) 
			if a.base.req and b.base.req then
				if a.base.req.level == b.base.req.level then
					return a.name < b.name
				else
					return (a.base.req.level or 1) > (b.base.req.level or 1)
				end
			elseif a.base.req and not b.base.req then
				return true
			elseif b.base.req and not a.base.req then
				return false
			else
				return a.name < b.name
			end
		end)
	end
	table.sort(self.baseTypeList)

	-- Set selector
	self.controls.setSelect = common.New("DropDownControl", {"TOPLEFT",self,"TOPLEFT"}, 96, 8, 200, 20, nil, function(index, value)
		self:SetActiveItemSet(self.itemSetOrderList[index])
		self:AddUndoState()
	end)
	self.controls.setSelect.enabled = function()
		return #self.itemSetOrderList > 1
	end
	self.controls.setSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode == "HOVER" then
			self:AddItemSetTooltip(tooltip, self.itemSets[self.itemSetOrderList[index]])
		end
	end
	self.controls.setLabel = common.New("LabelControl", {"RIGHT",self.controls.setSelect,"LEFT"}, -2, 0, 0, 16, "^7Item set:")
	self.controls.setManage = common.New("ButtonControl", {"LEFT",self.controls.setSelect,"RIGHT"}, 4, 0, 90, 20, "Manage...", function()
		self:OpenItemSetManagePopup()
	end)

	-- Item slots
    self.slots = { }
    self.orderedSlots = { }
    self.slotOrder = {}
    --[[
	self.slotAnchor = common.New("Control", {"TOPLEFT",self,"TOPLEFT"}, 96, 24, 310, 0)
	for index, slotName in ipairs(baseSlots) do
		local slot = common.New("ItemSlot", {"TOPLEFT",self.slotAnchor,"TOPLEFT"}, 0, (index - 1) * 20, self, slotName)
		t_insert(self.controls, slot)
		self.slotOrder[slotName] = #self.orderedSlots
		if slotName:match("Weapon") then
			slot.weaponSet = 1
			slot.shown = function()
				return not self.activeItemSet.useSecondWeaponSet
			end
			local swapSlot = common.New("ItemSlot", {"TOPLEFT",self.slotAnchor,"TOPLEFT"}, 0, (index - 1) * 20, self, slotName.." Swap", slotName)
			t_insert(self.controls, swapSlot)
			self.slotOrder[swapSlot.slotName] = #self.orderedSlots
			swapSlot.weaponSet = 2
			swapSlot.shown = function()
				return not slot:IsShown()
			end
		end
	end
	self.sockets = { }
	for _, node in pairs(build.tree.nodes) do
		if node.type == "socket" then
			local socketControl = common.New("ItemSlot", {"TOPLEFT",self.slotAnchor,"TOPLEFT"}, 0, 0, self, "Jewel "..node.id, "Socket", node.id)
			self.controls["socket"..node.id] = socketControl
			self.sockets[node.id] = socketControl
			self.slotOrder["Jewel "..node.id] = #baseSlots + 1 + node.id
		end
	end
	table.sort(self.orderedSlots, function(a, b)
		return self.slotOrder[a.slotName] < self.slotOrder[b.slotName]
	end)
	self.controls.slotHeader = common.New("LabelControl", {"BOTTOMLEFT",self.slotAnchor,"TOPLEFT"}, 0, -4, 0, 16, "^7Equipped items:")
	self.controls.weaponSwap1 = common.New("ButtonControl", {"BOTTOMRIGHT",self.slotAnchor,"TOPRIGHT"}, -20, -2, 18, 18, "I", function()
		if self.activeItemSet.useSecondWeaponSet then
			self.activeItemSet.useSecondWeaponSet = false
			self:AddUndoState()
			self.build.buildFlag = true
			local mainSocketGroup = self.build.skillsTab.socketGroupList[self.build.mainSocketGroup]
			if mainSocketGroup and mainSocketGroup.slot and self.slots[mainSocketGroup.slot].weaponSet == 2 then
				for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
					if socketGroup.slot and self.slots[socketGroup.slot].weaponSet == 1 then
						self.build.mainSocketGroup = index
						break
					end
				end
			end
		end
	end)
	self.controls.weaponSwap1.overSizeText = 3
	self.controls.weaponSwap1.locked = function()
		return not self.activeItemSet.useSecondWeaponSet
	end
	self.controls.weaponSwap2 = common.New("ButtonControl", {"BOTTOMRIGHT",self.slotAnchor,"TOPRIGHT"}, 0, -2, 18, 18, "II", function()
		if not self.activeItemSet.useSecondWeaponSet then
			self.activeItemSet.useSecondWeaponSet = true
			self:AddUndoState()
			self.build.buildFlag = true
			local mainSocketGroup = self.build.skillsTab.socketGroupList[self.build.mainSocketGroup]
			if mainSocketGroup and mainSocketGroup.slot and self.slots[mainSocketGroup.slot].weaponSet == 1 then
				for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
					if socketGroup.slot and self.slots[socketGroup.slot].weaponSet == 2 then
						self.build.mainSocketGroup = index
						break
					end
				end
			end
		end
	end)
	self.controls.weaponSwap2.overSizeText = 3
	self.controls.weaponSwap2.locked = function()
		return self.activeItemSet.useSecondWeaponSet
	end
	self.controls.weaponSwapLabel = common.New("LabelControl", {"RIGHT",self.controls.weaponSwap1,"LEFT"}, -4, 0, 0, 14, "^7Weapon Set:")

	-- All items list
	self.controls.itemList = common.New("ItemList", {"TOPLEFT",self.slotAnchor,"TOPRIGHT"}, 20, -20, 360, 308, self)

	-- Database selector
	self.controls.selectDBLabel = common.New("LabelControl", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 14, 0, 16, "^7Import from:")
	self.controls.selectDBLabel.shown = function()
		return self.height < 980
	end
	self.controls.selectDB = common.New("DropDownControl", {"LEFT",self.controls.selectDBLabel,"RIGHT"}, 4, 0, 150, 18, { "Uniques", "Rare Templates" })

	-- Unique database
	self.controls.uniqueDB = common.New("ItemDB", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 76, 360, function(c) return m_min(260, self.maxY - select(2, c:GetPos())) end, self, main.uniqueDB[build.targetVersion])
	self.controls.uniqueDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 76 or 54
	end
	self.controls.uniqueDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.selIndex == 1
	end

	-- Rare template database
	self.controls.rareDB = common.New("ItemDB", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 76, 360, function(c) return m_min(260, self.maxY - select(2, c:GetPos())) end, self, main.rareDB[build.targetVersion])
	self.controls.rareDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 76 or 370
	end
	self.controls.rareDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.selIndex == 2
	end

	-- Create/import item
	self.controls.craftDisplayItem = common.New("ButtonControl", {"TOPLEFT",self.controls.itemList,"TOPRIGHT"}, 20, 0, 120, 20, "Craft item...", function()
		self:CraftItem()
	end)
	self.controls.craftDisplayItem.shown = function()
		return self.displayItem == nil 
	end
	self.controls.newDisplayItem = common.New("ButtonControl", {"TOPLEFT",self.controls.craftDisplayItem,"TOPRIGHT"}, 8, 0, 120, 20, "Create custom...", function()
		self:EditDisplayItemText()
	end)
	self.controls.displayItemTip = common.New("LabelControl", {"TOPLEFT",self.controls.craftDisplayItem,"BOTTOMLEFT"}, 0, 8, 100, 16, 
^7Double-click an item from one of the lists,
or copy and paste an item from in game (hover over the item and Ctrl+C)
to view or edit the item and add it to your build.
You can Control + Click an item to equip it, or drag it onto the slot.
This will also add it to your build if it's from the unique/template list.
If there's 2 slots an item can go in, holding Shift will put it in the second.)

	self.controls.sharedItemList = common.New("SharedItemList", {"TOPLEFT",self.controls.craftDisplayItem, "BOTTOMLEFT"}, 0, 142, 360, 308, self)

	-- Display item
	self.displayItemTooltip = common.New("Tooltip")
	self.displayItemTooltip.maxWidth = 458
	self.anchorDisplayItem = common.New("Control", {"TOPLEFT",self.controls.itemList,"TOPRIGHT"}, 20, 0, 0, 0)
	self.anchorDisplayItem.shown = function()
		return self.displayItem ~= nil
	end
	self.controls.addDisplayItem = common.New("ButtonControl", {"TOPLEFT",self.anchorDisplayItem,"TOPLEFT"}, 0, 0, 100, 20, "", function()
		self:AddDisplayItem()
	end)
	self.controls.addDisplayItem.label = function()
		return self.items[self.displayItem.id] and "Save" or "Add to build"
	end
	self.controls.editDisplayItem = common.New("ButtonControl", {"LEFT",self.controls.addDisplayItem,"RIGHT"}, 8, 0, 60, 20, "Edit...", function()
		self:EditDisplayItemText()
	end)
	self.controls.removeDisplayItem = common.New("ButtonControl", {"LEFT",self.controls.editDisplayItem,"RIGHT"}, 8, 0, 60, 20, "Cancel", function()
		self:SetDisplayItem()
	end)
	self.controls.displayItemVariant = common.New("DropDownControl", {"LEFT",self.controls.removeDisplayItem,"RIGHT"}, 8, 0, 200, 20, nil, function(index, value)
		self.displayItem.variant = index
		itemLib.buildItemModList(self.displayItem)
		self:UpdateDisplayItemTooltip()
		self:UpdateDisplayItemRangeLines()
	end)
	self.controls.displayItemVariant.shown = function()
		return self.displayItem.variantList and #self.displayItem.variantList > 1
	end
	
	-- Section: Apply Implicit
	self.controls.displayItemSectionImplicit = common.New("Control", {"TOPLEFT",self.controls.addDisplayItem,"BOTTOMLEFT"}, 0, 8, 0, function()
		return (self.controls.displayItemEnchant:IsShown() or self.controls.displayItemCorrupt:IsShown()) and 28 or 0
	end)
	self.controls.displayItemEnchant = common.New("ButtonControl", {"TOPLEFT",self.controls.displayItemSectionImplicit,"TOPLEFT"}, 0, 0, 160, 20, "Apply Enchantment...", function()
		self:EnchantDisplayItem()
	end)
	self.controls.displayItemEnchant.shown = function()
		return self.displayItem.enchantments
	end
	self.controls.displayItemCorrupt = common.New("ButtonControl", {"TOPLEFT",self.controls.displayItemSectionImplicit,"TOPLEFT"}, function() return self.controls.displayItemEnchant:IsShown() and 168 or 0 end, 0, 100, 20, "Corrupt...", function()
		self:CorruptDisplayItem()
	end)
	self.controls.displayItemCorrupt.shown = function()
		return self.displayItem.corruptable
	end

	-- Section: Affix Selection
	self.controls.displayItemSectionAffix = common.New("Control", {"TOPLEFT",self.controls.displayItemSectionImplicit,"BOTTOMLEFT"}, 0, 0, 0, function()
		if not self.displayItem.crafted then
			return 0
		end
		local h = 6
		for i = 1, 6 do
			if self.controls["displayItemAffix"..i]:IsShown() then
				h = h + 24
				if self.controls["displayItemAffixRange"..i]:IsShown() then
					h = h + 18
				end
			end
		end
		return h
	end)
	for i = 1, 6 do
		local prev = self.controls["displayItemAffix"..(i-1)] or self.controls.displayItemSectionAffix
		local drop, slider
		drop = common.New("DropDownControl", {"TOPLEFT",prev,"TOPLEFT"}, i==1 and 40 or 0, 0, 418, 20, nil, function(index, value)
			local affix = { modId = "None" }
			if value.modId then
				affix.modId = value.modId
				affix.range = slider.val
			elseif value.modList then
				slider.divCount = #value.modList
				local index, range = slider:GetDivVal()
				affix.modId = value.modList[index]
				affix.range = range
			end
			self.displayItem[drop.outputTable][drop.outputIndex] = affix
			itemLib.craftItem(self.displayItem)
			self:UpdateDisplayItemTooltip()
			self:UpdateAffixControls()
		end)
		drop.y = function()
			return i == 1 and 0 or 24 + (prev.slider:IsShown() and 18 or 0)
		end
		drop.tooltipFunc = function(tooltip, mode, index, value)
			local modList = value.modList
			if not modList or main.popups[1] or mode == "OUT" or (self.selControl and self.selControl ~= drop) then
				tooltip:Clear()
			elseif tooltip:CheckForUpdate(modList) then
				if value.modId or #modList == 1 then
					local mod = self.displayItem.affixes[value.modId or modList[1]]
					tooltip:AddLine(16, "^7Affix: "..mod.affix)
					for _, line in ipairs(mod) do
						tooltip:AddLine(14, "^7"..line)
					end
					if mod.level > 1 then
						tooltip:AddLine(16, "Level: "..mod.level)
					end
				else
					tooltip:AddLine(16, "^7"..#modList.." Tiers")
					local minMod = self.displayItem.affixes[modList[1]]
					local maxMod = self.displayItem.affixes[modList[#modList]]
					for l, line in ipairs(minMod) do
						local minLine = line:gsub("%((%d[%d%.]*)%-(%d[%d%.]*)%)", "%1")
						local maxLine = maxMod[l]:gsub("%((%d[%d%.]*)%-(%d[%d%.]*)%)", "%2")
						local start = 1
						tooltip:AddLine(14, minLine:gsub("%d[%d%.]*", function(min)
							local s, e, max = maxLine:find("(%d[%d%.]*)", start)
							start = e + 1
							if min == max then
								return min
							else
								return "("..min.."-"..max..")"
							end
						end))
					end
					tooltip:AddLine(16, "Level: "..minMod.level.." to "..maxMod.level)
				end
			end
		end
		drop.shown = function()
			return self.displayItem.crafted and i <= self.displayItem.affixLimit
		end
		slider = common.New("SliderControl", {"TOPLEFT",drop,"BOTTOMLEFT"}, 0, 2, 300, 16, function(val)
			local affix = self.displayItem[drop.outputTable][drop.outputIndex]
			local index, range = slider:GetDivVal()
			affix.modId = drop.list[drop.selIndex].modList[index]
			affix.range = range
			itemLib.craftItem(self.displayItem)
			self:UpdateDisplayItemTooltip()
		end)
		slider.width = function()
			return slider.divCount and 300 or 100
		end
		slider.tooltipFunc = function(tooltip, val)
			local modList = drop.list[drop.selIndex].modList
			if not modList or main.popups[1] or (self.selControl and self.selControl ~= slider) then
				tooltip:Clear()
			elseif tooltip:CheckForUpdate(val, modList) then
				local index, range = slider:GetDivVal(val)
				local modId = modList[index]
				local mod = self.displayItem.affixes[modId]
				for _, line in ipairs(mod) do
					tooltip:AddLine(16, itemLib.applyRange(line, range))
				end
				tooltip:AddSeparator(10)
				if #modList > 1 then
					tooltip:AddLine(16, "^7Affix: Tier "..(#modList - isValueInArray(modList, modId) + 1).." ("..mod.affix..")")
				else
					tooltip:AddLine(16, "^7Affix: "..mod.affix)
				end
				for _, line in ipairs(mod) do
					tooltip:AddLine(14, line)
				end
				if mod.level > 1 then
					tooltip:AddLine(16, "Level: "..mod.level)
				end
			end
		end
		drop.slider = slider
		self.controls["displayItemAffix"..i] = drop
		self.controls["displayItemAffixLabel"..i] = common.New("LabelControl", {"RIGHT",drop,"LEFT"}, -4, 0, 0, 14, function()
			return drop.outputTable == "prefixes" and "^7Prefix:" or "^7Suffix:"
		end)
		self.controls["displayItemAffixRange"..i] = slider
		self.controls["displayItemAffixRangeLabel"..i] = common.New("LabelControl", {"RIGHT",slider,"LEFT"}, -4, 0, 0, 14, function()
			return drop.selIndex > 1 and "^7Roll:" or "^x7F7F7FRoll:"
		end)
	end

	-- Section: Custom modifiers
	self.controls.displayItemSectionCustom = common.New("Control", {"TOPLEFT",self.controls.displayItemSectionAffix,"BOTTOMLEFT"}, 0, 0, 0, function()
		local ret = 0
		return self.controls.displayItemAddCustom:IsShown() and 28 + self.displayItem.customCount * 22 or 0
	end)
	self.controls.displayItemAddCustom = common.New("ButtonControl", {"TOPLEFT",self.controls.displayItemSectionCustom,"TOPLEFT"}, 0, 0, 120, 20, "Add modifier...", function()
		self:AddCustomModifierToDisplayItem()
	end)
	self.controls.displayItemAddCustom.shown = function()
		return self.displayItem.rarity == "MAGIC" or self.displayItem.rarity == "RARE"
	end

	-- Section: Modifier Range
	self.controls.displayItemSectionRange = common.New("Control", {"TOPLEFT",self.controls.displayItemSectionCustom,"BOTTOMLEFT"}, 0, 0, 0, function()
		return self.displayItem.rangeLineList[1] and 28 or 0
	end)
	self.controls.displayItemRangeLine = common.New("DropDownControl", {"TOPLEFT",self.controls.displayItemSectionRange,"TOPLEFT"}, 0, 0, 350, 18, nil, function(index, value)
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[index].range
	end)
	self.controls.displayItemRangeLine.shown = function()
		return self.displayItem.rangeLineList[1] ~= nil
	end
	self.controls.displayItemRangeSlider = common.New("SliderControl", {"LEFT",self.controls.displayItemRangeLine,"RIGHT"}, 8, 0, 100, 18, function(val)
		self.displayItem.rangeLineList[self.controls.displayItemRangeLine.selIndex].range = val
		itemLib.buildItemModList(self.displayItem)
		self:UpdateDisplayItemTooltip()
		self:UpdateCustomControls()
	end)

	-- Tooltip anchor
	self.controls.displayItemTooltipAnchor = common.New("Control", {"TOPLEFT",self.controls.displayItemSectionRange,"BOTTOMLEFT"})

	-- Scroll bars
	self.controls.scrollBarH = common.New("ScrollBarControl", nil, 0, 0, 0, 18, 100, "HORIZONTAL", true)
	self.controls.scrollBarV = common.New("ScrollBarControl", nil, 0, 0, 18, 0, 100, "VERTICAL", true)

	-- Initialise drag target lists
	t_insert(self.controls.itemList.dragTargetList, self.controls.sharedItemList)
	t_insert(self.controls.itemList.dragTargetList, build.controls.mainSkillMinion)
	t_insert(self.controls.uniqueDB.dragTargetList, self.controls.itemList)
	t_insert(self.controls.uniqueDB.dragTargetList, self.controls.sharedItemList)
	t_insert(self.controls.uniqueDB.dragTargetList, build.controls.mainSkillMinion)
	t_insert(self.controls.rareDB.dragTargetList, self.controls.itemList)
	t_insert(self.controls.rareDB.dragTargetList, self.controls.sharedItemList)
	t_insert(self.controls.rareDB.dragTargetList, build.controls.mainSkillMinion)
	t_insert(self.controls.sharedItemList.dragTargetList, self.controls.itemList)
	t_insert(self.controls.sharedItemList.dragTargetList, build.controls.mainSkillMinion)
	for _, slot in pairs(self.slots) do
		t_insert(self.controls.itemList.dragTargetList, slot)
		t_insert(self.controls.uniqueDB.dragTargetList, slot)
		t_insert(self.controls.rareDB.dragTargetList, slot)
		t_insert(self.controls.sharedItemList.dragTargetList, slot)
	end
	]]

	-- Initialise item sets
	self.itemSets = { }
	self.itemSetOrderList = { 1 }
--	self:NewItemSet(1)
--	self:SetActiveItemSet(1)

--	self:PopulateSlots()
--	self.lastSlot = self.slots[baseSlots[#baseSlots]]
end)

function ItemsTabClass:Load(xml, dbFileName)
	self.activeItemSetId = 0
	self.itemSets = { }
	self.itemSetOrderList = { }
	for _, node in ipairs(xml) do
		if node.elem == "Item" then
			local item = { }
			item.raw = ""
			item.targetVersion = self.build.targetVersion
			item.id = tonumber(node.attrib.id)
			item.variant = tonumber(node.attrib.variant)
			itemLib.parseItemRaw(item)
			for _, child in ipairs(node) do
				if type(child) == "string" then
					item.raw = child
					itemLib.parseItemRaw(item)
				elseif child.elem == "ModRange" then
					local id = tonumber(child.attrib.id) or 0
					local range = tonumber(child.attrib.range) or 1
					if item.modLines[id] then
						item.modLines[id].range = range
					end
				end
			end
			itemLib.buildItemModList(item)
			self.items[item.id] = item
			t_insert(self.itemOrderList, item.id)
		elseif node.elem == "Slot" then
			local slot = self.slots[node.attrib.name or ""]
			if slot then
				slot.selItemId = tonumber(node.attrib.itemId)
				if slot.controls.activate then
					slot.active = node.attrib.active == "true"
					slot.controls.activate.state = slot.active
				end
			end
		elseif node.elem == "ItemSet" then
			local itemSet = self:NewItemSet(tonumber(node.attrib.id))
			itemSet.title = node.attrib.title
			itemSet.useSecondWeaponSet = node.attrib.useSecondWeaponSet == "true"
			for _, child in ipairs(node) do
				if child.elem == "Slot" then
					local slotName = child.attrib.name or ""
					if itemSet[slotName] then
						itemSet[slotName].selItemId = tonumber(child.attrib.itemId)
						itemSet[slotName].active = child.attrib.active == "true"
					end
				end
			end
			t_insert(self.itemSetOrderList, itemSet.id)
		end
	end
	if not self.itemSetOrderList[1] then
		self.activeItemSet = self:NewItemSet(1)
		self.activeItemSet.useSecondWeaponSet = xml.attrib.useSecondWeaponSet == "true"
		self.itemSetOrderList[1] = 1
	end
	self:SetActiveItemSet(tonumber(xml.attrib.activeItemSet) or 1)
	self:ResetUndo()
end

function ItemsTabClass:Save(xml)
	xml.attrib = {
		activeItemSet = tostring(self.activeItemSetId),
		useSecondWeaponSet = tostring(self.activeItemSet.useSecondWeaponSet),
	}
	for _, id in ipairs(self.itemOrderList) do
		local item = self.items[id]
		local child = { elem = "Item", attrib = { id = tostring(id), variant = item.variant and tostring(item.variant) } }
		t_insert(child, item.raw)
		for id, modLine in ipairs(item.modLines) do
			if modLine.range then
				t_insert(child, { elem = "ModRange", attrib = { id = tostring(id), range = tostring(modLine.range) } })
			end
		end
		t_insert(xml, child)
	end
	for slotName, slot in pairs(self.slots) do
		if slot.selItemId ~= 0 and not slot.nodeId then
			t_insert(xml, { elem = "Slot", attrib = { name = slotName, itemId = tostring(slot.selItemId), active = slot.active and "true" }})
		end
	end
	for _, itemSetId in ipairs(self.itemSetOrderList) do
		local itemSet = self.itemSets[itemSetId]
		local child = { elem = "ItemSet", attrib = { id = tostring(itemSetId), title = itemSet.title, useSecondWeaponSet = tostring(itemSet.useSecondWeaponSet) } }
		for slotName, slot in pairs(self.slots) do
			if not slot.nodeId then
				t_insert(child, { elem = "Slot", attrib = { name = slotName, itemId = tostring(itemSet[slotName].selItemId), active = itemSet[slotName].active and "true" }})
			end
		end
		t_insert(xml, child)
	end
	self.modFlag = false
end

function ItemsTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height
	self.controls.scrollBarH.width = viewPort.width
	self.controls.scrollBarH.x = viewPort.x
	self.controls.scrollBarH.y = viewPort.y + viewPort.height - 18
	self.controls.scrollBarV.height = viewPort.height - 18
	self.controls.scrollBarV.x = viewPort.x + viewPort.width - 18
	self.controls.scrollBarV.y = viewPort.y
	do
		local maxY = select(2, self.lastSlot:GetPos()) + 24
		if self.displayItem then
			local x, y = self.controls.displayItemTooltipAnchor:GetPos()
			local ttW, ttH = self.displayItemTooltip:GetSize()
			maxY = m_max(maxY, y + ttH + 4)
		end
		local contentHeight = maxY - self.y
		local contentWidth = self.anchorDisplayItem:GetPos() + 462 - self.x
		local v = contentHeight > viewPort.height
		local h = contentWidth > viewPort.width - (v and 20 or 0)
		if h then
			v = contentHeight > viewPort.height - 20
		end
		self.controls.scrollBarV:SetContentDimension(contentHeight, viewPort.height - (h and 20 or 0))
		self.controls.scrollBarH:SetContentDimension(contentWidth, viewPort.width - (v and 20 or 0))
		if self.snapHScroll == "RIGHT" then
			self.controls.scrollBarH:SetOffset(self.controls.scrollBarH.offsetMax)
		elseif self.snapHScroll == "LEFT" then
			self.controls.scrollBarH:SetOffset(0)
		end
		self.snapHScroll = nil
		self.maxY = h and self.controls.scrollBarH.y or viewPort.y + viewPort.height
	end
	self.x = self.x - self.controls.scrollBarH.offset
	self.y = self.y - self.controls.scrollBarV.offset

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "v" and IsKeyDown("CTRL") then
				local newItem = Paste()
				if newItem then
					self:CreateDisplayItemFromRaw(newItem, true)
				end
			elseif event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if event.key == "WHEELDOWN" or event.key == "PAGEDOWN" then
				if self.controls.scrollBarV:IsMouseOver() or not self.controls.scrollBarH:IsShown() then
					self.controls.scrollBarV:Scroll(1)
				else
					self.controls.scrollBarH:Scroll(1)
				end
			elseif event.key == "WHEELUP" or event.key == "PAGEUP" then
				if self.controls.scrollBarV:IsMouseOver() or not self.controls.scrollBarH:IsShown() then
					self.controls.scrollBarV:Scroll(-1)
				else
					self.controls.scrollBarH:Scroll(-1)
				end
			end
		end
	end

	main:DrawBackground(viewPort)

	wipeTable(self.controls.setSelect.list)
	for index, itemSetId in ipairs(self.itemSetOrderList) do
		local itemSet = self.itemSets[itemSetId]
		t_insert(self.controls.setSelect.list, itemSet.title or "Default")
		if itemSetId == self.activeItemSetId then
			self.controls.setSelect.selIndex = index
		end
	end

	if self.displayItem then
		local x, y = self.controls.displayItemTooltipAnchor:GetPos()
		self.displayItemTooltip:Draw(x, y, nil, nil, viewPort)
	end

	self:UpdateSockets()

	self:DrawControls(viewPort)
	if self.controls.scrollBarH:IsShown() then
		self.controls.scrollBarH:Draw(viewPort)
	end
	if self.controls.scrollBarV:IsShown() then
		self.controls.scrollBarV:Draw(viewPort)
	end
end

-- Creates a new item set
function ItemsTabClass:NewItemSet(itemSetId)
	local itemSet = { id = itemSetId }
	if not itemSetId then
		itemSet.id = 1
		while self.itemSets[itemSet.id] do
			itemSet.id = itemSet.id + 1
		end
	end
	for slotName, slot in pairs(self.slots) do
		if not slot.nodeId then
			itemSet[slotName] = { selItemId = 0 }
		end
	end
	self.itemSets[itemSet.id] = itemSet
	return itemSet
end

-- Changes the active item set
function ItemsTabClass:SetActiveItemSet(itemSetId)
	local prevSet = self.activeItemSet
	if not self.itemSets[itemSetId] then
		itemSetId = self.itemSetOrderList[1]
	end
	self.activeItemSetId = itemSetId
	self.activeItemSet = self.itemSets[itemSetId]
	local curSet = self.activeItemSet
	for slotName, slot in pairs(self.slots) do
		if not slot.nodeId then
			if prevSet then
				-- Update the previous set
				prevSet[slotName].selItemId = slot.selItemId
				prevSet[slotName].active = slot.active
			end
			-- Equip the incoming set's item
			slot.selItemId = curSet[slotName].selItemId
			slot.active = curSet[slotName].active
			if slot.controls.activate then
				slot.controls.activate.state = slot.active
			end
		end
	end
	self.build.buildFlag = true
	self:PopulateSlots()
end

-- Equips the given item in the given item set
function ItemsTabClass:EquipItemInSet(item, itemSetId)
	local itemSet = self.itemSets[itemSetId]
	local slotName = itemLib.getPrimarySlotForItem(item)
	if self.slots[slotName].weaponSet == 1 and itemSet.useSecondWeaponSet then
		-- Redirect to second weapon set
		slotName = slotName .. " Swap"
	end
	if not item.id or not self.items[item.id] then
		item = itemLib.makeItemFromRaw(self.targetVersion, item.raw)
		self:AddItem(item, true)
	end
	local altSlot = slotName:gsub("1","2")
	if IsKeyDown("SHIFT") then
		-- Redirect to second slot if possible
		if self:IsItemValidForSlot(item, altSlot, itemSet) then
			slotName = altSlot
		end
	end
	if itemSet == self.activeItemSet then
		self.slots[slotName]:SetSelItemId(item.id)
	else
		itemSet[slotName].selItemId = item.id
		if itemSet[altSlot].selItemId ~= 0 and not self:IsItemValidForSlot(self.items[itemSet[altSlot].selItemId], altSlot, itemSet) then
			itemSet[altSlot].selItemId = 0
		end
	end
	self:PopulateSlots()
	self:AddUndoState()
	self.build.buildFlag = true
end

-- Update the item lists for all the slot controls
function ItemsTabClass:PopulateSlots()
	for _, slot in pairs(self.slots) do
		slot:Populate()
	end
end

-- Updates the status and position of the socket controls
function ItemsTabClass:UpdateSockets()
	-- Build a list of active sockets
	local activeSocketList = { }
	for nodeId, slot in pairs(self.sockets) do
		if self.build.spec.allocNodes[nodeId] then
			t_insert(activeSocketList, nodeId)
			slot.inactive = false
		else
			slot.inactive = true
		end
	end
	table.sort(activeSocketList)

	-- Update the position of the active socket controls
	self.lastSlot = self.slots[baseSlots[#baseSlots]]
	for index, nodeId in ipairs(activeSocketList) do
		self.sockets[nodeId].label = "Socket #"..index
		self.sockets[nodeId].y = (#baseSlots + index - 1) * 20
		self.lastSlot = self.sockets[nodeId]
	end
end

-- Returns the slot control and equipped jewel for the given node ID
function ItemsTabClass:GetSocketAndJewelForNodeID(nodeId)
	return self.sockets[nodeId], self.items[self.sockets[nodeId].selItemId]
end

-- Adds the given item to the build's item list
function ItemsTabClass:AddItem(item, noAutoEquip, index)
	if not item.id then
		-- Find an unused item ID
		item.id = 1
		while self.items[item.id] do
			item.id = item.id + 1
		end

		if index then
			t_insert(self.itemOrderList, index, item.id)
		else
			-- Add it to the end of the display order list
			t_insert(self.itemOrderList, item.id)
		end

		if not noAutoEquip then
			-- Autoequip it
			for _, slot in ipairs(self.orderedSlots) do
				if not slot.nodeId and slot.selItemId == 0 and slot:IsShown() and self:IsItemValidForSlot(item, slot.slotName) then
					slot:SetSelItemId(item.id)
					break
				end
			end
		end
	end
	
	-- Add it to the list
	self.items[item.id] = item
	itemLib.buildItemModList(item)
end

-- Adds the current display item to the build's item list
function ItemsTabClass:AddDisplayItem(noAutoEquip)
	-- Add it to the list and clear the current display item
	self:AddItem(self.displayItem, noAutoEquip)
	self:SetDisplayItem()

	self:PopulateSlots()
	self:AddUndoState()
	self.build.buildFlag = true
end

-- Sorts the build's item list
function ItemsTabClass:SortItemList()
	table.sort(self.itemOrderList, function(a, b)
		local itemA = self.items[a]
		local itemB = self.items[b]
		local primSlotA = itemLib.getPrimarySlotForItem(itemA)
		local primSlotB = itemLib.getPrimarySlotForItem(itemB)
		if primSlotA ~= primSlotB then
			if not self.slotOrder[primSlotA] then
				return false
			elseif not self.slotOrder[primSlotB] then
				return true
			end
			return self.slotOrder[primSlotA] < self.slotOrder[primSlotB]
		end
		local equipSlotA, equipSetA = self:GetEquippedSlotForItem(itemA)
		local equipSlotB, equipSetB = self:GetEquippedSlotForItem(itemB)
		if equipSlotA and equipSlotB then
			if equipSlotA ~= equipSlotB then
				return self.slotOrder[equipSlotA.slotName] < self.slotOrder[equipSlotB.slotName]
			elseif equipSetA and not equipSetB then
				return false
			elseif not equipSetA and equipSetB then
				return true
			elseif equipSetA and equipSetB then
				return isValueInArray(self.itemSetOrderList, equipSetA.id) < isValueInArray(self.itemSetOrderList, equipSetB.id)
			end
		elseif equipSlotA then
			return true
		elseif equipSlotB then
			return false
		end
		return itemA.name < itemB.name
	end)
	self:AddUndoState()
end

-- Deletes an item
function ItemsTabClass:DeleteItem(item)
	for slotName, slot in pairs(self.slots) do
		if slot.selItemId == item.id then
			slot:SetSelItemId(0)
			self.build.buildFlag = true
		end
		if not slot.nodeId then
			for _, itemSet in pairs(self.itemSets) do
				if itemSet[slotName].selItemId == item.id then
					itemSet[slotName].selItemId = 0
					self.build.buildFlag = true
				end
			end
		end
	end
	for index, id in pairs(self.itemOrderList) do
		if id == item.id then
			t_remove(self.itemOrderList, index)
			break
		end
	end
	for _, spec in pairs(self.build.treeTab.specList) do
		for nodeId, itemId in pairs(spec.jewels) do
			if itemId == item.id then
				spec.jewels[nodeId] = 0
			end
		end
	end
	self.items[item.id] = nil
	self:PopulateSlots()
	self:AddUndoState()
end

-- Attempt to create a new item from the given item raw text and sets it as the new display item
function ItemsTabClass:CreateDisplayItemFromRaw(itemRaw, normalise)
	local newItem = itemLib.makeItemFromRaw(self.build.targetVersion, itemRaw)
	if newItem then
		if normalise then
			itemLib.normaliseQuality(newItem)
			itemLib.buildItemModList(newItem)
		end
		self:SetDisplayItem(newItem)
	end
end

-- Sets the display item to the given item
function ItemsTabClass:SetDisplayItem(item)
	self.displayItem = item
	if item then
		-- Update the display item controls
		self:UpdateDisplayItemTooltip()
		self.snapHScroll = "RIGHT"
		self.controls.displayItemVariant.list = item.variantList
		self.controls.displayItemVariant.selIndex = item.variant
		if item.crafted then
			self:UpdateAffixControls()
		end
		self:UpdateCustomControls()
		self:UpdateDisplayItemRangeLines()
	else
		self.snapHScroll = "LEFT"
	end
end

function ItemsTabClass:UpdateDisplayItemTooltip()
	self.displayItemTooltip:Clear()
	self:AddItemTooltip(self.displayItemTooltip, self.displayItem)
	self.displayItemTooltip.center = false
end

-- Update affix selection controls
function ItemsTabClass:UpdateAffixControls()
	local item = self.displayItem
	for i = 1, item.affixLimit/2 do
		self:UpdateAffixControl(self.controls["displayItemAffix"..i], item, "Prefix", "prefixes", i)
		self:UpdateAffixControl(self.controls["displayItemAffix"..(i+item.affixLimit/2)], item, "Suffix", "suffixes", i)
	end	
end

function ItemsTabClass:UpdateAffixControl(control, item, type, outputTable, outputIndex)
	local extraTags = { }
	local excludeGroups = { }
	for _, table in ipairs({"prefixes","suffixes"}) do
		for index = 1, item.affixLimit/2 do
			if index ~= outputIndex or table ~= outputTable then
				local mod = item.affixes[item[table][index] and item[table][index].modId]
				if mod then
					if mod.group then
						excludeGroups[mod.group] = true
					end
					if mod.tags then
						for _, tag in ipairs(mod.tags) do
							extraTags[tag] = true
						end
					end
				end
			end
		end
	end
	local affixList = { }
	for modId, mod in pairs(item.affixes) do
		if mod.type == type and not excludeGroups[mod.group] and itemLib.getModSpawnWeight(item, mod, extraTags) > 0 then
			t_insert(affixList, modId)
		end
	end
	table.sort(affixList, function(a, b)
		local modA = item.affixes[a]
		local modB = item.affixes[b]
		if item.type == "Flask" then
			return modA.affix < modB.affix
		end
		for i = 1, m_max(#modA, #modB) do
			if not modA[i] then
				return true
			elseif not modB[i] then
				return false
			elseif modA.statOrder[i] ~= modB.statOrder[i] then
				return modA.statOrder[i] < modB.statOrder[i]
			end
		end
		return modA.level > modB.level
	end)
	control.selIndex = 1
	control.list = { "None" }
	control.outputTable = outputTable
	control.outputIndex = outputIndex
	control.slider.shown = false
	control.slider.val = 0.5
	local selAffix = item[outputTable][outputIndex].modId
	if item.type == "Flask" or item.type == "Jewel" then
		for i, modId in pairs(affixList) do
			local mod = item.affixes[modId]
			if selAffix == modId then
				control.selIndex = i + 1
			end
			local modString = table.concat(mod, "/")
			local label = modString
			if item.type == "Flask" then
				label = mod.affix .. "   ^8[" .. modString .. "]"
			end
			control.list[i + 1] = {
				label = label,
				modList = { modId },
				modId = modId,
				haveRange = modString:match("%(%-?[%d%.]+%-[%d%.]+%)"),
			}
		end
	else
		local lastSeries
		for _, modId in ipairs(affixList) do
			local mod = item.affixes[modId]
			if not lastSeries or lastSeries.statOrderKey ~= mod.statOrderKey then
				local modString = table.concat(mod, "/")
				lastSeries = {
					label = modString,
					modList = { },
					haveRange = modString:match("%(%-?[%d%.]+%-[%d%.]+%)"),
					statOrderKey = mod.statOrderKey,
				}
				t_insert(control.list, lastSeries)
			end
			if selAffix == modId then
				control.selIndex = #control.list
			end
			t_insert(lastSeries.modList, 1, modId)
			if #lastSeries.modList == 2 then
				lastSeries.label = lastSeries.label:gsub("%d+%.?%d*","#"):gsub("%(#%-#%)","#")
				lastSeries.haveRange = true
			end
		end
	end
	if control.list[control.selIndex].haveRange then
		control.slider.divCount = #control.list[control.selIndex].modList
		control.slider.val = (isValueInArray(control.list[control.selIndex].modList, selAffix) - 1 + (item[outputTable][outputIndex].range or 0.5)) / control.slider.divCount
		if control.slider.divCount == 1 then
			control.slider.divCount = nil
		end
		control.slider.shown = true
	end
end

-- Create/update custom modifier controls
function ItemsTabClass:UpdateCustomControls()
	local item = self.displayItem
	local i = 1
	if item.rarity == "MAGIC" or item.rarity == "RARE" then
		for index, modLine in ipairs(item.modLines) do
			if index > item.implicitLines and (modLine.custom or modLine.crafted) then
				local line = itemLib.formatModLine(modLine)
				if line then
					if not self.controls["displayItemCustomModifier"..i] then
						self.controls["displayItemCustomModifier"..i] = common.New("LabelControl", {"TOPLEFT",self.controls.displayItemSectionCustom,"TOPLEFT"}, 55, i * 22 + 4, 0, 16)
						self.controls["displayItemCustomModifierLabel"..i] = common.New("LabelControl", {"RIGHT",self.controls["displayItemCustomModifier"..i],"LEFT"}, -2, 0, 0, 16)
						self.controls["displayItemCustomModifierRemove"..i] = common.New("ButtonControl", {"LEFT",self.controls["displayItemCustomModifier"..i],"RIGHT"}, 4, 0, 70, 20, "^7Remove")
					end
					self.controls["displayItemCustomModifier"..i].shown = true
					local label = itemLib.formatModLine(modLine)
					if DrawStringCursorIndex(16, "VAR", label, 330, 10) < #label then
						label = label:sub(1, DrawStringCursorIndex(16, "VAR", label, 310, 10)) .. "..."
					end
					self.controls["displayItemCustomModifier"..i].label = label
					self.controls["displayItemCustomModifierLabel"..i].label = modLine.crafted and "^7Crafted:" or "^7Custom:"
					self.controls["displayItemCustomModifierRemove"..i].onClick = function()
						t_remove(item.modLines, index)
						local id = item.id
						self:CreateDisplayItemFromRaw(itemLib.createItemRaw(item))
						self.displayItem.id = id
					end				
					i = i + 1
				end
			end
		end
	end
	item.customCount = i - 1
	while self.controls["displayItemCustomModifier"..i] do
		self.controls["displayItemCustomModifier"..i].shown = false
		i = i + 1
	end
end

-- Updates the range line dropdown and range slider for the current display item
function ItemsTabClass:UpdateDisplayItemRangeLines()
	if self.displayItem and self.displayItem.rangeLineList[1] then
		wipeTable(self.controls.displayItemRangeLine.list)
		for _, modLine in ipairs(self.displayItem.rangeLineList) do
			t_insert(self.controls.displayItemRangeLine.list, modLine.line)
		end
		self.controls.displayItemRangeLine.selIndex = 1
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[1].range
	end
end

-- Returns the first slot in which the given item is equipped
function ItemsTabClass:GetEquippedSlotForItem(item)
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.inactive then
			if slot.selItemId == item.id then
				return slot
			end
			for _, itemSetId in ipairs(self.itemSetOrderList) do
				local itemSet = self.itemSets[itemSetId]
				if itemSetId ~= self.activeItemSetId and itemSet[slot.slotName] and itemSet[slot.slotName].selItemId == item.id then
					return slot, itemSet
				end
			end
		end
	end
end

-- Check if the given item could be equipped in the given slot, taking into account possible conflicts with currently equipped items
-- For example, a shield is not valid for Weapon 2 if Weapon 1 is a staff, and a wand is not valid for Weapon 2 if Weapon 1 is a dagger
function ItemsTabClass:IsItemValidForSlot(item, slotName, itemSet)
	itemSet = itemSet or self.activeItemSet
	if item.type == slotName:gsub(" %d+","") then
		return true
	elseif slotName == "Weapon 1" or slotName == "Weapon 1 Swap" or slotName == "Weapon" then
		return item.base.weapon ~= nil
	elseif slotName == "Weapon 2" or slotName == "Weapon 2 Swap" then
		local weapon1Sel = itemSet[slotName == "Weapon 2" and "Weapon 1" or "Weapon 1 Swap"].selItemId or 0
		local weapon1Type = weapon1Sel > 0 and self.items[weapon1Sel].base.type or "None"
		if weapon1Type == "None" then
			return item.type == "Quiver" or item.type == "Shield" or (self.build.data.weaponTypeInfo[item.type] and self.build.data.weaponTypeInfo[item.type].oneHand)
		elseif weapon1Type == "Bow" then
			return item.type == "Quiver"
		elseif self.build.data.weaponTypeInfo[weapon1Type].oneHand then
			return item.type == "Shield" or (self.build.data.weaponTypeInfo[item.type] and self.build.data.weaponTypeInfo[item.type].oneHand and ((weapon1Type == "Wand" and item.type == "Wand") or (weapon1Type ~= "Wand" and item.type ~= "Wand")))
		end
	end
end

-- Opens the item set manager
function ItemsTabClass:OpenItemSetManagePopup()
	local controls = { }
	controls.setList = common.New("ItemSetList", nil, -155, 50, 300, 200, self)
	controls.sharedList = common.New("SharedItemSetList", nil, 155, 50, 300, 200, self)
	controls.setList.dragTargetList = { controls.sharedList }
	controls.sharedList.dragTargetList = { controls.setList }
	controls.close = common.New("ButtonControl", nil, 0, 260, 90, 20, "Done", function()
		main:ClosePopup()
	end)
	main:OpenPopup(630, 290, "Manage Item Sets", controls)
end

-- Opens the item crafting popup
function ItemsTabClass:CraftItem()
	local controls = { }
	local function makeItem(base)
		local item = { name = base.name, base = base.base, baseName = base.name, modLines = { }, quality = 0 }
		local raritySel = controls.rarity.selIndex
		if base.base.flask then
			if raritySel == 3 then
				raritySel = 2
			end
		end
		if raritySel == 2 or raritySel == 3 then
			item.crafted = true
		end
		item.rarity = controls.rarity.list[raritySel].rarity
		if raritySel >= 3 then
			item.title = controls.title.buf:match("%S") and controls.title.buf or "New Item"
		end
		item.implicitLines = 0
		if base.base.implicit then
			for line in base.base.implicit:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod[self.build.targetVersion](line)
				t_insert(item.modLines, { line = line, extra = extra, modList = modList or { } })
				item.implicitLines = item.implicitLines + 1
			end
		end
		itemLib.normaliseQuality(item)
		return itemLib.makeItemFromRaw(self.build.targetVersion, itemLib.createItemRaw(item))
	end
	controls.rarityLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 20, 0, 16, "Rarity:")
	controls.rarity = common.New("DropDownControl", nil, -80, 20, 100, 18, rarityDropList)
	controls.rarity.selIndex = self.lastCraftRaritySel or 3
	controls.title = common.New("EditControl", nil, 70, 20, 190, 18, "", "Name")
	controls.title.shown = function()
		return controls.rarity.selIndex >= 3
	end
	controls.typeLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 45, 0, 16, "Type:")
	controls.type = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 55, 45, 295, 18, self.baseTypeList, function(index, value)
		controls.base.list = self.baseLists[self.baseTypeList[index]]
		controls.base.selIndex = 1
	end)
	controls.type.selIndex = self.lastCraftTypeSel or 1
	controls.baseLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 70, 0, 16, "Base:")
	controls.base = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 55, 70, 200, 18, self.baseLists[self.baseTypeList[controls.type.selIndex]])
	controls.base.selIndex = self.lastCraftBaseSel or 1
	controls.base.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" then
			self:AddItemTooltip(tooltip, makeItem(value), nil, true)
		end
	end
	controls.save = common.New("ButtonControl", nil, -45, 100, 80, 20, "Create", function()
		main:ClosePopup()
		local item = makeItem(controls.base.list[controls.base.selIndex])
		self:SetDisplayItem(item)
		if not item.crafted and item.rarity ~= "NORMAL" then
			self:EditDisplayItemText()
		end
		self.lastCraftRaritySel = controls.rarity.selIndex
		self.lastCraftTypeSel = controls.type.selIndex
		self.lastCraftBaseSel = controls.base.selIndex
	end)
	controls.cancel = common.New("ButtonControl", nil, 45, 100, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 130, "Craft Item", controls)
end

-- Opens the item text editor popup
function ItemsTabClass:EditDisplayItemText()
	local controls = { }
	local function buildRaw()
		local editBuf = controls.edit.buf
		if editBuf:match("^Rarity: ") then
			return editBuf
		else
			return "Rarity: "..controls.rarity.list[controls.rarity.selIndex].rarity.."\n"..controls.edit.buf
		end
	end
	controls.rarity = common.New("DropDownControl", nil, -190, 10, 100, 18, rarityDropList)
	controls.edit = common.New("EditControl", nil, 0, 40, 480, 420, "", nil, "^%C\t\n", nil, nil, 14)
	if self.displayItem then
		controls.edit:SetText(itemLib.createItemRaw(self.displayItem):gsub("Rarity: %w+\n",""))
		controls.rarity:SelByValue(self.displayItem.rarity, "rarity")
	else
		controls.rarity.selIndex = 3
	end
	controls.edit.font = "FIXED"
	controls.edit.pasteFilter = function(text)
		return text:gsub("\246","o")
	end
	controls.save = common.New("ButtonControl", nil, -45, 470, 80, 20, self.displayItem and "Save" or "Create", function()
		local id = self.displayItem and self.displayItem.id
		self:CreateDisplayItemFromRaw(buildRaw(), not self.displayItem)
		self.displayItem.id = id
		main:ClosePopup()
	end)
	controls.save.enabled = function()
		local item = itemLib.makeItemFromRaw(self.build.targetVersion, buildRaw())
		return item ~= nil
	end
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		local item = itemLib.makeItemFromRaw(self.build.targetVersion, buildRaw())
		if item then
			self:AddItemTooltip(tooltip, item, nil, true)
		else
			tooltip:AddLine(14, "The item is invalid.")
			tooltip:AddLine(14, "Check that the item's title and base name are in the correct format.")
			tooltip:AddLine(14, "For Rare and Unique items, the first 2 lines must be the title and base name. E.g:")
			tooltip:AddLine(14, "Abberath's Horn")
			tooltip:AddLine(14, "Goat's Horn")
			tooltip:AddLine(14, "For Normal and Magic items, the base name must be somewhere in the first line. E.g:")
			tooltip:AddLine(14, "Scholar's Platinum Kris of Joy")
		end
	end	
	controls.cancel = common.New("ButtonControl", nil, 45, 470, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 500, self.displayItem and "Edit Item Text" or "Create Custom Item from Text", controls, nil, "edit")
end

-- Opens the item enchanting popup
function ItemsTabClass:EnchantDisplayItem()
	local controls = { } 
	local enchantments = self.displayItem.enchantments
	local haveSkills = not self.displayItem.enchantments[self.build.data.labyrinths[1].name]
	local skillList = { }
	local skillsUsed = { }
	if haveSkills then
		for _, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			for _, gem in ipairs(socketGroup.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support and enchantments[gem.grantedEffect.name] then
					skillsUsed[gem.grantedEffect.name] = true
				end
			end
		end
	end
	local function buildSkillList(onlyUsedSkills)
		wipeTable(skillList)
		for skillName in pairs(enchantments) do
			if not onlyUsedSkills or not next(skillsUsed) or skillsUsed[skillName] then
				t_insert(skillList, skillName)
			end
		end
		table.sort(skillList)
	end
	local labyrinthList = { }
	local function buildLabyrinthList()
		wipeTable(labyrinthList)
		local list = haveSkills and enchantments[skillList[controls.skill and controls.skill.selIndex or 1]] or enchantments
		for _, lab in ipairs(self.build.data.labyrinths) do
			if list[lab.name] then
				t_insert(labyrinthList, lab)
			end
		end
	end
	local enchantmentList = { }
	local function buildEnchantmentList()
		wipeTable(enchantmentList)
		local list = haveSkills and enchantments[skillList[controls.skill and controls.skill.selIndex or 1]] or enchantments
		for _, enchantment in ipairs(list[labyrinthList[controls.labyrinth and controls.labyrinth.selIndex or 1].name]) do
			t_insert(enchantmentList, enchantment)
		end
	end
	if haveSkills then
		buildSkillList(true)
	end
	buildLabyrinthList()
	buildEnchantmentList()
	local function enchantItem()
		local item = itemLib.makeItemFromRaw(self.build.targetVersion, itemLib.createItemRaw(self.displayItem))
		item.id = self.displayItem.id
		for i = 1, item.implicitLines do 
			t_remove(item.modLines, 1)
		end
		local list = haveSkills and enchantments[controls.skill.list[controls.skill.selIndex]] or enchantments
		t_insert(item.modLines, 1, { crafted = true, line = list[controls.labyrinth.list[controls.labyrinth.selIndex].name][controls.enchantment.selIndex] })
		item.implicitLines = 1
		item.raw = itemLib.createItemRaw(item)
		itemLib.parseItemRaw(item)
		return item
	end
	if haveSkills then
		controls.skillLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 20, 0, 16, "^7Skill:")
		controls.skill = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 20, 180, 18, skillList, function(index, value)
			buildLabyrinthList()
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
		end)
		controls.allSkills = common.New("CheckBoxControl", {"TOPLEFT",nil,"TOPLEFT"}, 350, 20, 18, "All skills:", function(state)
			buildSkillList(not state)
			controls.skill:SetSel(1)
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
		end)
		controls.allSkills.tooltipText = "Show all skills, not just those used by this build."
		if not next(skillsUsed) then
			controls.allSkills.state = true
			controls.allSkills.enabled = false
		end
	end
	controls.labyrinthLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 45, 0, 16, "^7Labyrinth:")
	controls.labyrinth = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 45, 100, 18, labyrinthList, function(index, value)
		buildEnchantmentList()
	end)
	controls.enchantmentLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 70, 0, 16, "^7Enchantment:")
	controls.enchantment = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 70, 440, 18, enchantmentList)
	controls.save = common.New("ButtonControl", nil, -45, 100, 80, 20, "Enchant", function()
		self:SetDisplayItem(enchantItem())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, enchantItem(), nil, true)
	end	
	controls.close = common.New("ButtonControl", nil, 45, 100, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(550, 130, "Enchant Item", controls)
end

-- Opens the item corrupting popup
function ItemsTabClass:CorruptDisplayItem()
	local controls = { } 
	local implicitList = { }
	for modId, mod in pairs(self.build.data.corruptedMods) do
		if itemLib.getModSpawnWeight(self.displayItem, mod) > 0 then
			t_insert(implicitList, mod)
		end
	end
	table.sort(implicitList, function(a, b)
		local an = a[1]:lower():gsub("%(.-%)","$"):gsub("[%+%-%%]",""):gsub("%d+","$")
		local bn = b[1]:lower():gsub("%(.-%)","$"):gsub("[%+%-%%]",""):gsub("%d+","$")
		if an ~= bn then
			return an < bn
		else
			return a.level < b.level
		end
	end)
	local function corruptItem()
		local item = itemLib.makeItemFromRaw(self.build.targetVersion, itemLib.createItemRaw(self.displayItem))
		item.id = self.displayItem.id
		item.corrupted = true
		if controls.implicit.selIndex > 1 then
			for i = 1, item.implicitLines do 
				t_remove(item.modLines, 1)
			end
			local mod = implicitList[controls.implicit.selIndex - 1]
			for _, modLine in ipairs(mod) do
				t_insert(item.modLines, 1, { line = modLine })
			end
			item.implicitLines = #mod
		end
		item.raw = itemLib.createItemRaw(item)
		itemLib.parseItemRaw(item)
		return item
	end
	controls.implicitLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 65, 20, 0, 16, "^7Implicit:")
	controls.implicit = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 70, 20, 450, 18, { "None" })
	for _, mod in ipairs(implicitList) do
		t_insert(controls.implicit.list, table.concat(mod, "/"))
	end
	controls.save = common.New("ButtonControl", nil, -45, 50, 80, 20, "Corrupt", function()
		self:SetDisplayItem(corruptItem())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, corruptItem(), nil, true)
	end	
	controls.close = common.New("ButtonControl", nil, 45, 50, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(540, 80, "Corrupt Item", controls)
end

-- Opens the custom modifier popup
function ItemsTabClass:AddCustomModifierToDisplayItem()
	local controls = { }
	local sourceList = { }
	local modList = { }
	local function buildMods(sourceId)
		wipeTable(modList)
		if sourceId == "MASTER" then
			for _, craft in ipairs(self.build.data.masterMods) do
				if craft.types[self.displayItem.type] then
					t_insert(modList, {
						label = craft.master .. " " .. craft.masterLevel .. "   "..craft.type:sub(1,3).."^8[" .. table.concat(craft, "/") .. "]",
						mod = craft,
						type = "crafted",
					})
				end
			end
		elseif sourceId == "ESSENCE" then
			for _, essence in pairs(self.build.data.essences) do
				local modId = essence.mods[self.displayItem.type]
				local mod = self.displayItem.affixes[modId]
				t_insert(modList, {
					label = essence.name .. "   "..mod.type:sub(1,3).."^8[" .. table.concat(mod, "/") .. "]",
					mod = mod,
					type = "custom",
					essence = essence,
				})
			end
			table.sort(modList, function(a, b)
				if a.essence.type ~= b.essence.type then
					return a.essence.type > b.essence.type 
				else
					return a.essence.tier > b.essence.tier
				end
			end)
		elseif sourceId == "PREFIX" or sourceId == "SUFFIX" then
			for _, mod in pairs(self.displayItem.affixes) do
				if sourceId:lower() == mod.type:lower() and itemLib.getModSpawnWeight(self.displayItem, mod) > 0 then
					t_insert(modList, {
						label = mod.affix .. "   ^8[" .. table.concat(mod, "/") .. "]",
						mod = mod,
						type = "custom",
					})
				end
			end
			table.sort(modList, function(a, b) 
				local modA = a.mod
				local modB = b.mod
				for i = 1, m_max(#modA, #modB) do
					if not modA[i] then
						return true
					elseif not modB[i] then
						return false
					elseif modA.statOrder[i] ~= modB.statOrder[i] then
						return modA.statOrder[i] < modB.statOrder[i]
					end
				end
				return modA.level > modB.level
			end)
		end
	end
	if self.displayItem.type ~= "Jewel" and self.displayItem.type ~= "Flask" then
		t_insert(sourceList, { label = "Master", sourceId = "MASTER" })
		t_insert(sourceList, { label = "Essence", sourceId = "ESSENCE" })
	end
	if not self.displayItem.crafted then
		t_insert(sourceList, { label = "Prefix", sourceId = "PREFIX" })
		t_insert(sourceList, { label = "Suffix", sourceId = "SUFFIX" })
	end
	t_insert(sourceList, { label = "Custom", sourceId = "CUSTOM" })
	buildMods(sourceList[1].sourceId)
	local function addModifier()
		local item = itemLib.makeItemFromRaw(self.build.targetVersion, itemLib.createItemRaw(self.displayItem))
		item.id = self.displayItem.id
		local sourceId = sourceList[controls.source.selIndex].sourceId
		if sourceId == "CUSTOM" then
			if controls.custom.buf:match("%S") then
				t_insert(item.modLines, { line = controls.custom.buf, custom = true })
			end
		else
			local listMod = modList[controls.modSelect.selIndex]
			for _, line in ipairs(listMod.mod) do
				t_insert(item.modLines, { line = line, [listMod.type] = true })
			end
		end
		item.raw = itemLib.createItemRaw(item)
		itemLib.parseItemRaw(item)
		return item
	end
	controls.sourceLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 20, 0, 16, "^7Source:")
	controls.source = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 20, 100, 18, sourceList, function(index, value)
		buildMods(value.sourceId)
		controls.modSelect:SetSel(1)
	end)
	controls.source.enabled = #sourceList > 1
	controls.modSelectLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 45, 0, 16, "^7Modifier:")
	controls.modSelect = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 45, 600, 18, modList)
	controls.modSelect.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.modSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" then
			for _, line in ipairs(value.mod) do
				tooltip:AddLine(16, "^7"..line)
			end
		end
	end
	controls.custom = common.New("EditControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 45, 440, 18)
	controls.custom.shown = function()
		return sourceList[controls.source.selIndex].sourceId == "CUSTOM"
	end
	controls.save = common.New("ButtonControl", nil, -45, 75, 80, 20, "Add", function()
		self:SetDisplayItem(addModifier())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, addModifier())
	end	
	controls.close = common.New("ButtonControl", nil, 45, 75, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(710, 105, "Add Modifier to Item", controls, "save", sourceList[controls.source.selIndex].sourceId == "CUSTOM" and "custom")	
end

function ItemsTabClass:AddItemSetTooltip(tooltip, itemSet)
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.nodeId then
			local item = self.items[itemSet[slot.slotName].selItemId]
			if item then
				tooltip:AddLine(16, s_format("^7%s: %s%s", slot.label, colorCodes[item.rarity], item.name))
			end
		end
	end
end

function ItemsTabClass:AddItemTooltip(tooltip, item, slot, dbMode)
	-- Item name
	local rarityCode = colorCodes[item.rarity]
	tooltip.center = true
	tooltip.color = rarityCode
	if item.title then
		tooltip:AddLine(20, rarityCode..item.title)
		tooltip:AddLine(20, rarityCode..item.baseName:gsub(" %(.+%)",""))
	else
		tooltip:AddLine(20, rarityCode..item.namePrefix..item.baseName:gsub(" %(.+%)","")..item.nameSuffix)
	end
	tooltip:AddSeparator(10)

	-- Special fields for database items
	if dbMode then
		if item.variantList then
			if #item.variantList == 1 then
				tooltip:AddLine(16, "^xFFFF30Variant: "..item.variantList[1])
			else
				tooltip:AddLine(16, "^xFFFF30Variant: "..item.variantList[item.variant].." ("..#item.variantList.." variants)")
			end
		end
		if item.league then
			tooltip:AddLine(16, "^xFF5555Exclusive to: "..item.league)
		end
		if item.unreleased then
			tooltip:AddLine(16, "^1Not yet available")
		end
		tooltip:AddSeparator(10)
	end

	local base = item.base
	local slotNum = slot and slot.slotNum or (IsKeyDown("SHIFT") and 2 or 1)
	local modList = item.modList or item.slotModList[slotNum]
	if base.weapon then
		-- Weapon-specific info
		local weaponData = item.weaponData[slotNum]
		tooltip:AddLine(16, s_format("^x7F7F7F%s", self.build.data.weaponTypeInfo[base.type].label or base.type))
		if item.quality > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality))
		end
		local totalDamageTypes = 0
		if weaponData.PhysicalDPS then
			tooltip:AddLine(16, s_format("^x7F7F7FPhysical Damage: "..colorCodes.MAGIC.."%d-%d (%.1f DPS)", weaponData.PhysicalMin, weaponData.PhysicalMax, weaponData.PhysicalDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		if weaponData.ElementalDPS then
			local elemLine
			for _, var in ipairs({"Fire","Cold","Lightning"}) do
				if weaponData[var.."DPS"] then
					elemLine = elemLine and elemLine.."^x7F7F7F, " or "^x7F7F7FElemental Damage: "
					elemLine = elemLine..s_format("%s%d-%d", colorCodes[var:upper()], weaponData[var.."Min"], weaponData[var.."Max"])
				end
			end
			tooltip:AddLine(16, elemLine)
			tooltip:AddLine(16, s_format("^x7F7F7FElemental DPS: "..colorCodes.MAGIC.."%.1f", weaponData.ElementalDPS))
			totalDamageTypes = totalDamageTypes + 1	
		end
		if weaponData.ChaosDPS then
			tooltip:AddLine(16, s_format("^x7F7F7FChaos Damage: "..colorCodes.CHAOS.."%d-%d "..colorCodes.MAGIC.."(%.1f DPS)", weaponData.ChaosMin, weaponData.ChaosMax, weaponData.ChaosDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		if totalDamageTypes > 1 then
			tooltip:AddLine(16, s_format("^x7F7F7FTotal DPS: "..colorCodes.MAGIC.."%.1f", weaponData.TotalDPS))
		end
		tooltip:AddLine(16, s_format("^x7F7F7FCritical Strike Chance: %s%.2f%%", main:StatColor(weaponData.CritChance, base.weapon.CritChanceBase), weaponData.CritChance))
		tooltip:AddLine(16, s_format("^x7F7F7FAttacks per Second: %s%.2f", main:StatColor(weaponData.AttackRate, base.weapon.AttackRateBase), weaponData.AttackRate))
		if weaponData.range then
			tooltip:AddLine(16, s_format("^x7F7F7FWeapon Range: %s%d", main:StatColor(weaponData.range, self.build.data.weaponTypeInfo[base.type].range), weaponData.range))
		end
	elseif base.armour then
		-- Armour-specific info
		local armourData = item.armourData
		if item.quality > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality))
		end
		if base.armour.BlockChance and armourData.BlockChance > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FChance to Block: %s%d%%", main:StatColor(armourData.BlockChance, base.armour.BlockChance), armourData.BlockChance))
		end
		if armourData.Armour > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FArmour: %s%d", main:StatColor(armourData.Armour, base.armour.ArmourBase), armourData.Armour))
		end
		if armourData.Evasion > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FEvasion Rating: %s%d", main:StatColor(armourData.Evasion, base.armour.EvasionBase), armourData.Evasion))
		end
		if armourData.EnergyShield > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FEnergy Shield: %s%d", main:StatColor(armourData.EnergyShield, base.armour.EnergyShieldBase), armourData.EnergyShield))
		end
	elseif base.flask then
		-- Flask-specific info
		local flaskData = item.flaskData
		if item.quality > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality))
		end
		if flaskData.lifeTotal then
			tooltip:AddLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FLife over %s%.1f0 ^x7F7F7FSeconds",
				main:StatColor(flaskData.lifeTotal, base.flask.life), flaskData.lifeTotal,
				main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration
			))
		end
		if flaskData.manaTotal then
			tooltip:AddLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FMana over %s%.1f0 ^x7F7F7FSeconds",
				main:StatColor(flaskData.manaTotal, base.flask.mana), flaskData.manaTotal, 
				main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration
			))
		end
		if not flaskData.lifeTotal and not flaskData.manaTotal then
			tooltip:AddLine(16, s_format("^x7F7F7FLasts %s%.2f ^x7F7F7FSeconds", main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration))
		end
		tooltip:AddLine(16, s_format("^x7F7F7FConsumes %s%d ^x7F7F7Fof %s%d ^x7F7F7FCharges on use",
			main:StatColor(flaskData.chargesUsed, base.flask.chargesUsed), flaskData.chargesUsed,
			main:StatColor(flaskData.chargesMax, base.flask.chargesMax), flaskData.chargesMax
		))
		for _, modLine in pairs(item.modLines) do
			if modLine.buff then
				tooltip:AddLine(16, (modLine.extra and colorCodes.UNSUPPORTED or colorCodes.MAGIC) .. modLine.line)
			end
		end
	elseif item.type == "Jewel" then
		-- Jewel-specific info
		if item.limit then
			tooltip:AddLine(16, "^x7F7F7FLimited to: ^7"..item.limit)
		end
		if item.jewelRadiusIndex then
			tooltip:AddLine(16, "^x7F7F7FRadius: ^7"..data.jewelRadius[item.jewelRadiusIndex].label)
		end
		if item.jewelRadiusData and slot and item.jewelRadiusData[slot.nodeId] then
			local radiusData = item.jewelRadiusData[slot.nodeId]
			local line
			local codes = { colorCodes.MARAUDER, colorCodes.RANGER, colorCodes.WITCH }
			for i, stat in ipairs({"Str","Dex","Int"}) do
				if radiusData[stat] and radiusData[stat] ~= 0 then
					line = (line and line .. ", " or "") .. s_format("%s%d %s^7", codes[i], radiusData[stat], stat)
				end
			end
			if line then
				tooltip:AddLine(16, "^x7F7F7FAllocated in Radius: "..line)
			end
		end
	end
	tooltip:AddSeparator(10)

	-- Requirements
	self.build:AddRequirementsToTooltip(tooltip, item.requirements.level,
		item.requirements.strMod, item.requirements.dexMod, item.requirements.intMod, 
		item.requirements.str or 0, item.requirements.dex or 0, item.requirements.int or 0)

	-- Implicit/explicit modifiers
	if item.modLines[1] then
		for index, modLine in pairs(item.modLines) do
			if not modLine.buff and (not modLine.variantList or modLine.variantList[item.variant]) then
				tooltip:AddLine(16, itemLib.formatModLine(modLine, dbMode))
			end
			if index == item.implicitLines + item.buffLines and item.modLines[index + 1] then
				-- Add separator between implicit and explicit modifiers
				tooltip:AddSeparator(10)
			end
		end
	end

	-- Corrupted item label
	if item.corrupted then
		if #item.modLines == item.implicitLines + item.buffLines then
			tooltip:AddSeparator(10)
		end
		tooltip:AddLine(16, "^1Corrupted")
	end
	tooltip:AddSeparator(14)

	-- Stat differences
	local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator()
	if base.flask then
		-- Special handling for flasks
		local stats = { }
		local flaskData = item.flaskData
		local modDB = self.build.calcsTab.mainEnv.modDB
		local durInc = modDB:Sum("INC", nil, "FlaskDuration")
		local effectInc = modDB:Sum("INC", nil, "FlaskEffect")
		if item.base.flask.life or item.base.flask.mana then
			local rateInc = modDB:Sum("INC", nil, "FlaskRecoveryRate")
			local instantPerc = flaskData.instantPerc > 0 and m_min(flaskData.instantPerc + effectInc, 100) or 0
			if item.base.flask.life then
				local lifeInc = modDB:Sum("INC", nil, "FlaskLifeRecovery")
				local lifeRateInc = modDB:Sum("INC", nil, "FlaskLifeRecoveryRate")
				local inst = flaskData.lifeBase * instantPerc / 100 * (1 + lifeInc / 100) * (1 + effectInc / 100)
				local grad = flaskData.lifeBase * (1 - instantPerc / 100) * (1 + lifeInc / 100) * (1 + effectInc / 100) * (1 + durInc / 100)
				local lifeDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + lifeRateInc / 100)
				if inst > 0 and grad > 0 then
					t_insert(stats, s_format("^8Life recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, lifeDur))
				elseif inst + grad ~= flaskData.lifeTotal then
					if inst > 0 then
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8instantly", inst))
					elseif grad > 0 then
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8over ^7%.2fs", grad, lifeDur))
					end
				end
			end
			if item.base.flask.mana then
				local manaInc = modDB:Sum("INC", nil, "FlaskManaRecovery")
				local manaRateInc = modDB:Sum("INC", nil, "FlaskManaRecoveryRate")
				local inst = flaskData.manaBase * instantPerc / 100 * (1 + manaInc / 100) * (1 + effectInc / 100)
				local grad = flaskData.manaBase * (1 - instantPerc / 100) * (1 + manaInc / 100) * (1 + effectInc / 100) * (1 + durInc / 100)
				local manaDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + manaRateInc / 100)
				if inst > 0 and grad > 0 then
					t_insert(stats, s_format("^8Mana recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, manaDur))
				elseif inst + grad ~= flaskData.manaTotal then
					if inst > 0 then
						t_insert(stats, s_format("^8Mana recovered: ^7%d ^8instantly", inst))
					elseif grad > 0 then
						t_insert(stats, s_format("^8Mana recovered: ^7%d ^8over ^7%.2fs", grad, manaDur))
					end
				end
			end
		else
			if durInc ~= 0 then
				t_insert(stats, s_format("^8Flask effect duration: ^7%.1f0s", flaskData.duration * (1 + durInc / 100)))
			end
		end
		local effectMod = 1 + (flaskData.effectInc + effectInc) / 100
		if effectMod ~= 1 then
			t_insert(stats, s_format("^8Flask effect modifier: ^7%+d%%", effectMod * 100 - 100))
		end
		local usedInc = modDB:Sum("INC", nil, "FlaskChargesUsed")
		if usedInc ~= 0 then
			local used = m_floor(flaskData.chargesUsed * (1 + usedInc / 100))
			t_insert(stats, s_format("^8Charges used: ^7%d ^8of ^7%d ^8(^7%d ^8uses)", used, flaskData.chargesMax, m_floor(flaskData.chargesMax / used)))
		end
		local gainMod = flaskData.gainMod * (1 + modDB:Sum("INC", nil, "FlaskChargesGained") / 100)
		if gainMod ~= 1 then
			t_insert(stats, s_format("^8Charge gain modifier: ^7%+d%%", gainMod * 100 - 100))
		end
		if stats[1] then
			tooltip:AddLine(14, "^7Effective flask stats:")
			for _, stat in ipairs(stats) do
				tooltip:AddLine(14, stat)
			end
		end
		local output = calcFunc({ toggleFlask = item })
		local header
		if self.build.calcsTab.mainEnv.flasks[item] then
			header = "^7Deactivating this flask will give you:"
		else
			header = "^7Activating this flask will give you:"
		end
		self.build:AddStatComparesToTooltip(tooltip, calcBase, output, header)
	else
		self:UpdateSockets()
		-- Build sorted list of slots to compare with
		local compareSlots = { }
		for slotName, slot in pairs(self.slots) do
			if self:IsItemValidForSlot(item, slotName) and not slot.inactive and (not slot.weaponSet or slot.weaponSet == (self.activeItemSet.useSecondWeaponSet and 2 or 1)) then
				t_insert(compareSlots, slot)
			end
		end
		table.sort(compareSlots, function(a, b)
			if a.selItemId ~= b.selItemId then
				if item == self.items[a.selItemId] then
					return true
				elseif item == self.items[b.selItemId] then
					return false
				end
			end
			local aNum = tonumber(a.slotName:match("%d+"))
			local bNum = tonumber(b.slotName:match("%d+"))
			if aNum and bNum then
				return aNum < bNum
			else
				return a.slotName < b.slotName
			end
		end)

		-- Add comparisons for each slot
		for _, slot in pairs(compareSlots) do
			local selItem = self.items[slot.selItemId]
			local output = calcFunc({ repSlotName = slot.slotName, repItem = item ~= selItem and item })
			local header
			if item == selItem then
				header = "^7Removing this item from "..slot.label.." will give you:"
			else
				header = string.format("^7Equipping this item in %s will give you:%s", slot.label, selItem and "\n(replacing "..colorCodes[selItem.rarity]..selItem.name.."^7)" or "")
			end
			self.build:AddStatComparesToTooltip(tooltip, calcBase, output, header)
		end
	end

	if launch.devModeAlt then
		-- Modifier debugging info
		tooltip:AddSeparator(10)
		for _, mod in ipairs(modList) do
			tooltip:AddLine(14, "^7"..modLib.formatMod(mod))
		end
	end
end

function ItemsTabClass:CreateUndoState()
	local state = { }
	state.activeItemSetId = self.activeItemSetId
	state.items = copyTable(self.items)
	state.itemOrderList = copyTable(self.itemOrderList)
	state.slotSelItemId = { }
	for slotName, slot in pairs(self.slots) do
		state.slotSelItemId[slotName] = slot.selItemId
	end
	state.itemSets = copyTable(self.itemSets)
	state.itemSetOrderList = copyTable(self.itemSetOrderList)
	return state
end

function ItemsTabClass:RestoreUndoState(state)
	self.items = state.items
	wipeTable(self.itemOrderList)
	for k, v in pairs(state.itemOrderList) do
		self.itemOrderList[k] = v
	end
	for slotName, selItemId in pairs(state.slotSelItemId) do
		self.slots[slotName]:SetSelItemId(selItemId)
	end
	self.itemSets = state.itemSets
	wipeTable(self.itemSetOrderList)
	for k, v in pairs(state.itemSetOrderList) do
		self.itemSetOrderList[k] = v
	end
	self.activeItemSetId = state.activeItemSetId
	self.activeItemSet = self.itemSets[self.activeItemSetId]
	self:PopulateSlots()
end
