
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the User Interface methods are listed in this file
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

local BlowtorchUtils = ISBlacksmithMenu


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
    local weldingrods = ISAutoGateUtils.getWeldingRodsWithMostUses(playerInventory)
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
    local blowtorch, weldingrods = ISAutoGateUtils.checkAndEquipInstallItems(player)
    ISTimedActionQueue.add(ISAutoGateInstallAction:new(player, gateCornerObject, blowtorch, weldingrods))
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

    local wrench, screwdriver, returnItems = ISAutoGateUtils.checkInteractItem(player, "both")
    ISTimedActionQueue.add(ISAutoGateInteractAction:new(player, gate, wrench, "connect"))
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, emptyController, "connect", nil, gate))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
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

    local wrench, returnItems = ISAutoGateUtils.checkInteractItem(player, "gate")
    ISTimedActionQueue.add(ISAutoGateInteractAction:new(player, gate, wrench, "reset"))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
end

---Copies the frequency from a connected controller to another
---@param player IsoPlayer Player
---@param fromConnectedController InventoryItem Controller with a connection
---@param toEmptyController InventoryItem Controller without a connection
function ISAutoGateTimedActions.copyControllerToAnother(player, fromConnectedController, toEmptyController)
    local screwdriver, returnItems = ISAutoGateUtils.checkInteractItem(player, "controller")
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, fromConnectedController, "copyStart", toEmptyController))
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, toEmptyController, "copyFinish", fromConnectedController))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
end

---Disconnects a controller from a gate
---@param player IsoPlayer Player
---@param connectedController InventoryItem Already connected controller
function ISAutoGateTimedActions.disconnectController(player, connectedController)
    local screwdriver, returnItems = ISAutoGateUtils.checkInteractItem(player, "controller")
    ISTimedActionQueue.add(ISAutoGateControllerAction:new(player, screwdriver, connectedController, "disconnect"))
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnItems)
end






------------------ Returning file for 'require' ------------------
return ISAutoGateTimedActions