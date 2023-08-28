
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to the Hotbar are listed in this file
--- @class ISAutoGateHotbar
--- @return ISAutoGateHotbar
local ISAutoGateHotbar = {}
----------------------------------------------------------------------------------------------
--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"

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
        ISAutoGateHotbar.toggleFromHotbar(item, self.character)
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
                menu:addSlice(getText("ContextMenu_AutoGate_UseController"), item:getTex(), ISAutoGateHotbar.toggleFromHotbar, item, player)
            end
        end
    end
end

---Toggle Gate from hotbar
---@param controller InventoryItem Controller to be used
---@param player IsoPlayer Player using the controller
function ISAutoGateHotbar.toggleFromHotbar(controller, player)
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

------------------ Returning file for 'require' ------------------
return ISAutoGateHotbar