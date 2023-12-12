require "TimedActions/ISBaseTimedAction"
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to all Gate Interactions are listed in this file
---	@class ISAutoGateInteractAction : ISBaseTimedAction
--- @field character IsoPlayer The player doing the action
--- @field gate IsoThumpable The target of the action
--- @field wrench InventoryItem Wrench used in the action
--- @field actionToBeExecuted string What the action will do. Can be "reset" or "connect"
---	@return ISAutoGateInteractAction
	local ISAutoGateInteractAction = ISBaseTimedAction:derive("ISAutoGateInteractAction")
----------------------------------------------------------------------------------------------
--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"
local ISAutoGateRenaming = require "AutoGate/ISAutoGateRenaming"

local textsTypes = {
	reset = getText("IGUI_AutoGate_GateResetting"),
	connect = getText("IGUI_AutoGate_CopyingFrom"),
	rename = getText("ContextMenu_AutoGate_RenameGate") --TODO: Better translation string
}

local function predicateWrench(wrench, player)
	return (wrench and (wrench:getType() == "Wrench") or false) and
			(wrench and player:getInventory():contains(wrench) or false)
end

function ISAutoGateInteractAction:isValid()
	return predicateWrench(self.wrench, self.character) and
			(instanceof(self.gate, "IsoThumpable"))
end

function ISAutoGateInteractAction:update()
	self.wrench:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.gate)
end

function ISAutoGateInteractAction:waitToStart()
	self.character:faceThisObject(self.gate);
	return self.character:shouldBeTurning()
end

function ISAutoGateInteractAction:start()
	self.character:faceThisObject(self.gate)

	self.wrench:setJobType(textsTypes[self.actionToBeExecuted])

	self:setActionAnim("Disassemble")
	self:setOverrideHandModels(self.wrench, nil)
	self.sound = self.character:playSound("RepairWithWrench")
end

function ISAutoGateInteractAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ISAutoGateInteractAction:stop()
	self.wrench:setJobDelta(0.0)
	self:stopSound()
	ISBaseTimedAction.stop(self)
end

function ISAutoGateInteractAction:perform()
	self.wrench:setJobDelta(0.0)
	self:stopSound()

	ISAutoGateUtils.debugMessage(self.actionToBeExecuted)
	if self.actionToBeExecuted == "reset" then
		ISAutoGateUtils.resetGate(self.gate, true)
		HaloTextHelper.addText(self.character, getText("IGUI_AutoGate_GateReset"), HaloTextHelper.getColorGreen())
	elseif self.actionToBeExecuted == "rename" then
		ISAutoGateRenaming.renameGateContainer(self.gate, self.character)
	end
	--Finish TimedAction
	ISBaseTimedAction.perform(self)
end

---Starts the GateInteract TimedAction
---@param character IsoPlayer The player doing the action
---@param gate IsoThumpable The target of the action
---@param wrench InventoryItem Wrench used in the action
---@param actionToBeExecuted string What the action will do. Can be "reset" or "connect"
---@return ISAutoGateInteractAction
function ISAutoGateInteractAction:new(character, gate, wrench, actionToBeExecuted)
	local o = {}
	setmetatable(o, self)
	self.__index = self
    o.character = character
    o.gate = gate
	o.wrench = wrench
	o.actionToBeExecuted = actionToBeExecuted
	o.maxTime = 200 - (character:getPerkLevel(Perks.Mechanics) * 5)
	if character:isTimedActionInstant() then o.maxTime = 10 end
	
	return o
end

------------------ Returning file for 'require' ------------------
return ISAutoGateInteractAction