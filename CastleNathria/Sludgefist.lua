--------------------------------------------------------------------------------
-- TODO:
-- -- Check sound with Stomp + Shift

--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Sludgefist", 2296, 2394)
if not mod then return end
mod:RegisterEnableMob(164407) -- Sludgefist
mod.engageId = 2399
mod.respawnTime = 15

--------------------------------------------------------------------------------
-- Locals
--
local destructiveStompCount = 1
local colossalRoarCount = 1
local chainLinkCount = 1
local hatefullGazeCount = 1
local chainSlamCount = 1
local seismicShiftCount = 1
local chainLinksApplied = 0

local timers = {
	[332318] = {18.5, 25.1, 42.6, 25.5, 42.5, 25.5, 45, 22.5, 45.0, 23.1, 41.4}, -- Destructive Stomp
	[332687] = {0.0, 36.7, 31.3, 36.4, 31.8, 36.3, 31.5, 36.4, 31.8, 36.3, 31.5, 36.3}, -- Colossal Roar
	[340817] = {18.5, 25.1, 30.6, 11.9, 25.5, 30.2, 12.3, 25.5} -- Seismic Shift
}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.stomp_shift = "Stomp & Shift" -- Destructive Stomp + Seismic Shift

	L.custom_off_boulder_impact = "Boulder Impact"
	L.custom_off_boulder_impact_desc = "Show a bar when the Fractured Boulder lands."
	L.custom_off_boulder_impact_icon = 341102
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{331209, "SAY" ,"SAY_COUNTDOWN"}, -- Hateful Gaze
		331314, -- Destructive Impact
		"custom_off_boulder_impact",
		335293, -- Chain Link
		332318, -- Destructive Stomp
		335361, -- Stonequake
		332687, -- Colossal Roar
		{335470, "SAY", "SAY_COUNTDOWN", "ICON"}, -- Chain Slam
		340817, -- Seismic Shift
		341250, -- Gruesome Rage
	},{
		[331209] = "general",
		[340817] = "mythic",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "HatefulGazeApplied", 331209)
	self:Log("SPELL_AURA_REMOVED", "HatefulGazeRemoved", 331209)
	self:Log("SPELL_AURA_APPLIED", "DestructiveImpactApplied", 331314)
	self:Log("SPELL_AURA_REMOVED", "DestructiveImpactRemoved", 331314)
	self:Log("SPELL_AURA_APPLIED", "ChainThemApplied", 342420, 342419) -- Pre chain debuff
	self:Log("SPELL_CAST_START", "DestructiveStomp", 332318)
	self:Log("SPELL_CAST_SUCCESS", "ColossalRoar", 332687)
	self:Log("SPELL_AURA_APPLIED", "ChainSlamApplied", 335470)
	self:Log("SPELL_AURA_REMOVED", "ChainSlamRemoved", 335470)
	self:Log("SPELL_AURA_APPLIED", "GruesomeRageApplied", 341250)

	-- Mythic
	self:Log("SPELL_AURA_APPLIED", "SeismicShiftApplied", 340817)

	self:Log("SPELL_AURA_APPLIED", "GroundDamage", 335361) -- Stonequake
	self:Log("SPELL_PERIODIC_DAMAGE", "GroundDamage", 335361)
	self:Log("SPELL_PERIODIC_MISSED", "GroundDamage", 335361)
end

function mod:OnEngage()
	destructiveStompCount = 1
	colossalRoarCount = 1
	chainLinkCount = 1
	hatefullGazeCount = 1
	chainSlamCount = 1
	seismicShiftCount = 1
	chainLinksApplied = 0

	self:Bar(335293, 5, CL.count:format(self:SpellName(335293), chainLinkCount)) -- Chain Link
	self:Bar(335470, 29.1, CL.count:format(self:SpellName(335470), chainSlamCount)) -- Chain Slam
	if not self:Tank() then
		self:Bar(331209, 52.5, CL.count:format(self:SpellName(331209), hatefullGazeCount)) -- Hateful Gaze
	else
		self:CDBar(331314, 58.5, CL.count:format(self:SpellName(331314), hatefullGazeCount)) -- Destructive Impact
	end
	if self:Mythic() then
		self:CDBar(340817, timers[340817][seismicShiftCount], CL.count:format(L.stomp_shift, seismicShiftCount)) -- Seismic Shift
	else
		self:Bar(332318, timers[332318][destructiveStompCount], CL.count:format(self:SpellName(332318), destructiveStompCount)) -- Destructive Stomp
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:HatefulGazeApplied(args)
	self:StopBar(CL.count:format(args.spellName, hatefullGazeCount))
	self:TargetMessage(args.spellId, "yellow", args.destName, CL.count:format(args.spellName, hatefullGazeCount))
	if self:Me(args.destGUID) then
		self:PlaySound(args.spellId, "warning")
		self:Say(args.spellId)
		self:SayCountdown(args.spellId, 6)
	end
	if not self:Tank() then
		self:CDBar(331314, 6, CL.count:format(self:SpellName(331314), hatefullGazeCount)) -- Destructive Impact
	else
		self:TargetBar(args.spellId, 6, args.destName, CL.count:format(args.spellName, hatefullGazeCount))
	end
	hatefullGazeCount = hatefullGazeCount + 1
end

function mod:HatefulGazeRemoved(args)
	self:StopBar(CL.count:format(args.spellName, hatefullGazeCount-1), args.destName)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(args.spellId)
	end
end

function mod:DestructiveImpactApplied(args)
	self:Message(args.spellId, "red", CL.on:format(args.spellName, args.destName))
	self:PlaySound(args.spellId, "info")
	self:Bar(args.spellId, 12)
	self:CastBar("custom_off_boulder_impact", 3.5, 341102, 341102) -- Fractured Boulder
end

function mod:DestructiveImpactRemoved(args)
	chainLinksApplied = 0
	self:Bar(331209, 52.5, CL.count:format(self:SpellName(331209), hatefullGazeCount)) -- Hateful Gaze
end

do
	local playerList = mod:NewTargetList()
	function mod:ChainThemApplied(args)
		chainLinksApplied = chainLinksApplied + 1
		if self:Me(args.destGUID) then
			local partner = args.sourceName
			self:Message(335293, "blue", CL.link:format(self:ColorName(partner)))
			self:PlaySound(335293, "warning")
		end
		if chainLinksApplied == 1 then
			self:StopBar(CL.count:format(CL.count:format(self:SpellName(335293), chainLinkCount)))
			if not self:Mythic() then -- Everyone is chained on Mythic
				self:Message(335293, "yellow", CL.count:format(self:SpellName(335293), chainLinkCount))
			end
			chainLinkCount = chainLinkCount + 1
			self:CDBar(335293, 69, CL.count:format(self:SpellName(335293), chainLinkCount))
		end
	end
end

function mod:DestructiveStomp(args)
	self:StopBar(CL.count:format(args.spellName, destructiveStompCount))
	self:Message(args.spellId, "orange", CL.count:format(args.spellName, destructiveStompCount))
	self:PlaySound(args.spellId, "long")
	self:CastBar(args.spellId, 4, CL.count:format(args.spellName, destructiveStompCount))
	destructiveStompCount = destructiveStompCount + 1
	if not self:Mythic() then -- Merged with Seismic Shift in Mythic
		self:Bar(args.spellId, timers[args.spellId][destructiveStompCount], CL.count:format(args.spellName, destructiveStompCount))
	end
end

function mod:ColossalRoar(args)
	self:StopBar(CL.count:format(args.spellName, colossalRoarCount))
	self:Message(args.spellId, "yellow", CL.count:format(args.spellName, colossalRoarCount))
	self:PlaySound(args.spellId, "info")
	colossalRoarCount = colossalRoarCount + 1
	self:Bar(args.spellId, timers[args.spellId][colossalRoarCount], CL.count:format(args.spellName, colossalRoarCount))
end

function mod:ChainSlamApplied(args)
	self:StopBar(CL.count:format(args.spellName, chainSlamCount))
	self:TargetMessage(args.spellId, "yellow", args.destName, CL.count:format(args.spellName, chainSlamCount))
	self:PrimaryIcon(args.spellId, args.destName)
	if self:Me(args.destGUID) then
		self:Say(args.spellId)
		self:SayCountdown(args.spellId, 4)
		self:PlaySound(args.spellId, "warning")
	end
	chainSlamCount = chainSlamCount + 1
	self:Bar(args.spellId, 69, CL.count:format(args.spellName, chainSlamCount))
end

function mod:ChainSlamRemoved(args)
	self:PrimaryIcon(args.spellId)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(args.spellId)
	end
end

function mod:GruesomeRageApplied(args)
	self:Message(args.spellId, "yellow")
	self:PlaySound(args.spellId, "alert")
end

do
	local prev = 0
	function mod:GroundDamage(args)
		if self:Me(args.destGUID) then
			local t = args.time
			if t-prev > 2 then
				prev = t
				self:PlaySound(args.spellId, "alarm")
				self:PersonalMessage(args.spellId, "underyou")
			end
		end
	end
end

-- Mythic
do
	local prev = 0
	function mod:SeismicShiftApplied(args)
		local t = args.time
		if t-prev > 2 then
			prev = t
			self:StopBar(CL.count:format(args.spellName, seismicShiftCount))
			self:Message(args.spellId, "yellow", CL.count:format(args.spellName, seismicShiftCount))
			self:PlaySound(args.spellId, "long")
			seismicShiftCount = seismicShiftCount + 1
			if seismicShiftCount == 3 or seismicShiftCount == 6 then -- No stomp with these
				self:CDBar(args.spellId, timers[args.spellId][seismicShiftCount], CL.count:format(args.spellName, seismicShiftCount))
			else
				self:CDBar(args.spellId, timers[args.spellId][seismicShiftCount], CL.count:format(L.stomp_shift, seismicShiftCount))
			end
		end
	end
end
