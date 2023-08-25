
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author: peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/

--- All the Utilities methods used in other files are listed in this file
--- @class ISAutoGateUtils
--- @return ISAutoGateUtils
	local ISAutoGateUtils = {}
----------------------------------------------------------------------------------------------

--Local variables
local totalRecipesCount = 2
local woodenGate = {
	"gate_yay_01_2",
	"gate_yay_01_3",
	"gate_yay_01_10",
	"gate_yay_01_11",
	"gate_yay_01_8",
	"gate_yay_01_9",
	"gate_yay_01_0",
	"gate_yay_01_1"
}
local metalWireGate = {
	"gate_yay_01_18",
	"gate_yay_01_19",
	"gate_yay_01_26",
	"gate_yay_01_27",
	"gate_yay_01_24",
	"gate_yay_01_25",
	"gate_yay_01_16",
	"gate_yay_01_17"
}
local metalBarsGate = {
	"gate_yay_01_34",
	"gate_yay_01_35",
	"gate_yay_01_42",
	"gate_yay_01_43",
	"gate_yay_01_40",
	"gate_yay_01_41",
	"gate_yay_01_32",
	"gate_yay_01_33"
}
local spriteSheet = {}
spriteSheet["Double Door"] = woodenGate
spriteSheet["Double Metal Wire Gate"] = metalWireGate
spriteSheet["Double Metal Pole Gate"] = metalBarsGate

local soundSheet = {}
soundSheet["Double Door"] = "WoodGate"
soundSheet["Double Metal Wire Gate"] = "MetalGate"
soundSheet["Double Metal Pole Gate"] = "MetalGate"

--Temporary global table for future Sandbox settings update
local AutoGateVars = SandboxVars.AutoGate
AutoGateVars.BatteryMaxDeltaUse = (1/ AutoGateVars.BatteryMaxUseCount)

--[[**********************************************************************************]]--

------------------ Functions related to miscellaneous utils ------------------,

---Checks if the gateModData's name is valid
---@param gateNameModData string Name of the gate
---@return boolean True if gate name is valid, false if invalid
function ISAutoGateUtils.predicateGateName(gateNameModData)
	return (gateNameModData ~= nil) and (gateNameModData ~= "")
end

---Returns the given number rounded with the number of decimal places in param2 (0 by default)
---@param number number Number to be rounded
---@param numberDecimalPlaces number Amount of decimal places
---@return number Rounded number
function ISAutoGateUtils.roundNumber(number, numberDecimalPlaces)
	local decimal = 10^(numberDecimalPlaces or 0)
	return math.floor(number * decimal + 0.5) / decimal
end

---Returns a table with 2 positions containing the sum of a given table positions and the amount of positions in that table (if not, returns 0)
---@param table table Table with numbers on all index
---@return table Table with a "total" and "count" index
function ISAutoGateUtils.sumAllTable(table)
	local sum = {}
	sum.count = 0
	sum.total = 0
	if table then
		for i=1, #table do
			sum.total = sum.total + table[i]
			sum.count = sum.count + 1
		end
	end
	if sum.total < 0 then sum.total = 0 end
	return sum
end

---Prints a debug message on the log (only works on debug mode)
---@param message String The message that will be printed on the console
function ISAutoGateUtils.debugMessage(message)
	if not getDebug() then return end
	local str = string.format("DEBUGAutoGateReborn: %s\nDEBUGAutoGateReborn: Message time: %s", tostring(message), tostring(os.date()))
	print(str)
end

--[[**********************************************************************************]]--

------------------ Functions related to recipes from the mod ------------------
---Returns a table with all AutoGate module recipes (to increase performance, stops the loop when total recipes are got)
---@return table<number, Recipe> Table with all AutoGate Recipes
function ISAutoGateUtils.getAutoGateRecipes()
	local allRecipes = getAllRecipes()
	local recipesTable = {}
	local count = 0
	for i=0, allRecipes:size()-1 do
		currentRecipe = allRecipes:get(i)
		moduleName = currentRecipe:getModule():getName()
		if (moduleName == "AutoGate") then
			table.insert(recipesTable, currentRecipe)
			count = count + 1
		end
		if count == totalRecipesCount then
			break;
		end
	end
	return recipesTable
end

---Definitions of each recipe and skills required for them
---@param recipe Recipe Recipe to be changed
function ISAutoGateUtils.setRecipeSkillRequirement(recipe)
	local recipeName = recipe:getOriginalname()
	if recipeName == "Create Controller" then
		recipe:addRequiredSkill(Perks.Electricity, AutoGateVars.LevelRequirementsMakeControllerElectrical)
	end
	if recipeName == "Create Gate Components" then
		recipe:addRequiredSkill(Perks.Electricity, AutoGateVars.LevelRequirementsMakeComponentsElectrical)
		recipe:addRequiredSkill(Perks.Mechanics,   AutoGateVars.LevelRequirementsMakeComponentsMechanics)
	end
end

---Add all the skills requirements related to each specific recipe
function ISAutoGateUtils.setSkillSpecificAutoGateRecipe()
	local modRecipes = ISAutoGateUtils.getAutoGateRecipes()
	if modRecipes then
		for i=1, #modRecipes do
			ISAutoGateUtils.setRecipeSkillRequirement(modRecipes[i])
		end
		ISAutoGateUtils.setFreeRecipesProfessions(modRecipes)
		ISAutoGateUtils.debugMessage("Skills required set to all AutoGate recipes!")
	else
		ISAutoGateUtils.debugMessage("No recipes where found!")
	end

end

function ISAutoGateUtils.setFreeRecipesProfessions(modRecipes)
	local engineer = ProfessionFactory.getProfession("engineer")
	engineer:getFreeRecipes():add("CanInstallGate")
	if modRecipes then
		for i=1, #modRecipes do
			engineer:getFreeRecipes():add(modRecipes[i]:getOriginalname())
		end
	end
	ISAutoGateUtils.debugMessage("Free recipes for Engineer set!")
end

--[[**********************************************************************************]]--

------------------ Functions related to TimedActions ------------------
local function comparatorDrainableUsesInt(item1, item2)
    return item1:getDrainableUsesInt() - item2:getDrainableUsesInt()
end
---Get the best Welding Rods inside a inventory container
---@param container ItemContainer Usually the player inventory
---@return DrainableComboItem WeldingRods with most uses left
function ISAutoGateUtils.getWeldingRodsWithMostUses(container)
    return container:getBestTypeEvalRecurse("Base.WeldingRods", comparatorDrainableUsesInt)
end

---Check if the item still have uses left
---@param inventoryItem InventoryItem Item to be checked
---@param itemType String Type of the item
---@return boolean True if has uses left, false if not
function ISAutoGateUtils.hasDeltaLeft(inventoryItem, itemType)
	if inventoryItem:getType() == itemType then
		if inventoryItem:getDelta() > 0 then
			return true
		end
	end
	return false
end

---Equips items for TimedAction
---@param player IsoPlayer Player doing the action
---@return DrainableComboItem, DrainableComboItem
function ISAutoGateUtils.checkAndEquipInstallItems(player)
	local playerInventory = player:getInventory()

	--Checking if equipped items are valid
	local equippedPrimary = player:getPrimaryHandItem()
	local alreadyEquippedPrimary = false
	if instanceof(equippedPrimary, "DrainableComboItem") then
		alreadyEquippedPrimary = ISAutoGateUtils.hasDeltaLeft(equippedPrimary, "BlowTorch")
	end	
	local equippedSecondary = player:getSecondaryHandItem()
	local alreadyEquippedSecondary = false
	if instanceof(equippedSecondary, "DrainableComboItem") then
		alreadyEquippedSecondary = ISAutoGateUtils.hasDeltaLeft(equippedSecondary, "WeldingRods")
	end
	--Setting correct items
	local blowtorch = ISBlacksmithMenu.getBlowTorchWithMostUses(playerInventory)
	if alreadyEquippedPrimary then
		blowtorch = equippedPrimary
	end
	local weldingrods = ISAutoGateUtils.getWeldingRodsWithMostUses(playerInventory)
	if alreadyEquippedSecondary then
		weldingrods = equippedSecondary
	end
	local weldingmask = playerInventory:getItemFromTypeRecurse("WeldingMask")

	ISInventoryPaneContextMenu.transferIfNeeded(player, blowtorch)
	ISInventoryPaneContextMenu.transferIfNeeded(player, weldingrods)
	ISInventoryPaneContextMenu.transferIfNeeded(player, weldingmask)
	luautils.equipItems(player, blowtorch, weldingrods)
	ISInventoryPaneContextMenu.wearItem(weldingmask, player:getPlayerNum())
	return blowtorch, weldingrods
end

---Get the items for a given interaction and equips them
---@param player IsoPlayer Player to do the action
---@param gateOrController string If the action is on a gate/controller
---@return InventoryItem, table<number,InventoryItem> Return checked item and it's container instance
function ISAutoGateUtils.checkInteractItem(player, gateOrController)
	local playerInventory = player:getInventory()
	local returnToContainer = {}
	local screwdriver = playerInventory:getItemFromTypeRecurse("Screwdriver")
	local wrench = playerInventory:getItemFromTypeRecurse("Wrench")
	if gateOrController == "controller" and screwdriver then
		table.insert(returnToContainer, screwdriver)
		ISInventoryPaneContextMenu.transferIfNeeded(player, screwdriver)
		return screwdriver, returnToContainer
	elseif gateOrController == "gate" and wrench then
		table.insert(returnToContainer, wrench)
		ISInventoryPaneContextMenu.transferIfNeeded(player, wrench)
		return wrench, returnToContainer
	elseif gateOrController == "both" and wrench and screwdriver then
		table.insert(returnToContainer, wrench)
		table.insert(returnToContainer, screwdriver)
		ISInventoryPaneContextMenu.transferIfNeeded(player, wrench)
		ISInventoryPaneContextMenu.transferIfNeeded(player, screwdriver)
		return wrench, screwdriver, returnToContainer
	end
	return nil
end

--[[**********************************************************************************]]--

------------------ Functions related to getting a specific item from containers (gate's or player's inventory) ------------------
---Simple predicate function to get a battery with charge
---@param batteriesItems table<number, InventoryItem>
local function getBatteryWithCharge(batteriesItems)
	for i=1, #batteriesItems do
		if batteriesItems[i]:getDelta() > 0 then return batteriesItems[i] end
	end
	return nil
end
---Get Car Batteries from a gate inventory
---@param gate IsoThumpable Gate corner with container
---@param getChargeOnly boolean Defines what the return value is
---@return InventoryItem|table if getChargeOnly is true, returns a table with the number of batteries and total charge. If getChargeOnly is false, returns a battery item with charge
function ISAutoGateUtils.getBatteryFromGate(gate, getChargeOnly)
	local totalBatteries = {}
	totalBatteries.item = {}
	totalBatteries.charge = {}
	if gate then
        local gateItems = gate:getItemContainer():getItems()
		for i=0, gateItems:size()-1 do
			local item = gateItems:get(i)
			local itemType = item:getType()
			if itemType == "CarBattery1" or itemType == "CarBattery2" or itemType == "CarBattery3" then
				table.insert(totalBatteries.item, item)
				table.insert(totalBatteries.charge, item:getDelta())
			end
		end
		if getChargeOnly then
			return ISAutoGateUtils.sumAllTable(totalBatteries.charge)
		else
			return getBatteryWithCharge(totalBatteries.item)
		end
    end
    return nil
end

---Get controllers inside the player inventory
---@param player IsoPlayer Player with the controller
---@param doorCode number A automatic gate motor code
---@return InventoryItem|table<number, InventoryItem> If doorCode is not nil and a connected gate is found, returns the controller item. If doorCode is nil, returns all unconnected controllers as a table
function ISAutoGateUtils.findControllerOnPlayer(player, doorCode)
    local controllers = player:getInventory():getItemsFromType("GateController")
	local emptyControllers = {}
	for i=0, controllers:size()-1, 1 do
		local controller = controllers:get(i)
		local controllerCode = controller:getModData()["AutoGateFrequency_code"]
		if doorCode == nil then
			if controllerCode == nil then
				table.insert(emptyControllers, controller)
			end
		else
			if controllerCode == doorCode then
				return controller
			end
		end
	end
	if doorCode == nil then return emptyControllers else return nil end
end

--[[**********************************************************************************]]--

------------------ Functions related to the installation of the gate's automatic motor ------------------
---Called after motor install, defines the frequency for that gate
---@param gateXYZ table<string, number> Contains the x,y and z fields with the gate corner position
function ISAutoGateUtils.installAutomaticGateMotor(gateXYZ)
    local square = getCell():getGridSquare(gateXYZ.x,gateXYZ.y,gateXYZ.z)
    local gate = ISAutoGateUtils.getGateFromSquare(square)
    local fullGate = ISAutoGateUtils.getFullGate(gate)
    local corner = fullGate[1]
	--local code = ZombRand(100, 9999)
    corner:setIsContainer(true)
    corner:getContainer():setOnlyAcceptCategory("Item")
    for i = 1, #fullGate do
		fullGate[i]:getModData()["AutoGateFrequency_X"] = corner:getX()
		fullGate[i]:getModData()["AutoGateFrequency_Y"] = corner:getY()
		fullGate[i]:getModData()["AutoGateFrequency_Z"] = corner:getZ()
		fullGate[i]:getModData()["AutoGateFrequency_code"] = 10000
		fullGate[i]:getModData()["RenameContainer_CustomName"] = getText("ContextMenu_AutoGate_GateMenu")
    end
	ISAutoGateUtils.setNewGateSprite(corner, tostring(corner:getName()))
	ISAutoGateUtils.debugMessage(corner:getModData()["AutoGateFrequency_code"])
end

---Sets the new sprite to all gate objects
---@param gateCorner IsoThumpable Corner object of the gate
---@param gateName String Name of the gate is changing sprite
function ISAutoGateUtils.setNewGateSprite(gateCorner, gateName)
	local fullGate = ISAutoGateUtils.getFullGate(gateCorner)
	if gateCorner:getNorth() then
		fullGate[1]:setSprite(spriteSheet[gateName][1])
		fullGate[2]:setSprite(spriteSheet[gateName][2])
		fullGate[3]:setSprite(spriteSheet[gateName][3])
		fullGate[4]:setSprite(spriteSheet[gateName][4])
	else
		fullGate[1]:setSprite(spriteSheet[gateName][5])
		fullGate[2]:setSprite(spriteSheet[gateName][6])
		fullGate[3]:setSprite(spriteSheet[gateName][7])
		fullGate[4]:setSprite(spriteSheet[gateName][8])
	end
	ISAutoGateUtils.debugMessage("New gate sprite set!")
end

--[[**********************************************************************************]]--

------------------ Functions related to gate's opening, closing and locking ------------------
---Set the lock of all parts of a gate and toggles lock on the corner container
---@param gate IsoThumpable Corner gate object
---@param lock boolean if true, locks the gate, if false, unlocks the gate
function ISAutoGateUtils.fullGateLock(gate, lock)
	if not gate:IsOpen() then
		local fullGate = ISAutoGateUtils.getFullGate(gate)
		if not fullGate then return nil end
		for i = 1, #fullGate do
			fullGate[i]:setLockedByKey(lock)
		end
		ISAutoGateUtils.lockBatteryContainer(fullGate[1], lock)
		if isClient() or isServer() then gate:syncIsoThumpable() end
		return true
	end
	return false
end

---Only toggles the gate lock
---@param gate IsoThumpable Any gate object
---@param player IsoPlayer Player toggling the lock
---@return boolean Returns true if toggled, if not, returns false
function ISAutoGateUtils.toggleGateLock(gate, player)
	if ISAutoGateUtils.getFrequency(gate) == nil then return end
	local gateLock = gate:isLockedByKey()
	if not gate:IsOpen() and ISAutoGateUtils.checkDistanceToGate(player, gate) then
		local toggled = ISAutoGateUtils.fullGateLock(gate, (not gateLock))
		if toggled then
			ISAutoGateUtils.gateLockSound(player, not gateLock, tostring(gate:getName()));
			ISAutoGateUtils.debugMessage("Toggled gate lock");
			return true
		end
	end
	return false
end

---Actually toggles open/close on a given gate.
---If SandboxOption "AutoLockGate" is false, the gate will never be automatically locked
---@param player IsoPlayer Player interacting with the gate
---@param gate IsoThumpable Any gate object
function ISAutoGateUtils.toggleActualGate(player, gate)
	local doneLock = false
	local currentState = gate:isLockedByKey()
	local gateName = tostring(gate:getName())
	if not AutoGateVars.AutoLockGate then
		if currentState then doneLock = ISAutoGateUtils.fullGateLock(gate, false) end
		if doneLock then ISAutoGateUtils.gateLockSound(player, false, gateName); end
		gate:ToggleDoor(player)
		ISAutoGateUtils.debugMessage("Gate toggled")
	else
		if gate:IsOpen() then
			gate:ToggleDoor(player)
			doneLock = ISAutoGateUtils.fullGateLock(gate, true)
			if doneLock then ISAutoGateUtils.gateLockSound(player, true, gateName) end
		else
			doneLock = ISAutoGateUtils.fullGateLock(gate, false)
			if doneLock and currentState then ISAutoGateUtils.gateLockSound(player, false, gateName) end
			gate:ToggleDoor(player)
		end
		ISAutoGateUtils.debugMessage("Gate and gate lock toggled")
	end
end

---Checks if the gate have a battery with charges left, if true, toggles the gate.
---@param player IsoPlayer Player interacting with the gate
---@param gate IsoThumpable Any gate object
---@return boolean Returns true if gate got toggled, else, returns false
function ISAutoGateUtils.toggleAutomaticGate(gate, player)
	--Updating SandboxVars value
	AutoGateVars.BatteryMaxDeltaUse = (1/SandboxVars.AutoGate.BatteryMaxUseCount)
	if player then
		local batteryItem = ISAutoGateUtils.getBatteryFromGate(gate, false)
		if ISAutoGateUtils.checkDistanceToGate(player, gate) and batteryItem then
			local batteryDelta = batteryItem:getDelta()
			if batteryDelta > 0 then
				--To work with MP and SP
				if not isClient() and not isServer() then
					ISAutoGateUtils.toggleActualGate(player, gate)
					if (batteryDelta >= AutoGateVars.BatteryMaxDeltaUse) then
						batteryItem:setDelta(batteryDelta - AutoGateVars.BatteryMaxDeltaUse)
					else
						batteryItem:setDelta(0.0)
					end
				else
					ISAutoGateUtils.toggleActualGate(player, gate)
					sendClientCommand(player, "AutoGate", "toggleGate", {x = gate:getX(), y = gate:getY(), z = gate:getZ()})
					gate:syncIsoThumpable()
				end
			end
		end
	end
	return false
end

---Checks if the player is within the max range (set by the SandboxSettings) to the gate
---@param player IsoPlayer Player to be checked
---@param gate IsoThumpable Any gate object
---@return boolean Returns true if the player is within range, if not, returns false
function ISAutoGateUtils.checkDistanceToGate(player, gate)
    if gate and (gate:getSquare():DistTo(player:getSquare()) < AutoGateVars.ControllerRange) then
        return true
    end
    return false
end

---Consumes the battery of the gate - Only used in MP
---@param gateXYZ table Contains the XYZ coordinates of the gate
function ISAutoGateUtils.consumeBatteryMP(gateXYZ)
	local square = getCell():getGridSquare(gateXYZ.x,gateXYZ.y,gateXYZ.z)
	local gate = ISAutoGateUtils.getGateFromSquare(square)

	local batteryItem = ISAutoGateUtils.getBatteryFromGate(gate, false)
	if batteryItem then
		local batteryDelta = batteryItem:getDelta()
		if batteryDelta > 0 then
			if (batteryDelta >= AutoGateVars.BatteryMaxDeltaUse) then
				batteryItem:setDelta(batteryDelta - AutoGateVars.BatteryMaxDeltaUse)
			else
				batteryItem:setDelta(0.0)
			end
		end
	end
end

---Locks a gate battery container regarding the current gate isLocked status
---@param gate IsoThumpable Corner gate object
---@return boolean Returns true if the container got locked/unlocked
function ISAutoGateUtils.lockBatteryContainer(gate, lock)
	if not gate then return false end
	if gate:getContainer() == nil then ISAutoGateUtils.debugMessage("Not a container"); return false; end
	gate:setLockedByPadlock(lock)
	return true
end

---Plays the door lock/unlock sound on the player based on the current gate state
---@param player IsoPlayer Player interacting with the gate
---@param gateLock boolean Gate lock state - If true, plays the lock sound, if false, plays the unlock sound
---@param gateName string The name of the current selected gate
function ISAutoGateUtils.gateLockSound(player, gateLock, gateName)
	if gateLock then
		player:getEmitter():playSound(soundSheet[gateName] .. "Unlock")
	else
		player:getEmitter():playSound(soundSheet[gateName] .. "Lock")
	end
end

---Similar to "getText()" but for the mod's locking strings
---@param gateLock boolean If the gate is currently locked/unlocked
---@param location String Where the text will be used
---@return String Returns the correct string for the lock and location
function ISAutoGateUtils.getGateLockText(gateLock, location)
	if gateLock then
		if location == "context" then
			return getText("ContextMenu_AutoGate_UnlockGate")
		end
		if location == "tooltipTitle" then
			return getText("Tooltip_AutoGate_UnlockGate")
		end
		if location == "tooltipDescription" then
			return getText("Tooltip_AutoGate_UnlockGateDescription")
		end
	else
		if location == "context" then
			return getText("ContextMenu_AutoGate_LockGate")
		end
		if location == "tooltipTitle" then
			return getText("Tooltip_AutoGate_LockGate")
		end
		if location == "tooltipDescription" then
			return getText("Tooltip_AutoGate_LockGateDescription")
		end
	end
end

--[[**********************************************************************************]]--

------------------ Functions that get the Gate position from object or vice-versa (also by frequency) ------------------
---Gets a IsoThumpable Gate Object from a IsoSquare
---@param isoGridSquare IsoGridSquare Position to search for
---@return IsoThumpable Returns gate object found, if not, returns nil
function ISAutoGateUtils.getGateFromSquare(isoGridSquare)
	if not isoGridSquare then return nil end
	for i=0, isoGridSquare:getObjects():size()-1 do
        local object = isoGridSquare:getObjects():get(i)
        local name = tostring(object:getName())
        if (instanceof(object, "IsoThumpable")) and
			((name == "Double Door") or (name == "Double Metal Pole Gate") or (name == "Double Metal Wire Gate")) then
            return object
        end
    end
	return nil
end

---Gets the left-most corner IsoSquare of a Gate Object
---@param gate IsoThumpable Any gate object
---@return IsoGridSquare Returns the position of the corner gate
function ISAutoGateUtils.getGateCorner(gate)
	if not gate then return nil end
    local gateSquare = gate:getSquare()
    local isNorth = gate:getNorth()
    local gateProperties = tonumber(gateSquare:getProperties():Val("DoubleDoor"))
    local x = gateSquare:getX()
    local y = gateSquare:getY()
    local z = gateSquare:getZ()
    if gateProperties == 1 or gateProperties == 5 then
        return gateSquare
    end
    if isNorth then
        if gateProperties == 2 then
            return getCell():getGridSquare(x-1,y,z)
        elseif gateProperties == 3 then
            return getCell():getGridSquare(x-2,y,z)
        elseif gateProperties == 4 or gateProperties == 8 then
            return getCell():getGridSquare(x-3,y,z)
        elseif gateProperties == 6 then
            return getCell():getGridSquare(x,y-1,z)
        else
            return getCell():getGridSquare(x-3,y-1,z)
        end
    else
        if gateProperties == 2 then
            return getCell():getGridSquare(x,y+1,z)
        elseif gateProperties == 3 then
            return getCell():getGridSquare(x,y+2,z)
        elseif gateProperties == 4 or gateProperties == 8 then
            return getCell():getGridSquare(x,y+3,z)
        elseif gateProperties == 6 then
            return getCell():getGridSquare(x-1,y,z)
        else
            return getCell():getGridSquare(x-1,y+3,z)
        end
    end
end

---Gets all the 4 objects of a gate
---@param gate IsoThumpable Any gate object
---@return table<number, IsoThumpable> Returns a table with all 4 gate objects within (indexes 1->4, left->right)
function ISAutoGateUtils.getFullGate(gate)
	if not gate then return nil end
	---@type table<number, IsoThumpable>
    local fullGate = {}
    local corner = ISAutoGateUtils.getGateCorner(gate)
    local isNorth = gate:getNorth()
	if not corner then return nil end
    local x = corner:getX()
    local y = corner:getY()
    local z = corner:getZ()
    fullGate[1] = ISAutoGateUtils.getGateFromSquare(corner)
    local offsetX = 0
    local offsetY = 0
    for i = 1, 3 do
        if isNorth then
            offsetX = i
        else
            offsetY = -i
        end
        local gridSquare = getCell():getGridSquare(x+ offsetX, y+ offsetY, z)
        local gateInCell = ISAutoGateUtils.getGateFromSquare(gridSquare)
        if gateInCell then
            table.insert(fullGate, gateInCell)
        end
    end
	if gate:IsOpen() then
		if isNorth then
			y = y+1
		else
			x = x+1
		end
		for i = 0, 3 do
			if isNorth then
				offsetX = i
			else
				offsetY = -i
			end
			local gridSquare = getCell():getGridSquare(x+ offsetX, y+ offsetY, z)
			local gateInCell = ISAutoGateUtils.getGateFromSquare(gridSquare)
			if gateInCell then
				table.insert(fullGate, gateInCell)
			end
		end
	end
    return fullGate
end

---Gets a specific gate from a frequency
---@param frequency table Contains the x, y, z and code of a gate
---@return IsoThumpable If found, returns the gate corner object, if not, returns nil
function ISAutoGateUtils.getGateFromFrequency(frequency)
	local square = getCell():getGridSquare(frequency[1],frequency[2],frequency[3])
    if square then
        local gate = ISAutoGateUtils.getGateFromSquare(square)
		if gate then
			if gate:getModData()["AutoGateFrequency_code"] == frequency[4] then
				return gate
			end
		end
	end
	return nil
end

--[[**********************************************************************************]]--

------------------ Functions related to gate frequency and connecting ------------------
---Gets a table with 5 positions containing the X, Y, Z, code and controllers from a Object
---@param obj IsoThumpable|InventoryItem Any gate object/controller item
---@return table Returns the table with frequency info, if none, returns nil
function ISAutoGateUtils.getFrequency(obj)
    local frequency = {}
    frequency[1] = obj:getModData()["AutoGateFrequency_X"]
    if frequency[1] == nil then
        return nil
    end
    frequency[2] = obj:getModData()["AutoGateFrequency_Y"]
    frequency[3] = obj:getModData()["AutoGateFrequency_Z"]
    frequency[4] = obj:getModData()["AutoGateFrequency_code"]
    return frequency
end

---Copies the frequency from one controller to another
---@param controllerTo InventoryItem Controller without a frequency
---@param controllerFrom InventoryItem Controller with a frequency
---@return boolean Returns true if the action is successful, if not, returns false
function ISAutoGateUtils.makeControllerCopy(controllerFrom, controllerTo)
    local frequency = ISAutoGateUtils.getFrequency(controllerFrom)
    if frequency then
        controllerTo:getModData()["AutoGateFrequency_X"] = frequency[1]
        controllerTo:getModData()["AutoGateFrequency_Y"] = frequency[2]
        controllerTo:getModData()["AutoGateFrequency_Z"] = frequency[3]
        controllerTo:getModData()["AutoGateFrequency_code"] = frequency[4]
		controllerTo:setName(controllerFrom:getName())
		controllerTo:setCustomName(true)
		return true
    end
	return false
end

---Connects a controller to a gate, copying it's frequency
---@param controller InventoryItem Controller without a frequency
---@param gate IsoThumpable Gate with a motor installed
---@return boolean Returns true if the action is successful, if not, returns false
function ISAutoGateUtils.connectGateController(controller, gate)
	local frequency = ISAutoGateUtils.getFrequency(gate)
	local gateName = gate:getModData()["RenameContainer_CustomName"]
	if frequency[4] > 9999 then ISAutoGateUtils.resetGate(gate, false); frequency = ISAutoGateUtils.getFrequency(gate) end
	if frequency then
		controller:getModData()["AutoGateFrequency_X"] = frequency[1]
		controller:getModData()["AutoGateFrequency_Y"] = frequency[2]
		controller:getModData()["AutoGateFrequency_Z"] = frequency[3]
		controller:getModData()["AutoGateFrequency_code"] = frequency[4]
		if ISAutoGateUtils.predicateGateName(gateName) then
			ISAutoGateUtils.renameController(controller, gateName, frequency[4])
			return true
		end
		controller:setName(getText("ContextMenu_AutoGate_GateMenu") .. " - No. ".. frequency[4])
		controller:setCustomName(true)
		return true
	end
	return false
end

---Empties controller frequency, disconnecting it from the gate previously connected
---@param controller InventoryItem Controller with a frequency
---@return boolean Returns true if the action is successful, if not, returns false
function ISAutoGateUtils.clearController(controller)
	local frequency = ISAutoGateUtils.getFrequency(controller)
	if not frequency then
		return false
	end
	controller:getModData()["AutoGateFrequency_X"] 	  = nil
	controller:getModData()["AutoGateFrequency_Y"] 	  = nil
	controller:getModData()["AutoGateFrequency_Z"] 	  = nil
	controller:getModData()["AutoGateFrequency_code"] = nil
	controller:setName(getItemNameFromFullType("AutoGate.GateController"))
	controller:setCustomName(false)
	ISAutoGateUtils.debugMessage("Controller frequency cleared")
	return true
end

---Reset the gate code (from gate square), disconnecting all controllers linked to it
---@param gate IsoThumpable Gate with a motor installed
---@param resetName boolean If true, the name will also be reset
function ISAutoGateUtils.resetGate(gate, resetName)
    local fullGate = ISAutoGateUtils.getFullGate(gate)
    local corner = fullGate[1]
	local code = 0
	--Make sure it's not the same code
	repeat
		code = ZombRand(100, 9999)
	until code ~= corner:getModData()["AutoGateFrequency_code"]

    for i = 1,  #fullGate do
		fullGate[i]:getModData()["AutoGateFrequency_code"] = code
		if resetName then fullGate[i]:getModData()["RenameContainer_CustomName"] = getText("ContextMenu_AutoGate_GateMenu") end
		fullGate[i]:transmitModData()
    end
	ISAutoGateUtils.fullGateLock(corner, false)
	ISAutoGateUtils.debugMessage(corner:getModData()["AutoGateFrequency_code"])
end

---Rename all the objects of a given gate to a given name
---@param gate IsoThumpable Gate piece to be renamed
---@param gateName string New name of the gate
function ISAutoGateUtils.fullGateRename(gate, gateName)
	local fullGate = ISAutoGateUtils.getFullGate(gate)
	for i = 1, #fullGate do
		if ISAutoGateUtils.predicateGateName(gateName) then
			fullGate[i]:getModData()["RenameContainer_CustomName"] = gateName
			fullGate[i]:transmitModData()
		end
	end
end

---Changes the name of the controller to the given gate name and code
---@param controllerOrFrequency InventoryItem|table Controller to get renamed|Frequency table with name in 5 index
---@param gateName string Name of the gate
---@param gateCode string Code of the gate
---@param player IsoPlayer Player with the controller on the inventory
function ISAutoGateUtils.renameController(controllerOrFrequency, gateName, gateCode, player)
	if not controllerOrFrequency then return end
	if instanceof(controllerOrFrequency, "InventoryItem") and gateName and gateCode then
		controllerOrFrequency:setName(gateName .. " - No. " .. gateCode)
		controllerOrFrequency:setCustomName(true)
		ISInventoryPage.dirtyUI()
	elseif player and controllerOrFrequency[5] then
		local controller = ISAutoGateUtils.findControllerOnPlayer(player, controllerOrFrequency[4])
		if controller then
			controller:setName(controllerOrFrequency[5] .. " - No. " .. controllerOrFrequency[4])
			controller:setCustomName(true)
			ISInventoryPage.dirtyUI()
		end
	end
end

--[[**********************************************************************************]]--

------------------ Add functions to events ------------------
Events.OnGameBoot.Add(ISAutoGateUtils.setSkillSpecificAutoGateRecipe)


------------------ Returning file for 'require' ------------------
return ISAutoGateUtils