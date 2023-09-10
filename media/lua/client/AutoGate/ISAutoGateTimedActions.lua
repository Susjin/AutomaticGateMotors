
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to TimedActions are listed in this file
--- @class ISAutoGateTimedActions
--- @return ISAutoGateTimedActions
local ISAutoGateTimedActions = {}
----------------------------------------------------------------------------------------------
--Sandbox Settings
local AutoGateVars = SandboxVars.AutoGate

--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"
local ISAutoGateTooltip = require "AutoGate/ISUI/ISAutoGateTooltip"

local ISAutoGateInstallAction = require "AutoGate/TimedActions/ISAutoGateInstallAction"
local ISAutoGateInteractAction = require "AutoGate/TimedActions/ISAutoGateInteractAction"
local ISAutoGateControllerAction = require "AutoGate/TimedActions/ISAutoGateControllerAction"
local ISAutoGateClearQueueAction = require "AutoGate/TimedActions/ISAutoGateClearQueueAction"

local BlowtorchUtils = ISBlacksmithMenu


------------------ Functions related to TimedActions Checks ------------------
local function comparatorDrainableUsesInt(item1, item2)
    return item1:getDrainableUsesInt() - item2:getDrainableUsesInt()
end
---Get the best Welding Rods inside a inventory container
---@param container ItemContainer Usually the player inventory
---@return DrainableComboItem WeldingRods with most uses left
function ISAutoGateTimedActions.getWeldingRodsWithMostUses(container)
    return container:getBestTypeEvalRecurse("Base.WeldingRods", comparatorDrainableUsesInt)
end

---Check if the item still have uses left
---@param inventoryItem InventoryItem Item to be checked
---@param itemType String Type of the item
---@return boolean True if has uses left, false if not
function ISAutoGateTimedActions.hasDeltaLeft(inventoryItem, itemType)
    if inventoryItem:getType() == itemType then
        if inventoryItem:getDelta() > 0 then
            return true
        end
    end
    return false
end

---Equips items for TimedAction
---@param player IsoPlayer Player doing the action
---@return DrainableComboItem, DrainableComboItem
function ISAutoGateTimedActions.checkAndEquipInstallItems(player)
    local playerInventory = player:getInventory()

    --Checking if equipped items are valid
    local equippedPrimary = player:getPrimaryHandItem()
    local alreadyEquippedPrimary = false
    if instanceof(equippedPrimary, "DrainableComboItem") then
        alreadyEquippedPrimary = ISAutoGateTimedActions.hasDeltaLeft(equippedPrimary, "BlowTorch")
    end
    local equippedSecondary = player:getSecondaryHandItem()
    local alreadyEquippedSecondary = false
    if instanceof(equippedSecondary, "DrainableComboItem") then
        alreadyEquippedSecondary = ISAutoGateTimedActions.hasDeltaLeft(equippedSecondary, "WeldingRods")
    end
    --Setting correct items
    local blowtorch = BlowtorchUtils.getBlowTorchWithMostUses(playerInventory)
    if alreadyEquippedPrimary then
        blowtorch = equippedPrimary
    end
    local weldingrods = ISAutoGateTimedActions.getWeldingRodsWithMostUses(playerInventory)
    if alreadyEquippedSecondary then
        weldingrods = equippedSecondary
    end
    local weldingmask = playerInventory:getItemFromTypeRecurse("WeldingMask")

    ISInventoryPaneContextMenu.transferIfNeeded(player, blowtorch)
    ISInventoryPaneContextMenu.transferIfNeeded(player, weldingrods)
    ISInventoryPaneContextMenu.transferIfNeeded(player, weldingmask)
    luautils.equipItems(player, blowtorch, weldingrods)
    ISInventoryPaneContextMenu.wearItem(weldingmask, player:getPlayerNum())
    return blowtorch, weldingrods
end

---Get the items for a given interaction and equips them
---@param player IsoPlayer Player to do the action
---@param gateOrController string If the action is on a gate/controller
---@return InventoryItem, table<number,InventoryItem> Return checked item and it's container instance
function ISAutoGateTimedActions.checkInteractItem(player, gateOrController)
    local playerInventory = player:getInventory()
    local returnToContainer = {}
    local screwdriver = playerInventory:getItemFromTypeRecurse("Screwdriver")
    local wrench = playerInventory:getItemFromTypeRecurse("Wrench")
    if gateOrController == "controller" and screwdriver then
        table.insert(returnToContainer, screwdriver)
        ISInventoryPaneContextMenu.transferIfNeeded(player, screwdriver)
        return screwdriver, returnToContainer
    elseif gateOrController == "gate" and wrench then
        table.insert(returnToContainer, wrench)
        ISInventoryPaneContextMenu.transferIfNeeded(player, wrench)
        return wrench, returnToContainer
    elseif gateOrController == "both" and wrench and screwdriver then
        table.insert(returnToContainer, wrench)
        table.insert(returnToContainer, screwdriver)
        ISInventoryPaneContextMenu.transferIfNeeded(player, wrench)
        ISInventoryPaneContextMenu.transferIfNeeded(player, screwdriver)
        return wrench, screwdriver, returnToContainer
    end
    return nil
end

------------------ Functions related to gate installation ------------------

---Adds the Install Automatic Motor option to a context menu
---@param player IsoPlayer Player
---@param context ISContextMenu ContextMenu when clicked on a gate
---@param gate IsoThumpable Gate without motor installed
function ISAutoGateTimedActions.addOptionInstallAutomaticMotor(player, context, gate)
    ------------------ Setting variables ------------------
    local playerInventory = player:getInventory()
    local metalWelding = player:getPerkLevel(Perks.MetalWelding)
    local gateOpen = gate:IsOpen()
    local gateName = tostring(gate:getName())
    local components = playerInventory:getCountTypeRecurse("GateComponents")
    local blowtorch = BlowtorchUtils.getBlowTorchWithMostUses(playerInventory)
    local blowtorchUses = 0
    local weldingrods = ISAutoGateTimedActions.getWeldingRodsWithMostUses(playerInventory)
    local weldingrodsUses = 0
    local weldingmask = playerInventory:getCountTypeRecurse("WeldingMask")
    ------------------ Running checks ------------------
    if blowtorch   ~= nil then blowtorchUses = blowtorch:getDelta() end
    if weldingrods ~= nil then weldingrodsUses = weldingrods:getDelta() end
    ------------------ Adding option and tooltip ------------------
    local installOption = context:addOption(getText("ContextMenu_AutoGate_InstallComponents"), player, ISAutoGateTimedActions.queueInstallAutomaticGateMotor, gate)
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
function ISAutoGateTimedActions.queueInstallAutomaticGateMotor(player, gate)
    local playerSquare = player:getSquare()
    local gateCornerObject = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))

    local gateSquare = gateCornerObject:getSquare()
    local gateOppositeSquare = gateCornerObject:getOppositeSquare()
    local doorSquare = gateOppositeSquare:DistTo(playerSquare) < gateSquare:DistTo(playerSquare) and gateOppositeSquare or gateSquare

    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, doorSquare))
    local blowtorch, weldingrods = ISAutoGateTimedActions.checkAndEquipInstallItems(player)
    ISTimedActionQueue.add(ISAutoGateInstallAction:new(player, gateCornerObject, blowtorch, weldingrods))
    ISTimedActionQueue.add(ISAutoGateClearQueueAction:new(player))
end

------------------ Functions related to gate and controller interactions ------------------

---Connects a empty controller on a gate
---@param player IsoPlayer Player
---@param emptyController InventoryItem Controller without a connection
---@param gate IsoThumpable Gate with motor installed
function ISAutoGateTimedActions.connectControllerToGate(player, emptyController, gate)
    local playerSquare = player:getSquare()
    local gateCornerObject = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))

    local gateSquare = gateCornerObject:getSquare()
    local gateOppositeSquare = gateCornerObject:getOppositeSquare()
    local doorSquare = (gateOppositeSquare:DistTo(playerSquare) < gateSquare:DistTo(playerSquare)) and gateOppositeSquare or gateSquare
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, doorSquare))

    local wrench, screwdriver, returnItems = ISAutoGateTimedActions.checkInteractItem(player, "both")
    ISTimedActionQueue.add(ISAutoGateInteractAction:new(player, gate, wrench, "connect"))
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, emptyController, "connect", nil, gate))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
    ISTimedActionQueue.add(ISAutoGateClearQueueAction:new(player))
end

---Resets a automatic gate frequency
---@param player IsoPlayer Player
---@param gate IsoThumpable Gate with motor installed
function ISAutoGateTimedActions.resetGate(gate, player)
    local playerSquare = player:getSquare()
    local gateCornerObject = ISAutoGateUtils.getGateFromSquare(ISAutoGateUtils.getGateCorner(gate))

    local gateSquare = gateCornerObject:getSquare()
    local gateOppositeSquare = gateCornerObject:getOppositeSquare()
    local doorSquare = (gateOppositeSquare:DistTo(playerSquare) < gateSquare:DistTo(playerSquare)) and gateOppositeSquare or gateSquare
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, doorSquare))

    local wrench, returnItems = ISAutoGateTimedActions.checkInteractItem(player, "gate")
    ISTimedActionQueue.add(ISAutoGateInteractAction:new(player, gate, wrench, "reset"))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
    ISTimedActionQueue.add(ISAutoGateClearQueueAction:new(player))
end

---Copies the frequency from a connected controller to another
---@param player IsoPlayer Player
---@param fromConnectedController InventoryItem Controller with a connection
---@param toEmptyController InventoryItem Controller without a connection
function ISAutoGateTimedActions.copyControllerToAnother(player, fromConnectedController, toEmptyController)
    local screwdriver, returnItems = ISAutoGateTimedActions.checkInteractItem(player, "controller")
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, fromConnectedController, "copyStart", toEmptyController))
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, toEmptyController, "copyFinish", fromConnectedController))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
    ISTimedActionQueue.add(ISAutoGateClearQueueAction:new(player))
end

---Disconnects a controller from a gate
---@param player IsoPlayer Player
---@param connectedController InventoryItem Already connected controller
function ISAutoGateTimedActions.disconnectController(player, connectedController)
    local screwdriver, returnItems = ISAutoGateTimedActions.checkInteractItem(player, "controller")
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, connectedController, "disconnect"))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
    ISTimedActionQueue.add(ISAutoGateClearQueueAction:new(player))
end


------------------ Returning file for 'require' ------------------
return ISAutoGateTimedActions