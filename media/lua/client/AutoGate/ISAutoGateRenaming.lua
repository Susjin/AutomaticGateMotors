
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to the Renaming are listed in this file
--- @class ISAutoGateRenaming
--- @return ISAutoGateRenaming
local ISAutoGateRenaming = {}
----------------------------------------------------------------------------------------------
--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"


-- ---------------- Functions related to Renaming gates and controllers ---------------- --
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
function ISAutoGateRenaming.renameGateContainer(gate, player)
    local gateName = gate:getModData()["RenameContainer_CustomName"]
    local textBox = ISTextBox:new(0, 0, 280, 180, getText("IGUI_AutoGate_RenameGate"), ISAutoGateUtils.predicateGateName(gateName) and tostring(gateName) or getText("ContextMenu_AutoGate_GateMenu"), gate, ISAutoGateRenaming.onRenameGateContainerClick, player:getPlayerNum(), player)
    textBox:initialise()
    textBox:addToUIManager()
    textBox.entry:focus()
end

---Renames the gate to the new name, or do nothing if the TextBox is empty or the action cancelled.
---"Fully compatible with the Rename Containers mod"
---@param gate IsoThumpable Gate to get renamed
---@param button ISButton Button of the TextBox
---@param player IsoPlayer Player renaming the gate
function ISAutoGateRenaming.onRenameGateContainerClick(gate, button, player)
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

------------------ Returning file for 'require' ------------------
return ISAutoGateRenaming