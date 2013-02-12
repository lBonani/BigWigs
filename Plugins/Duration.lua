-------------------------------------------------------------------------------
-- Module Declaration
--

-- XXX EXPERIMENTAL MODULE, ALL CODE/FEATURES MAY CHANGE

local plugin = BigWigs:NewPlugin("Duration")
if not plugin then return end

-------------------------------------------------------------------------------
-- Locals
--

--local L = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Plugins")
local SecondsToTime = SecondsToTime
local activeDurations = nil

-------------------------------------------------------------------------------
-- Initialization
--

local dev = true
function plugin:OnPluginEnable()
	if not BigWigsDurationDB then
		BigWigsDurationDB = {}
	end

	if not activeDurations then
		activeDurations = {}
	end

	if not dev then
		self:RegisterMessage("BigWigs_OnBossEngage")
		self:RegisterMessage("BigWigs_OnBossWin")
		self:RegisterMessage("BigWigs_OnBossReboot")
	end
end

-------------------------------------------------------------------------------
-- Event Handlers
--

function plugin:BigWigs_OnBossEngage(event, module)
	if module.encounterId then
		BigWigs:Print("Boss", module.moduleName, "engaged.")
		activeDurations[module.encounterId] = GetTime()
	end
end

function plugin:BigWigs_OnBossWin(event, module)
	if module.encounterId and activeDurations[module.encounterId] then
		BigWigs:Print("Boss", module.moduleName, "defeated after", SecondsToTime(GetTime()-lastTime))
		activeDurations[module.encounterId] = nil
	end
end

function plugin:BigWigs_OnBossReboot(event, module)
	if module.encounterId and activeDurations[module.encounterId] then
		BigWigs:Print("Boss", module.moduleName, "wiped after", SecondsToTime(GetTime()-lastTime))
		activeDurations[module.encounterId] = nil
	end
end

