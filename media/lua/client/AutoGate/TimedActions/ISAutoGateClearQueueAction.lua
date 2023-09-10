require "TimedActions/ISBaseTimedAction"
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to the Automatic Gate Install Action are listed in this file
---	@class ISAutoGateClearQueueAction : ISBaseTimedAction
--- @field character IsoPlayer The player clearing queue
---	@return ISAutoGateClearQueueAction
local ISAutoGateClearQueueAction = ISBaseTimedAction:derive("ISAutoGateClearQueueAction")
----------------------------------------------------------------------------------------------

function ISAutoGateClearQueueAction:isValid()
    return true
end

function ISAutoGateClearQueueAction:update()

end

function ISAutoGateClearQueueAction:start()

end

function ISAutoGateClearQueueAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISAutoGateClearQueueAction:perform()
    --Ending Action
    ISBaseTimedAction.perform(self)
    ISTimedActionQueue.clear(self.character)
end

---Starts the ClearQueue TimedAction
---@param character IsoPlayer The player doing the action
---@return ISAutoGateClearQueueAction
function ISAutoGateClearQueueAction:new(character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.useProgressBar = false
    o.maxTime = 1

    return o
end

------------------ Returning file for 'require' ------------------
return ISAutoGateClearQueueAction