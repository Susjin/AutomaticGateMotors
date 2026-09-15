
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to the ClientCommands are listed in this file
--- @class AutoGateServerCommands
--- @return AutoGateServerCommands
local AutoGateServerCommands = {}
----------------------------------------------------------------------------------------------
--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"

AutoGateServerCommands.onServerCommand = function(module, command, args)
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

Events.OnServerCommand.Add(AutoGateServerCommands.onServerCommand)


------------------ Returning file for 'require' ------------------
return AutoGateServerCommands