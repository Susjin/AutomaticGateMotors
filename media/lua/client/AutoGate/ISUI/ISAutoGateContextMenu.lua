
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to the ContextMenu are listed in this file
--- @class ISAutoGateContextMenu
--- @return ISAutoGateContextMenu
	local ISAutoGateContextMenu = {}
----------------------------------------------------------------------------------------------

--Local definitions
local AutoGateVars = SandboxVars.AutoGate

--Local tables to store all functions
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"
local ISAutoGateTimedActions = require "AutoGate/ISAutoGateTimedActions"
local ISAutoGateTooltip = require "AutoGate/ISUI/ISAutoGateTooltip"


------------------ ContextMenu Functions ------------------
---Triggers when user Opens a ContextMenu on a gate
---@param playerNum number PlayerID
---@param contextMenu ISContextMenu Main ContextMenu
---@param objects table Contains all objects in mouse position
function ISAutoGateContextMenu.doWorldMenu(playerNum, contextMenu, objects)
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
			local renameOption = gateSubMenu:addOption(getText("ContextMenu_AutoGate_RenameGate"), gate, ISAutoGateTimedActions.renameGate, player)
			if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (mechanics < AutoGateVars.LevelRequirementsGateInteraction) or
				(wrench < 1) then renameOption.notAvailable = true end
			ISAutoGateTooltip.renameGate(renameOption, electrical, mechanics, wrench, gateName)
			local connectOption = gateSubMenu:addOption(getText("ContextMenu_AutoGate_ConnectController"), player, ISAutoGateTimedActions.connectControllerToGate, emptyControllers[1], gate)
			if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (mechanics < AutoGateVars.LevelRequirementsGateInteraction) or
				(#emptyControllers < 1) or (wrench < 1) or (screwdriver < 1) then connectOption.notAvailable = true end
			ISAutoGateTooltip.connectController(connectOption, #emptyControllers, electrical, mechanics, wrench, screwdriver, gateName)
			local resetOption = gateSubMenu:addOption (getText("ContextMenu_AutoGate_ResetGate"), gate, ISAutoGateTimedActions.resetGate, player)
			if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (mechanics < AutoGateVars.LevelRequirementsGateInteraction) or
				(wrench < 1) then resetOption.notAvailable = true end
			ISAutoGateTooltip.resetGate(resetOption, electrical, mechanics, wrench, gateName)
			------------------ Hide Options ------------------
			if gateLock then
				gateSubMenu:removeOptionByName(getText("ContextMenu_AutoGate_ConnectController"))
				gateSubMenu:removeOptionByName(getText("ContextMenu_AutoGate_RenameGate"))
				gateSubMenu:removeOptionByName(getText("ContextMenu_AutoGate_ResetGate"))
			end
			if gateSubMenu:isEmpty() then
				contextMenu:removeOptionByName(getText("ContextMenu_AutoGate_GateMenu"))
			end
		else
			------------------ Gate Motor Install ------------------
            if ISAutoGateUtils.predicateInstallOption(player) then
				ISAutoGateTimedActions.addOptionInstallAutomaticMotor(player, contextMenu, gate)
			end
        end
    end       
end

---Triggers when user Opens a ContextMenu on a gate controller
---@param playerNum number PlayerID
---@param contextMenu ISContextMenu Main ContextMenu
---@param inventoryItems table Contains all objects on the player selected slot
function ISAutoGateContextMenu.doInventoryMenu(playerNum, contextMenu, inventoryItems)
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
					local copyControllerOption = controllerSubMenu:addOption(getText("ContextMenu_AutoGate_Copy"), player, ISAutoGateTimedActions.copyControllerToAnother, controller,  emptyControllers[1])
					if (electrical < AutoGateVars.LevelRequirementsControllerInteraction) or (screwdriver < 1) or (#emptyControllers < 1) then copyControllerOption.notAvailable = true end
					------------------ Clear Controller Option ------------------
					local clearControllerOption = controllerSubMenu:addOption(getText("ContextMenu_AutoGate_ClearController"), player, ISAutoGateTimedActions.disconnectController, controller)
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

--Register Events
Events.OnFillWorldObjectContextMenu.Add(ISAutoGateContextMenu.doWorldMenu)
Events.OnFillInventoryObjectContextMenu.Add(ISAutoGateContextMenu.doInventoryMenu)

------------------ Returning file for 'require' ------------------
return ISAutoGateContextMenu