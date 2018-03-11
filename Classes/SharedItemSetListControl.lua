-- Path of Building
--
-- Class: Shared Item Set List
-- Shared item set list control.
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local s_format = string.format

local SharedItemSetListClass = common.NewClass("SharedItemSetList", "ListControl", function(self, anchor, x, y, width, height, itemsTab)
	self.ListControl(anchor, x, y, width, height, 16, true, main.sharedItemSetList)
	self.itemsTab = itemsTab
	self.defaultText = "^x7F7F7FThis is a list of item sets that will be shared\nbetween all of your builds.\nYou can add sets to this list by dragging them\nfrom the build's set list."
	self.controls.delete = common.New("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, 2, -4, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.rename = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOP"}, -2, -4, 60, 18, "Rename", function()
		self:RenameSet(self.selValue)
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
end)

function SharedItemSetListClass:RenameSet(sharedItemSet)
	local controls = { }
	controls.label = common.New("LabelControl", nil, 0, 20, 0, 16, "^7Enter name for this item set:")
	controls.edit = common.New("EditControl", nil, 0, 40, 350, 20, sharedItemSet.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = common.New("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
		sharedItemSet.title = controls.edit.buf
		self.itemsTab.modFlag = true
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = common.New("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, sharedItemSet.title and "Rename" or "Set Name", controls, "save", "edit")
end

function SharedItemSetListClass:GetRowValue(column, index, sharedItemSet)
	if column == 1 then
		return sharedItemSet.title or "Default"
	end
end

function SharedItemSetListClass:AddValueTooltip(tooltip, index, sharedItemSet)
	tooltip:Clear()
	for _, slot in ipairs(self.itemsTab.orderedSlots) do
		if not slot.nodeId then
			local slotName = slot.slotName
			local item = sharedItemSet.slots[slotName] and sharedItemSet.slots[slotName][self.itemsTab.build.targetVersion]
			if item then
				tooltip:AddLine(16, s_format("^7%s: %s%s", self.itemsTab.slots[slotName].label, colorCodes[item.rarity], item.name))
			end
		end
	end
end

function SharedItemSetListClass:GetDragValue(index, value)
	return "SharedItemListControl", value
end

function SharedItemSetListClass:CanReceiveDrag(type, value)
	return type == "ItemListControl"
end

function SharedItemSetListClass:ReceiveDrag(type, value, source)
	if type == "ItemListControl" then
		local sharedItemList = { title = value.title, slots = { } }
		for slotName, slot in pairs(self.itemsTab.slots) do
			if not slot.nodeId then
				if value ~= self.itemsTab.activeItemSet then
					slot = value[slotName]
				end
				if slot.selItemId ~= 0 then
					local item = self.itemsTab.items[slot.selItemId]
					local verItem = { raw = item:BuildRaw() }
					for _, targetVersion in ipairs(targetVersionList) do
						local newItem = common.New("Item", targetVersion, verItem.raw)
						if not value.id then
							newItem:NormaliseQuality()
						end
						verItem[targetVersion] = newItem
					end
					sharedItemList.slots[slotName] = verItem
				end
			end
		end
		t_insert(self.list, self.dragIndex or #self.list + 1, sharedItemList)
	end
end

function SharedItemSetListClass:OnSelDelete(index, sharedItemSet)
	main:OpenConfirmPopup("Delete Item Set", "Are you sure you want to delete '"..(sharedItemSet.title or "Default").."' from the shared item set list?", "Delete", function()
		t_remove(self.list, index)
		self.selIndex = nil
		self.selValue = nil
	end)
end

function SharedItemSetListClass:OnSelKeyDown(index, sharedItemSet, key)
	if key == "F2" then
		self:RenameSet(sharedItemSet)
	end
end