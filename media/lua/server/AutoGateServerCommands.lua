
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/

---	All the methods related to the ServerCommands are listed in this file
    local ServerCommands = {}
----------------------------------------------------------------------------------------------
---Getting the Utils file
local ISAutoGateUtils = require "ISAutoGateUtils"

local onClientCommand = function(module, command, player, args)
    if isServer() then
        if module == "AutoGate" then
            if command == "install" then
                ISAutoGateUtils.installAutomaticGateMotor(args)
            elseif command == "toggleGate" then
                ISAutoGateUtils.consumeBatteryMP(args)
            end
            sendServerCommand(module, command, args)
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
