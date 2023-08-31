
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/
--- GitHub Repository: https://github.com/Susjin/AutomaticGateMotors

---	All the methods related to handling the ClientCommands are listed in this file
--- @class AutoGateClientCommands
--- @return AutoGateClientCommands
    local AutoGateClientCommands = {}
----------------------------------------------------------------------------------------------
--Setting up locals
local ISAutoGateUtils = require "AutoGate/ISAutoGateUtils"

AutoGateClientCommands.onClientCommand = function(module, command, player, args)
    if isServer() then
        if module == "AutoGate" then
            if command == "install" then
                ISAutoGateUtils.installAutomaticGateMotor(args)
            elseif command == "toggleGate" then
                ISAutoGateUtils.consumeBatteryMP(args)
            end
            sendServerCommand(module, command, args)
            ISAutoGateUtils.debugMessage(string.format("From player: %s", tostring(player)))
        end
    end
end

--Add functions to events
Events.OnClientCommand.Add(AutoGateClientCommands.onClientCommand)

------------------ Returning file for 'require' ------------------
return AutoGateClientCommands