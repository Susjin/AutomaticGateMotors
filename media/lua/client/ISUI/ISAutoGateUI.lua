
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/

---	All the User Interface methods are listed in this file
--- @class ISAutoGateUI
--- @return ISAutoGateUI
	local ISAutoGateUI = {}
----------------------------------------------------------------------------------------------

---Local definitions
local AutoGateVars = SandboxVars.AutoGate

---Local tables to store all functions
local ISAutoGateUtils = require "ISAutoGateUtils"
local ISAutoGateTooltip = require "ISUI/ISAutoGateTooltip"
local BlowtorchUtils = ISBlacksmithMenu


------------------ Functions related to gate installation ------------------
---Check if player has blowtorch and weldingmask
---@param player IsoPlayer Player
local function predicateInstallOption(player)
	local playerInventory = player:getInventory()
	if (playerInventory:contains("BlowTorch", true) and playerInventory:contains("WeldingMask", true) and player:isRecipeKnown("CanInstallGate")) or
			ISBuildMenu.cheat then return true else return false end
end

---Adds the Install Automatic Motor option to a context menu
---@param player IsoPlayer Player
---@param context ISContextMenu ContextMenu when clicked on a gate
---@param gate IsoThumpable Gate without motor installed
function ISAutoGateUI.addOptionInstallAutomaticMotor(player, context, gate)
	------------------ Setting variables ------------------
	local playerInventory = player:getInventory()
	local metalWelding = player:getPerkLevel(Perks.MetalWelding)
	local gateOpen = gate:IsOpen()
	local gateName = tostring(gate:getName())
	local components = playerInventory:getCountTypeRecurse("GateComponents")
	local blowtorch = BlowtorchUtils.getBlowTorchWithMostUses(playerInventory)
	local blowtorchUses = 0
	local weldingrods = ISAutoGateUtils.getWeldingRodsWithMostUses(playerInventory)
	local weldingrodsUses = 0
	local weldingmask = playerInventory:getCountTypeRecurse("WeldingMask")
	------------------ Running checks ------------------
	if blowtorch   ~= nil then blowtorchUses = blowtorch:getDelta() end
	if weldingrods ~= nil then weldingrodsUses = weldingrods:getDelta() end
	------------------ Adding option and tooltip ------------------
	local installOption = context:addOption(getText("ContextMenu_AutoGate_InstallComponents"), player, ISAutoGateUI.queueInstallAutomaticGateMotor, gate)
	if 	(metalWelding < AutoGateVars.LevelRequirementsInstallMetalWelding) or (gateOpen) or
		 (blowtorchUses < 0.09 ) or (weldingrodsUses < 0.08) or (weldingmask < 1) or (components < 1)
	then
		installOption.notAvailable = true
	end
	ISAutoGateTooltip.installGate(installOption, components, blowtorchUses, weldingrodsUses, weldingmask, metalWelding, gateOpen, gateName)
end

---Executes the TimedAction Install
---@param player IsoPlayer Iso Player
---@param gate IsoThumpable Gate without motor installed
function ISAutoGateUI.queueInstallAutomaticGateMotor(player, gate)
    local playerSquare = player:getSquare()
	local gateCornerObject = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))
	
	local gateSquare = gateCornerObject:getSquare()
	local gateOppositeSquare = gateCornerObject:getOppositeSquare()
	local doorSquare = gateOppositeSquare:DistTo(playerSquare) < gateSquare:DistTo(playerSquare) and gateOppositeSquare or gateSquare

	ISTimedActionQueue.add(ISWalkToTimedAction:new(player, doorSquare))
	local blowtorch, weldingrods = ISAutoGateUtils.checkAndEquipInstallItems(player)
	ISTimedActionQueue.add(ISAutoGateInstallAction:new(player, gateCornerObject, blowtorch, weldingrods))
end

------------------ Functions related to gate and controller interactions ------------------
---Connects a empty controller on a gate
---@param player IsoPlayer Player
---@param emptyController InventoryItem Controller without a connection
---@param gate IsoThumpable Gate with motor installed
function ISAutoGateUI.connectControllerToGate(player, emptyController, gate)
	local playerSquare = player:getSquare()
	local gateCornerObject = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))

	local gateSquare = gateCornerObject:getSquare()
	local gateOppositeSquare = gateCornerObject:getOppositeSquare()
	local doorSquare = (gateOppositeSquare:DistTo(playerSquare) < gateSquare:DistTo(playerSquare)) and gateOppositeSquare or gateSquare
	ISTimedActionQueue.add(ISWalkToTimedAction:new(player, doorSquare))

	local wrench, screwdriver, returnItems = ISAutoGateUtils.checkInteractItem(player, "both")
	ISTimedActionQueue.add(ISAutoGateInteractAction:new(player, gate, wrench, "connect"))
	ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, emptyController, "connect", nil, gate))
	ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
end

---Resets a automatic gate frequency
---@param player IsoPlayer Player
---@param gate IsoThumpable Gate with motor installed
function ISAutoGateUI.resetGate(gate, player)
	local playerSquare = player:getSquare()
	local gateCornerObject = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))

	local gateSquare = gateCornerObject:getSquare()
	local gateOppositeSquare = gateCornerObject:getOppositeSquare()
	local doorSquare = (gateOppositeSquare:DistTo(playerSquare) < gateSquare:DistTo(playerSquare)) and gateOppositeSquare or gateSquare
	ISTimedActionQueue.add(ISWalkToTimedAction:new(player, doorSquare))

	local wrench, returnItems = ISAutoGateUtils.checkInteractItem(player, "gate")
	ISTimedActionQueue.add(ISAutoGateInteractAction:new(player, gate, wrench, "reset"))
	ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
end

---Copies the frequency from a connected controller to another
---@param player IsoPlayer Player
---@param fromConnectedController InventoryItem Controller with a connection
---@param toEmptyController InventoryItem Controller without a connection
function ISAutoGateUI.copyControllerToAnother(player, fromConnectedController, toEmptyController)
	local screwdriver, returnItems = ISAutoGateUtils.checkInteractItem(player, "controller")
	ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, fromConnectedController, "copyStart", toEmptyController))
	ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, toEmptyController, "copyFinish", fromConnectedController))
	ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
end

---Disconnects a controller from a gate
---@param player IsoPlayer Player
---@param connectedController InventoryItem Already connected controller
function ISAutoGateUI.disconnectController(player, connectedController)
	local screwdriver, returnItems = ISAutoGateUtils.checkInteractItem(player, "controller")
	ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, connectedController, "disconnect"))
	ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
end

------------------ Functions related to Hotbar ------------------
---Add to vanilla functionality to interact with Hotbar slots, so the toggleAutomaticGate function is triggered
local old_activateSlot = ISHotbar.activateSlot
function ISHotbar:activateSlot(slotIndex)
	---@type InventoryItem
	local item = self.attachedItems[slotIndex]
	if not item then return end
	if item:getAttachedSlot() ~= slotIndex then
		error "item:getAttachedSlot() ~= slotIndex"
	end
	if item:getType() == "GateController" then
		ISAutoGateUI.toggleFromHotbar(item, self.character)
		return
	end
	old_activateSlot(self, slotIndex)
end
---Add to vanilla functionality of the Left DPad key to add the controller in the list
local old_displayLeft = ISDPadWheels.onDisplayLeft
function ISDPadWheels.onDisplayLeft(joypadData)
	--Call old method because there's a call to clear the menu
	old_displayLeft(joypadData)
	if (UIManager.getSpeedControls()) and (UIManager.getSpeedControls():getCurrentGameSpeed() == 0) then return end
	local playerIndex = joypadData.player
	---@type IsoPlayer
	local player = getSpecificPlayer(playerIndex)
	---@type ISRadialMenu
	local menu = getPlayerRadialMenu(playerIndex)
	---@type ISHotbar
	local hotbar = getPlayerHotbar(playerIndex)
	local playerItems = player:getInventory():getItems()

	for i=0, playerItems:size()-1 do
		---@type InventoryItem
		local item = playerItems:get(i)
		if instanceof(item, "InventoryItem") and item:getType() == "GateController" then
			if hotbar:isInHotbar(item) and ISAutoGateUtils.checkDistanceToGate(player, ISAutoGateUtils.getGateFromFrequency(ISAutoGateUtils.getFrequency(item))) then
				menu:addSlice(getText("ContextMenu_AutoGate_UseController"), item:getTex(), ISAutoGateUI.toggleFromHotbar, item, player)
			end
		end
	end
end

---Toggle Gate from hotbar
function ISAutoGateUI.toggleFromHotbar(controller, player)
	local frequency = ISAutoGateUtils.getFrequency(controller)
	if frequency then
		local gate = ISAutoGateUtils.getGateFromFrequency(frequency)
		if gate then
			ISAutoGateUtils.toggleAutomaticGate(gate, player)

			--Renaming the controller in case it's needed
			local controllerName = controller:getName()
			local gateName = gate:getModData().RenameContainer_CustomName
			if ISAutoGateUtils.predicateGateName(gateName) and (string.gsub(controllerName, gateName, "") ~= " - No. " .. frequency[4]) then
				ISAutoGateUtils.debugMessage("Controller name does not match")
				ISAutoGateUtils.renameController(controller, gateName, frequency[4])
			end
		end
	end
end
------------------ Functions related to Renaming gates and controllers ------------------
---Add to vanilla functionality of rendering container's page title, to render the gate custom name
---"Fully compatible with the Rename Containers mod"
local vanilla_prerender = ISInventoryPage.prerender
function ISInventoryPage:prerender()
	if not ISInventoryPage.renameContainer then
		if self.title and not self.onCharacter and self.inventory:getType() ~= "floor" and self.inventory:getParent() then
			local modData = self.inventory:getParent():getModData()
			if modData.RenameContainer_CustomName and modData.RenameContainer_CustomName ~= "" then
				self.title = modData.RenameContainer_CustomName
			end
		end
	end
	vanilla_prerender(self)
end

---Adds the TextBox for renaming
---@param gate IsoThumpable Gate to get renamed
---@param player IsoPlayer Player renaming the gate
function ISAutoGateUI.renameGateContainer(gate, player)
	local gateName = gate:getModData()["RenameContainer_CustomName"]
	local textBox = ISTextBox:new(0, 0, 280, 180, getText("IGUI_AutoGate_RenameGate"), ISAutoGateUtils.predicateGateName(gateName) and tostring(gateName) or getText("ContextMenu_AutoGate_GateMenu"), gate, ISAutoGateUI.onRenameGateContainerClick, player:getPlayerNum(), player)
	textBox:initialise()
	textBox:addToUIManager()
	textBox.entry:focus()
end

---Renames the gate to the new name, or do nothing if the TextBox is empty or the action cancelled.
---"Fully compatible with the Rename Containers mod"
---@param gate IsoThumpable Gate to get renamed
---@param button ISButton Button of the TextBox
---@param player IsoPlayer Player renaming the gate
function ISAutoGateUI.onRenameGateContainerClick(gate, button, player)
	if button.internal == "OK" then
		local textBoxText = button.parent.entry:getText()
		if textBoxText and textBoxText ~= "" and gate then
			ISAutoGateUtils.debugMessage("renamed gate to " .. textBoxText)
			ISAutoGateUtils.fullGateRename(gate, textBoxText)
			HaloTextHelper.addText(player, getText("IGUI_AutoGate_RenameGateDone"), HaloTextHelper.getColorGreen())

			--Renaming the controllers for all players
			local gateFrequency = ISAutoGateUtils.getFrequency(gate)
			table.insert(gateFrequency, textBoxText)
			if isClient() then
				sendClientCommand("AutoGate", "renameGate", gateFrequency)
			else
				for i=0, 3 do
					local playerJoypad = getSpecificPlayer(i)
					ISAutoGateUtils.renameController(gateFrequency, nil, nil, playerJoypad)
				end
			end
		end
	end
end


------------------ ContextMenu Functions ------------------
---Triggers when user Opens a ContextMenu on a gate
---@param playerNum number PlayerID
---@param contextMenu ISContextMenu Main ContextMenu
---@param objects table Contains all objects in mouse position
function ISAutoGateUI.doMenu(playerNum, contextMenu, objects)
    local player = getSpecificPlayer(playerNum)
	---@type IsoThumpable
	local gate
	local gateName
	for i = 1, #objects do
        local name = tostring(objects[i]:getName())
        if (instanceof(objects[i], "IsoThumpable")) and
			((name == "Double Door") or (name == "Double Metal Pole Gate") or (name == "Double Metal Wire Gate")) --3 types of gate made by the player
		then
            gate = objects[i]
			gateName = name
            break
        end
    end
	--If a gate exists in the clicked square then
    if gate then
		--To counterpart some bizarre problems with gate IsoGridSquare, all functions will work with the Corner object
		gate = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))
        local gateFrequency = ISAutoGateUtils.getFrequency(gate)
        --Checks if gate have a automatic motor installed
		if gateFrequency then
            ------------------ Setting variables ------------------
			local gateFrequencyCode = gateFrequency[4]
			local gateLock = gate:isLockedByKey()
			local gateOpen = gate:IsOpen()
			local playerInventory = player:getInventory()
			local electrical = player:getPerkLevel(Perks.Electricity)
			local mechanics = player:getPerkLevel(Perks.Mechanics)
			local wrench = playerInventory:getCountTypeRecurse("Wrench")
			local screwdriver = playerInventory:getCountTypeRecurse("Screwdriver")
			local itemConnectedController = ISAutoGateUtils.findControllerOnPlayer(player, gateFrequencyCode)
			local emptyControllers = ISAutoGateUtils.findControllerOnPlayer(player, nil)
			local playerDistanceValid = ISAutoGateUtils.checkDistanceToGate(player, gate)
			local totalBatteryCharge = ISAutoGateUtils.getBatteryFromGate(gate, true)
			------------------ Creating the gate SubMenu ------------------
			local gateMenu = contextMenu:addOption(getText("ContextMenu_AutoGate_GateMenu"), objects, nil)
			local gateSubMenu = ISContextMenu:getNew(contextMenu)
			contextMenu:addSubMenu(gateMenu, gateSubMenu)
			------------------ Use & Lock Options ------------------
			if (itemConnectedController and playerDistanceValid) --[[or getDebug()]] then
				local lockFromGateOption = gateSubMenu:addOption(ISAutoGateUtils.getGateLockText(gateLock, "context"), gate, ISAutoGateUtils.toggleGateLock, player)
				if (gate:IsOpen()) then lockFromGateOption.notAvailable = true end
				ISAutoGateTooltip.lockGate(lockFromGateOption, gateLock, gateOpen)
				local useFromGateMenu  = contextMenu:addOptionOnTop(getText("ContextMenu_AutoGate_UseController"), gate, ISAutoGateUtils.toggleAutomaticGate, player)
				if (totalBatteryCharge.total <= 0) then useFromGateMenu.notAvailable = true end
				ISAutoGateTooltip.useFromGateOrControllerConnected(useFromGateMenu, totalBatteryCharge, true, playerDistanceValid)
			end
			------------------ Connect, Reset & Rename Options ------------------
			local renameOption = gateSubMenu:addOption (getText("ContextMenu_AutoGate_RenameGate"), gate, ISAutoGateUI.renameGateContainer, player)
			if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (mechanics < AutoGateVars.LevelRequirementsGateInteraction) or
				(wrench < 1) then renameOption.notAvailable = true end
			ISAutoGateTooltip.renameGate(renameOption, electrical, mechanics, wrench, gateName)
			local connectOption = gateSubMenu:addOption(getText("ContextMenu_AutoGate_ConnectController"), player, ISAutoGateUI.connectControllerToGate, emptyControllers[1], gate)
			if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (mechanics < AutoGateVars.LevelRequirementsGateInteraction) or
				(#emptyControllers < 1) or (wrench < 1) or (screwdriver < 1) then connectOption.notAvailable = true end
			ISAutoGateTooltip.connectController(connectOption, #emptyControllers, electrical, mechanics, wrench, screwdriver, gateName)
			local resetOption = gateSubMenu:addOption (getText("ContextMenu_AutoGate_ResetGate"), gate, ISAutoGateUI.resetGate, player)
			if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (mechanics < AutoGateVars.LevelRequirementsGateInteraction) or
				(wrench < 1) then resetOption.notAvailable = true end
			ISAutoGateTooltip.resetGate(resetOption, electrical, mechanics, wrench, gateName)
			------------------ Hide Options ------------------
			if gateLock then
				gateSubMenu:removeOptionByName(getText("ContextMenu_AutoGate_ConnectController"))
				gateSubMenu:removeOptionByName(getText("ContextMenu_AutoGate_RenameGate"))
				gateSubMenu:removeOptionByName(getText("ContextMenu_AutoGate_ResetGate"))
				if #gateSubMenu.options == 0 then
					contextMenu:removeOptionByName(getText("ContextMenu_AutoGate_GateMenu"))
				end
			end
        else
			------------------ Gate Motor Install ------------------
            if predicateInstallOption(player) then
				ISAutoGateUI.addOptionInstallAutomaticMotor(player, contextMenu, gate)
			end
        end
    end       
end

---Triggers when user Opens a ContextMenu on a gate controller
---@param playerNum number PlayerID
---@param contextMenu ISContextMenu Main ContextMenu
---@param inventoryItems table Contains all objects on the player selected slot
function ISAutoGateUI.doInventoryMenu(playerNum, contextMenu, inventoryItems)
    local player = getSpecificPlayer(playerNum)
	local items = inventoryItems
	if not instanceof(inventoryItems[1], "InventoryItem") then
		items = inventoryItems[1].items
	end
	for i = 1, #items do
		--Checking every controller on player's inventory and if it is connected
		local itemInCheck = items[i]
		if instanceof(itemInCheck, "InventoryItem") then
			if itemInCheck:getType() == "GateController" then
				local controllerFrequency = ISAutoGateUtils.getFrequency(itemInCheck)
				if controllerFrequency then
					------------------ Setting variables ------------------
					---@type IsoThumpable
					local gate = ISAutoGateUtils.getGateFromFrequency(controllerFrequency)
					local gateExists = gate and true or false
					local gateLock = gate and gate:isLockedByKey() or false
					local gateOpen = gate and gate:IsOpen() or false
					local gateName = gate and gate:getModData().RenameContainer_CustomName or ""
					---@type InventoryItem
					local controller = itemInCheck
					local electrical = player:getPerkLevel(Perks.Electricity)
					local screwdriver = player:getInventory():getCountTypeRecurse("Screwdriver")
					local emptyControllers = ISAutoGateUtils.findControllerOnPlayer(player, nil)
					local totalBatteryCharge = ISAutoGateUtils.getBatteryFromGate(gate, true)
					local playerDistanceValid = ISAutoGateUtils.checkDistanceToGate(player, gate)
					------------------ Changing name of the controller ------------------
					local controllerName = controller:getName()
					if ISAutoGateUtils.predicateGateName(gateName) and (string.gsub(controllerName, gateName, "") ~= " - No. " .. controllerFrequency[4]) then
						ISAutoGateUtils.debugMessage("Controller name does not match")
						ISAutoGateUtils.renameController(controller, gateName, controllerFrequency[4])
					end
					------------------ Creating the controller SubMenu ------------------
					local controllerMenu = contextMenu:addOption(getText("ContextMenu_AutoGate_ControllerMenu"), inventoryItems, nil)
					---@type ISContextMenu
					local controllerSubMenu = ISContextMenu:getNew(contextMenu)
					contextMenu:addSubMenu(controllerMenu, controllerSubMenu)
					------------------ Use Controller Option ------------------
					local useControllerOption = contextMenu:addOptionOnTop(getText("ContextMenu_AutoGate_UseController"), gate, ISAutoGateUtils.toggleAutomaticGate, player)
					if (not gateExists) or (totalBatteryCharge.total <= 0) or (not playerDistanceValid) then useControllerOption.notAvailable = true end
					------------------ Lock Controller Option ------------------
					local lockControllerOption = controllerSubMenu:addOption(ISAutoGateUtils.getGateLockText(gateLock, "context"), gate, ISAutoGateUtils.toggleGateLock, player)
					if gateOpen then lockControllerOption.notAvailable = true end
					------------------ Copy Controller Option ------------------
					local copyControllerOption = controllerSubMenu:addOption(getText("ContextMenu_AutoGate_Copy"), player, ISAutoGateUI.copyControllerToAnother, controller,  emptyControllers[1])
					if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (screwdriver < 1) or (#emptyControllers < 1) then copyControllerOption.notAvailable = true end
					------------------ Clear Controller Option ------------------
					local clearControllerOption = controllerSubMenu:addOption(getText("ContextMenu_AutoGate_ClearController"), player, ISAutoGateUI.disconnectController, controller)
					if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (screwdriver < 1) then clearControllerOption.notAvailable = true end
					------------------ Hide Options/Show Tooltips ------------------
					if gateExists and playerDistanceValid then
						ISAutoGateTooltip.lockGate(lockControllerOption, gateLock, gateOpen)
					else
						controllerSubMenu:removeOptionByName(ISAutoGateUtils.getGateLockText(gateLock, "context"))
					end
					ISAutoGateTooltip.useFromGateOrControllerConnected(useControllerOption, totalBatteryCharge, gateExists, playerDistanceValid)
					ISAutoGateTooltip.copyController(copyControllerOption, #emptyControllers, electrical, screwdriver)
					ISAutoGateTooltip.clearController(clearControllerOption, electrical, screwdriver)
				------------------ Ending loop after controller is found ------------------
				break
				end
			end
		end
	end
end

local origDoContextualDblClick = ISInventoryPane.doContextualDblClick
---Triggers when user DoubleClick on a gate controller
---@param item InventoryItem Item that got clicked
function ISInventoryPane:doContextualDblClick(item)
    local player = item:getContainer():getCharacter()
	ISAutoGateUtils.debugMessage(player:getFullName())
	if instanceof(item, "InventoryItem") then
		if item:getType() == "GateController" then
			local frequency = ISAutoGateUtils.getFrequency(item)
			local gate = ISAutoGateUtils.getGateFromFrequency(frequency)
			if gate then
				ISAutoGateUtils.toggleAutomaticGate(gate, player)
			end
		end
	end
    return origDoContextualDblClick(self, item)
end



--ServerSync Function
local onServerCommand = function(module, command, args)
	if isClient() then
		if module == "AutoGate" then
			if command == "install" then
				ISAutoGateUtils.installAutomaticGateMotor(args)
			elseif command == "toggleGate" then
				ISAutoGateUtils.consumeBatteryMP(args)
			elseif command == "renameGate" then
				for i=0, 3 do
					local player = getSpecificPlayer(i)
					ISAutoGateUtils.renameController(args, nil, nil, player)
				end
			end
		end
	end
end

--Register Events
Events.OnServerCommand.Add(onServerCommand)
Events.OnFillWorldObjectContextMenu.Add(ISAutoGateUI.doMenu)
Events.OnFillInventoryObjectContextMenu.Add(ISAutoGateUI.doInventoryMenu)

------------------ Returning file for 'require' ------------------
return ISAutoGateUI