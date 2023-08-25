
----------------------------------------------------------------------------------------------
---	Automatic Gate Motors
---	@author peteR_pg
---	Steam profile: https://steamcommunity.com/id/peter_pg/

---	All the Tooltips methods are listed in this file
---	@class ISAutoGateTooltip
	ISAutoGateTooltip = {}
----------------------------------------------------------------------------------------------

--Local tables to store all functions
---@see ISAutoGateUtils
---@type ISAutoGateUtils
local GateUtils = ISAutoGateUtils

--Local variables
local AutoGateVars   = SandboxVars.AutoGate
local remoteTexture = "Item_RemoteCrafted"
local installTexture = { }
installTexture["Double Door"] = "gate_yay_01_8"
installTexture["Double Metal Wire Gate"] = "gate_yay_01_24"
installTexture["Double Metal Pole Gate"] = "gate_yay_01_40"

---Declare colors table to use in tooltips
local colors = {}
colors.colorWhite = " <RGB:1,1,1> "
colors.colorUse   = nil

---Get the colors from each user setting in accessibility and sets tooltips colors as which
local function getColorsFromAccessibility()
	colors.colorGood = " <RGB:" .. getCore():getGoodHighlitedColor():getR() .. "," .. getCore():getGoodHighlitedColor():getG() .. "," .. getCore():getGoodHighlitedColor():getB() .. "> "
	colors.colorBad  = " <RGB:" .. getCore():getBadHighlitedColor():getR() .. "," .. getCore():getBadHighlitedColor():getG() .. "," .. getCore():getBadHighlitedColor():getB() .. "> "
end

local old_apply = MainOptions.apply
---Check the colors everytime player clicks on "Apply"
function MainOptions.apply(...)
	old_apply(...)
	getColorsFromAccessibility()
end

---Load colors for tooltips on startup
getColorsFromAccessibility()

--[[**********************************************************************************]]--

---Shows a tooltip for a InstallGate ContextMenu Option
---@param installOption table Contains a given option inside a ContextMenu
---@param components number Amount of components on player's inventory
---@param blowtorch number Amount of blowtorch uses on player's inventory
---@param weldingrods number Amount of weldingrods uses on player's inventory
---@param weldingmask number Amount of weldingmasks on player's inventory
---@param metalWelding number MetalWelding level of the player
---@param gateOpen boolean True if the gate is open, false if not
---@param gateName string Name of the gate that will get motor installed
function ISAutoGateTooltip.installGate(installOption, components, blowtorch, weldingrods, weldingmask, metalWelding, gateOpen, gateName)
	---@type ISToolTip
	installOption.toolTip = ISToolTip:new()
	installOption.toolTip:initialise()
	installOption.toolTip:setVisible(true)
	installOption.toolTip:setTexture(installTexture[gateName])
	installOption.toolTip:setName(getText("Tooltip_AutoGate_InstallComponents"))

	installOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_InstallComponentsDescription") .. " <LINE><LINE> "
	installOption.toolTip.description = installOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "
    if blowtorch 	< 0.092 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.BlowTorch") .. " " .. getText("ContextMenu_Uses") .. " " .. tostring(math.ceil(blowtorch*10)) .. "/1 <LINE> "
	if weldingrods 	< 0.084 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.WeldingRods") .. " " .. getText("ContextMenu_Uses") .. " " .. tostring(math.ceil(weldingrods*20)) .. "/2 <LINE> "
    if weldingmask 	< 1 	then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.WeldingMask") .. " " .. tostring(weldingmask) .. "/1 <LINE> "
	if components 	< 1 	then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("AutoGate.GateComponents") .. " " .. tostring(components) .. "/1 <LINE><LINE> "
	if metalWelding < AutoGateVars.LevelRequirementsInstallMetalWelding 	then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		installOption.toolTip.description = installOption.toolTip.description .. colors.colorUse .. getText("IGUI_perks_MetalWelding") .. " " .. tostring(metalWelding) .. "/" .. tostring(AutoGateVars.LevelRequirementsInstallMetalWelding) .. " <LINE> "
	if gateOpen then installOption.toolTip.footNote = getText("Tooltip_AutoGate_CantInstallFootNote") end
end

---Shows a tooltip for a ConnectController ContextMenu Option
---@param connectOption table Contains a given option inside a ContextMenu
---@param amountEmpty number Amount of disconnected controllers on player inventory
---@param electrical number Electrical level of the Player
---@param mechanics number Mechanics level of the Player
---@param wrench number Amount of Wrench(s) on player inventory
---@param screwdriver number Amount of Screwdriver(s) on player inventory
---@param gateName string Name of the gate to be connected to
function ISAutoGateTooltip.connectController(connectOption, amountEmpty, electrical, mechanics, wrench, screwdriver, gateName)
    ---@type ISToolTip
	connectOption.toolTip = ISToolTip:new()
    connectOption.toolTip:initialise()
	connectOption.toolTip:setTexture(installTexture[gateName])
	connectOption.toolTip:setVisible(true)
	connectOption.toolTip.footNote = getText("Tooltip_AutoGate_UndoneFootNote")
    connectOption.toolTip:setName(getText("Tooltip_AutoGate_Connecting"))

	connectOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_ConnectingDescription") .. " <LINE><LINE> "
	connectOption.toolTip.description = connectOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "
	if wrench 	   < 1	then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		connectOption.toolTip.description = connectOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.Wrench") .. " " .. tostring(wrench) .. "/1 <LINE> "
	if screwdriver < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		connectOption.toolTip.description = connectOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.Screwdriver") .. " " .. tostring(screwdriver) .. "/1 <LINE> "
	if amountEmpty < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		connectOption.toolTip.description = connectOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("AutoGate.GateController") .. " " .. tostring(amountEmpty) .. "/1 <LINE> "
	if electrical  < AutoGateVars.LevelRequirementsControllerInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		connectOption.toolTip.description = connectOption.toolTip.description .. colors.colorUse .. " <LINE> " .. getText("IGUI_perks_Electricity") .. " " .. tostring(electrical) .. "/" .. tostring(AutoGateVars.LevelRequirementsControllerInteraction) .. " <LINE> "
	if mechanics   < AutoGateVars.LevelRequirementsGateInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		connectOption.toolTip.description = connectOption.toolTip.description .. colors.colorUse .. getText("IGUI_perks_Mechanics") .. " " .. tostring(mechanics) .. "/" .. tostring(AutoGateVars.LevelRequirementsGateInteraction) .. " <LINE> "
end

---Shows a tooltip for a ResetGate ContextMenu Option
---@param resetOption table Contains a given option inside a ContextMenu
---@param electrical number Electrical level of the player
---@param mechanics number Mechanics level of the Player
---@param wrench number Amount of Wrench(s) on player inventory
---@param gateName string Name of the gate to be reset
function ISAutoGateTooltip.resetGate(resetOption, electrical, mechanics, wrench, gateName)
	---@type ISToolTip
	resetOption.toolTip = ISToolTip:new()
	resetOption.toolTip:initialise()
	resetOption.toolTip:setVisible(true)
	resetOption.toolTip:setTexture(installTexture[gateName])
	resetOption.toolTip:setName(getText("Tooltip_AutoGate_Reset"))
	resetOption.toolTip.footNote = getText("Tooltip_AutoGate_UndoneFootNote")
	resetOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_ResetDescription") .. " <LINE><LINE> "

	if resetOption.notAvailable then
		resetOption.toolTip.description = resetOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "
		if  wrench < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
			resetOption.toolTip.description = resetOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.Wrench") .. " " .. tostring(wrench) .. "/1 <LINE> "
		resetOption.toolTip.description = resetOption.toolTip.description .. colors.colorGood .. getText("Tooltip_AutoGate_AutomaticGateMotor") .. " " .. tostring(1) .. "/1 <LINE> "
		if electrical  < AutoGateVars.LevelRequirementsControllerInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
			resetOption.toolTip.description = resetOption.toolTip.description .. colors.colorUse .. " <LINE> " .. getText("IGUI_perks_Electricity") .. " " .. tostring(electrical) .. "/" .. tostring(AutoGateVars.LevelRequirementsControllerInteraction) .. " <LINE> "
		if mechanics  < AutoGateVars.LevelRequirementsGateInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
			resetOption.toolTip.description = resetOption.toolTip.description .. colors.colorUse .. getText("IGUI_perks_Mechanics") .. " " .. tostring(mechanics) .. "/" .. tostring(AutoGateVars.LevelRequirementsGateInteraction) .. " <LINE> "
	else
		resetOption.toolTip.description = resetOption.toolTip.description .. " <LINE><LINE><LINE> " .. colors.colorBad .. getText("Tooltip_AutoGate_UndoneDescription") .. " <LINE> "
	end
end

---Shows a tooltip for a RenameGate ContextMenu Option
---@param renameOption table Contains a given option inside a ContextMenu
---@param electrical number Electrical level of the player
---@param mechanics number Mechanics level of the Player
---@param wrench number Amount of Wrench(s) on player inventory
---@param gateName string Name of the gate to be reset
function ISAutoGateTooltip.renameGate(renameOption, electrical, mechanics, wrench, gateName)
	---@type ISToolTip
	renameOption.toolTip = ISToolTip:new()
	renameOption.toolTip:initialise()
	renameOption.toolTip:setVisible(true)
	renameOption.toolTip:setTexture(installTexture[gateName])
	renameOption.toolTip:setName(getText("Tooltip_AutoGate_Rename"))
	renameOption.toolTip.footNote = getText("Tooltip_AutoGate_RenameFootNote")
	renameOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_RenameDescription") .. " <LINE><LINE> "

	renameOption.toolTip.description = renameOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "
	if  wrench < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		renameOption.toolTip.description = renameOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.Wrench") .. " " .. tostring(wrench) .. "/1 <LINE> "
	renameOption.toolTip.description = renameOption.toolTip.description .. colors.colorGood .. getText("Tooltip_AutoGate_AutomaticGateMotor") .. " " .. tostring(1) .. "/1 <LINE> "
	if electrical  < AutoGateVars.LevelRequirementsControllerInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		renameOption.toolTip.description = renameOption.toolTip.description .. colors.colorUse .. " <LINE> " .. getText("IGUI_perks_Electricity") .. " " .. tostring(electrical) .. "/" .. tostring(AutoGateVars.LevelRequirementsControllerInteraction) .. " <LINE> "
	if mechanics  < AutoGateVars.LevelRequirementsGateInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		renameOption.toolTip.description = renameOption.toolTip.description .. colors.colorUse .. getText("IGUI_perks_Mechanics") .. " " .. tostring(mechanics) .. "/" .. tostring(AutoGateVars.LevelRequirementsGateInteraction) .. " <LINE> "
end

---Shows a tooltip for a UseController ContextMenu Option
---@param useControllerOption table Contains a given option inside a ContextMenu
---@param batteryCharge table Contains a sum of the current charge of batteries and the amount of batteries
---@param gateExists boolean true if the gate could be found, else false
function ISAutoGateTooltip.useFromGateOrControllerConnected(useControllerOption, batteryCharge, gateExists, playerDistanceValid)
	---@type ISToolTip
	useControllerOption.toolTip = ISToolTip:new()
	useControllerOption.toolTip:initialise()
	useControllerOption.toolTip:setVisible(true)
	useControllerOption.toolTip:setTexture(remoteTexture)
	useControllerOption.toolTip:setName(getText("Tooltip_AutoGate_Open"))

	if gateExists and playerDistanceValid then
		useControllerOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_OpenDescription") .. " <LINE><LINE> "
		useControllerOption.toolTip.description = useControllerOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "
		if (batteryCharge.total <= 0) then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		if (batteryCharge.count > 0) then
			useControllerOption.toolTip.description = useControllerOption.toolTip.description .. colors.colorUse .. getText("Tooltip_AutoGate_BatteryCharge") .. " " .. tostring(GateUtils.roundNumber(batteryCharge.total*AutoGateVars.BatteryMaxUseCount)) .. "/" .. tostring(AutoGateVars.BatteryMaxUseCount*batteryCharge.count) .. " <LINE> "
		else
			useControllerOption.toolTip.description = useControllerOption.toolTip.description .. colors.colorBad .. getText("Tooltip_AutoGate_NoBatteries") .. " <LINE> "
		end
	else
		useControllerOption.toolTip.footNote = getText("Tooltip_AutoGate_GateNotFoundFootNote")
		useControllerOption.toolTip.description = colors.colorBad .. getText("Tooltip_AutoGate_GateNotFound") .. " <LINE> "
	end
end

---Shows a tooltip for a LockGate/UnlockGate ContextMenu Option
---@param lockOption table Contains a given option inside a ContextMenu
---@param gateLock boolean True if gate is locked, false if not
---@param gateOpen boolean True if gate is open, false if not
function ISAutoGateTooltip.lockGate(lockOption, gateLock, gateOpen)
	lockOption.toolTip = ISToolTip:new()
    lockOption.toolTip:initialise()
    lockOption.toolTip:setVisible(true)
	lockOption.toolTip:setTexture(remoteTexture)
    lockOption.toolTip:setName(GateUtils.getGateLockText(gateLock, "tooltipTitle"))

	lockOption.toolTip.description = colors.colorWhite .. GateUtils.getGateLockText(gateLock, "tooltipDescription") .. " <LINE> "
	if gateOpen then lockOption.toolTip.footNote = getText("Tooltip_AutoGate_CantLock") end
end

---Shows a tooltip for a CopyController ContextMenu Option
---@param copyControllerOption table Contains a given option inside a ContextMenu
---@param amountEmpty number Amount of disconnected controllers on player's inventory
---@param electrical number Electrical level of the player
---@param screwdriver number Amount of Screwdriver(s) on player inventory
function ISAutoGateTooltip.copyController(copyControllerOption, amountEmpty, electrical, screwdriver)
    copyControllerOption.toolTip = ISToolTip:new()
    copyControllerOption.toolTip:initialise()
	copyControllerOption.toolTip:setTexture(remoteTexture)
    copyControllerOption.toolTip:setVisible(true)
    copyControllerOption.toolTip:setName(getText("Tooltip_AutoGate_Copy"))
	copyControllerOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_CopyDescription") .. " <LINE><LINE> "
	
	copyControllerOption.toolTip.description = copyControllerOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "
	if screwdriver < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		copyControllerOption.toolTip.description = copyControllerOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.Screwdriver") .. " " .. tostring(screwdriver) .. "/1 <LINE> "
    if amountEmpty < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		copyControllerOption.toolTip.description = copyControllerOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("AutoGate.GateController") .. " " .. tostring(amountEmpty) .. "/1 <LINE> "
	if electrical  < AutoGateVars.LevelRequirementsControllerInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		copyControllerOption.toolTip.description = copyControllerOption.toolTip.description .. colors.colorUse .. " <LINE> " .. getText("IGUI_perks_Electricity") .. " " .. tostring(electrical) .. "/" .. tostring(AutoGateVars.LevelRequirementsControllerInteraction) .. " <LINE> "
end

---Shows a tooltip for a ClearController ContextMenu Option
---@param clearControllerOption table Contains a given option inside a ContextMenu
---@param electrical number Electrical level of the player
---@param screwdriver number Amount of Screwdriver(s) on player inventory
function ISAutoGateTooltip.clearController(clearControllerOption, electrical, screwdriver)
	---@type ISToolTip
	clearControllerOption.toolTip = ISToolTip:new()
	clearControllerOption.toolTip:initialise()
	clearControllerOption.toolTip:setTexture(remoteTexture)
	clearControllerOption.toolTip:setVisible(true)
	clearControllerOption.toolTip:setName(getText("Tooltip_AutoGate_ClearController"))
	clearControllerOption.toolTip.description = colors.colorWhite .. getText("Tooltip_AutoGate_ClearControllerDescription") .. " <LINE><LINE> "

	if clearControllerOption.notAvailable then
		clearControllerOption.toolTip.description = clearControllerOption.toolTip.description .. getText("Tooltip_craft_Needs") .. ": <LINE> "
		if screwdriver < 1 then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		clearControllerOption.toolTip.description = clearControllerOption.toolTip.description .. colors.colorUse .. getItemNameFromFullType("Base.Screwdriver") .. " " .. tostring(screwdriver) .. "/1 <LINE> "
		clearControllerOption.toolTip.description = clearControllerOption.toolTip.description .. colors.colorGood .. clearControllerOption.param1:getDisplayName() .. " " .. tostring(1) .. "/1 <LINE> "
		if electrical  < AutoGateVars.LevelRequirementsControllerInteraction then colors.colorUse = colors.colorBad else colors.colorUse = colors.colorGood end
		clearControllerOption.toolTip.description = clearControllerOption.toolTip.description .. colors.colorUse .. " <LINE> " .. getText("IGUI_perks_Electricity") .. " " .. tostring(electrical) .. "/" .. tostring(AutoGateVars.LevelRequirementsControllerInteraction) .. " <LINE> "
	else
		clearControllerOption.toolTip.footNote = getText("Tooltip_AutoGate_UndoneFootNote")
		clearControllerOption.toolTip.description = clearControllerOption.toolTip.description .. colors.colorBad .. getText("Tooltip_AutoGate_UndoneDescription") .. " <LINE> "
	end
end
