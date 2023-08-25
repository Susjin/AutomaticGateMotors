require "TimedActions/ISBaseTimedAction"
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/

---	All the methods related to the InstallAutomaticGate Action are listed in this file
---	@class ISAutoGateInstallAction : ISBaseTimedAction
--- @field character IsoPlayer The player doing the action
--- @field gate IsoThumpable The target of the action
--- @field blowtorch DrainableComboItem A Blowtorch with uses left
--- @field weldingrods DrainableComboItem A WeldingRods with uses left
	ISAutoGateInstallAction = ISBaseTimedAction:derive("ISAutoGateInstallAction")
----------------------------------------------------------------------------------------------
--Setting up locals
---@type ISAutoGateUtils
---@see ISAutoGateUtils
local GateUtils = ISAutoGateUtils

---Predicate WeldingMask
---@param player IsoPlayer
local function predicateWornWeldingMask(player)
	local wornItems = player:getWornItems()
	for i=0, wornItems:size()-1 do
		if wornItems:getItemByIndex(i):getType() == "WeldingMask" then
			return true
		end
	end
	return false
end


function ISAutoGateInstallAction:isValid()
	return self.character:isPrimaryHandItem(self.blowtorch) and
			self.character:isSecondaryHandItem(self.weldingrods) and
			 predicateWornWeldingMask(self.character) and
			  (self.gate:IsOpen() == false)
end

function ISAutoGateInstallAction:update()
	self.blowtorch:setJobDelta(self:getJobDelta())
	self.weldingrods:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.gate)
end

function ISAutoGateInstallAction:waitToStart()
	self.character:faceThisObject(self.gate);
	return self.character:shouldBeTurning()
end

function ISAutoGateInstallAction:start()
	self.character:faceThisObject(self.gate)
        
	self.blowtorch:setJobType(getText("IGUI_AutoGate_Installing"))
	self.weldingrods:setJobType(getText("IGUI_AutoGate_Installing"))
	
	self:setOverrideHandModels(self.blowtorch, self.weldingrods)
    self:setActionAnim("BlowTorch")
	self.sound = self.character:playSound("BlowTorch")
end

function ISAutoGateInstallAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ISAutoGateInstallAction:stop()
	self.blowtorch:setJobDelta(0.0)
	self.weldingrods:setJobDelta(0.0)
	self:stopSound()
	ISBaseTimedAction.stop(self)
end

function ISAutoGateInstallAction:perform()
	self.blowtorch:setJobDelta(0.0)
	self.weldingrods:setJobDelta(0.0)
	self:stopSound()

	--Consume items
	local playerInventory = self.character:getInventory()
	local components = playerInventory:getItemFromTypeRecurse("GateComponents")
	if components:getContainer() then
		components:getContainer():Remove(components)
	else
		playerInventory:Remove(components)
	end
	if self.blowtorch:getDelta() > 0 then self.blowtorch:Use() end
	if self.weldingrods:getDelta() > 0 then self.weldingrods:Use();self.weldingrods:Use(); end
    
	--ServerSync
	if isClient() then
        sendClientCommand("AutoGate", "install", {x = self.gate:getX(), y = self.gate:getY(), z = self.gate:getZ()})
    else
		GateUtils.installAutomaticGateMotor({x = self.gate:getX(), y = self.gate:getY(), z = self.gate:getZ()})
    end
	
	--Ending Action
	ISBaseTimedAction.perform(self)
	HaloTextHelper.addText(self.character, getText("IGUI_AutoGate_InstallComplete"), HaloTextHelper.getColorGreen())
end 

---Starts the InstallGate TimedAction
---@param character IsoPlayer The player doing the action
---@param gate IsoThumpable The target of the action
---@param blowtorch DrainableComboItem A Blowtorch with uses left
---@param weldingrods DrainableComboItem A WeldingRods with uses left
---@return ISAutoGateInstallAction
function ISAutoGateInstallAction:new(character, gate, blowtorch, weldingrods)
	local o = {}
	setmetatable(o, self)
	self.__index = self
    o.character = character
    o.gate = gate
	o.blowtorch = blowtorch
	o.weldingrods = weldingrods
	o.maxTime = 1000 - (character:getPerkLevel(Perks.MetalWelding) * 20)
	if character:isTimedActionInstant() then o.maxTime = 10 end
	
	return o
end





