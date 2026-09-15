require "TimedActions/ISBaseTimedAction"
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to all Controller Interactions are listed in this file
---	@class ISAutoGateControllerAction : ISBaseTimedAction
--- @field character IsoPlayer The player doing the action
--- @field screwdriver InventoryItem Tool used in the action
--- @field controller InventoryItem Main controller for the action
--- @field actionToBeExecuted string What the action will do. Can be "disconnect", "copyStart"/"copyFinish" or "connect"
--- @field secondController InventoryItem Optional, only needed if "actionToBeExecuted" is "copyStart"/"copyFinish"
--- @field gate IsoThumpable Optional, gate to connect to, only needed if "actionToBeExecuted" is "connect"
---	@return ISAutoGateControllerAction
	local ISAutoGateControllerAction = ISBaseTimedAction:derive("ISAutoGateControllerAction")
----------------------------------------------------------------------------------------------
--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"

local textsTypes = {
	disconnect = getText("IGUI_AutoGate_ClearingController"),
	copyStart = getText("IGUI_AutoGate_CopyingFrom"),
	copyFinish = getText("IGUI_AutoGate_CopyingTo"),
	connect = getText("IGUI_AutoGate_CopyingTo")
}

local function predicateScrewdriver(screwdriver, player)
	return (screwdriver and (screwdriver:getType() == "Screwdriver") or false) and
			(screwdriver and player:getInventory():contains(screwdriver) or false)
end

local function predicateController(controller, player)
	return (controller and (controller:getType() == "GateController") or false) and
			(controller and player:getInventory():contains(controller) or false)
end


function ISAutoGateControllerAction:isValid()
	return predicateScrewdriver(self.screwdriver, self.character) and
			predicateController(self.controller, self.character)
end

function ISAutoGateControllerAction:update()
	if self.actionToBeExecuted == "connect" then self.character:faceThisObject(self.gate) end
	self.screwdriver:setJobDelta(self:getJobDelta())
	self.controller:setJobDelta(self:getJobDelta())
end

function ISAutoGateControllerAction:start()
	self.screwdriver:setJobType(textsTypes[self.actionToBeExecuted])
	self.controller:setJobType(textsTypes[self.actionToBeExecuted])
	
	self:setOverrideHandModels(self.screwdriver, self.controller)
    self:setActionAnim("Disassemble")
	self.sound = self.character:playSound("Dismantle")
end

function ISAutoGateControllerAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ISAutoGateControllerAction:stop()
	self.screwdriver:setJobDelta(0.0)
	self.controller:setJobDelta(0.0)
	self:stopSound()
	ISBaseTimedAction.stop(self)
end

function ISAutoGateControllerAction:perform()
	self.screwdriver:setJobDelta(0.0)
	self.controller:setJobDelta(0.0)
	self:stopSound()
	ISAutoGateUtils.debugMessage(self.actionToBeExecuted)
	if self.actionToBeExecuted == "disconnect" then
		ISAutoGateUtils.clearController(self.controller)
		HaloTextHelper.addText(self.character, getText("IGUI_AutoGate_ClearControllerDone"), HaloTextHelper.getColorRed())
	elseif self.actionToBeExecuted == "copyFinish" then
		ISAutoGateUtils.makeControllerCopy(self.secondController, self.controller)
		HaloTextHelper.addText(self.character, getText("IGUI_AutoGate_CopyingDone"), HaloTextHelper.getColorGreen())
	elseif self.actionToBeExecuted == "connect" then
		ISAutoGateUtils.connectGateController(self.controller, self.gate)
		HaloTextHelper.addText(self.character, getText("IGUI_AutoGate_ConnectControllerDone"), HaloTextHelper.getColorGreen())
	end
	--Finish TimedAction
	ISInventoryPage.dirtyUI() --Refresh inventory
	ISBaseTimedAction.perform(self)
end

---Starts a controller interaction TimedAction
---@param character IsoPlayer The player doing the action
---@param screwdriver InventoryItem Screwdriver used in the action
---@param controller InventoryItem Main controller for the action
---@param actionToBeExecuted string What the action will do. Can be "disconnect", "copyStart"/"copyFinish" or "connect"
---@param secondController InventoryItem Optional, only needed if "actionToBeExecuted" is "copyStart"/"copyFinish"
---@param gate IsoThumpable Optional, gate to connect to, only needed if "actionToBeExecuted" is "connect"
---@return ISAutoGateControllerAction
function ISAutoGateControllerAction:new(character, screwdriver, controller, actionToBeExecuted, secondController, gate)
	local o = {}
	setmetatable(o, self)
	self.__index = self
    o.character = character
	o.screwdriver = screwdriver
	o.controller = controller
	o.actionToBeExecuted = actionToBeExecuted
	o.secondController = secondController
	o.gate = gate
	o.maxTime = 100 - (character:getPerkLevel(Perks.Electricity) * 5)
	if character:isTimedActionInstant() then o.maxTime = 10 end
	
	return o
end

------------------ Returning file for 'require' ------------------
return ISAutoGateControllerAction