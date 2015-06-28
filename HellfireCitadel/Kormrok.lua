
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Kormrok", 1026, 1392)
if not mod then return end
mod:RegisterEnableMob(90435)
mod.engageId = 1787

--------------------------------------------------------------------------------
-- Locals
--

local poundCount = 1
local tankDebuffCount = 1
local phase = 0 -- 0:NONE, 1:EXPLOSIVE, 2:FOUL, 3:SHADOW
local explosiveCount, foulCount, shadowCount = 0, 0, 0
local enrageMod = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then

end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		181307, -- Foul Crush
		{181306, "PROXIMITY", "FLASH", "SAY"}, -- Explosive Burst
		{181305, "TANK_HEALER"}, -- Swat
		181299, -- Grasping Hands
		181296, -- Explosive Runes
		181292, -- Fel Outpouring
		{180244, "PROXIMITY"}, -- Pound
		186882, -- Enrage
		"stages",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "FelOutpouring", 181292, 181293) -- Normal, Empowered - HAS TO BE _SUCCESS FOR MYTHIC MODULE
	self:Log("SPELL_CAST_START", "ExplosiveRunes", 181296, 181297) -- Normal, Empowered - HAS TO BE _START FOR MYTHIC MODULE
	self:Log("SPELL_CAST_START", "GraspingHandsStart", 181299, 181300)
	self:Log("SPELL_CAST_SUCCESS", "GraspingHands", 181299, 181300) -- Normal, Empowered - HAS TO BE _SUCCESS FOR MYTHIC MODULE
	self:Log("SPELL_CAST_START", "Pound", 180244)
	self:Log("SPELL_AURA_REMOVED", "PoundOver", 180244)
	self:Log("SPELL_CAST_SUCCESS", "FoulCrush", 181307)
	self:Log("SPELL_CAST_SUCCESS", "Swat", 181305)
	self:Log("SPELL_CAST_SUCCESS", "ExplosiveBurst", 181306)
	self:Log("SPELL_AURA_REMOVED", "ExplosiveBurstRemoved", 181306)
	self:Log("SPELL_AURA_APPLIED", "ShadowEnergy", 180115, 186879) -- Normal, Enraged
	self:Log("SPELL_AURA_APPLIED", "ExplosiveEnergy", 180116, 186880) -- Normal, Enraged
	self:Log("SPELL_AURA_APPLIED", "FoulEnergy", 180117, 186881) -- Normal, Enraged
	self:Log("SPELL_AURA_APPLIED", "Enrage", 186882)
end

function mod:OnEngage()
	phase = 0
	explosiveCount, foulCount, shadowCount = 0, 0, 0
	poundCount = 1
	tankDebuffCount = 1
	enrageMod = 1
	self:CDBar("stages", 10, 180068) -- Leap
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ShadowEnergy(args)
	self:SendMessage("BigWigs_StopBars", self)
	shadowCount = 4
	phase = 3
	tankDebuffCount = 1

	self:Message("stages", "Neutral", "Info", args.spellName, false)
	self:Bar(181292, 16 * enrageMod, 181293) -- Empowered Fel Outpouring
	self:Bar(181305, 38 * enrageMod) -- Swat
	self:CDBar(180244, 49 * enrageMod) -- Pound
	self:Bar(181296, 63 * enrageMod, explosiveCount > 0 and 181297) -- [Empowered] Explosive Runes
	self:Bar(181299, 85 * enrageMod, foulCount > 0 and 181300)-- Grasping Hands / Dragging Hands
	self:CDBar("stages", 133 * enrageMod, 180068) -- Leap
end

function mod:ExplosiveEnergy(args)
	self:SendMessage("BigWigs_StopBars", self)
	explosiveCount = 4
	phase = 1
	tankDebuffCount = 1

	self:Message("stages", "Neutral", "Info", args.spellName, false)
	self:Bar(181296, 13 * enrageMod, 181297) -- Empowered Explosive Runes
	self:Bar(181306, 25 * enrageMod) -- Explosive Burst
	self:CDBar(180244, 36 * enrageMod) -- Pound
	self:Bar(181299, 53 * enrageMod, foulCount > 0 and 181300) -- Grasping Hands / Dragging Hands
	self:Bar(181292, 74 * enrageMod, shadowCount > 0 and 181293) -- [Empowered] Fel Outpouring
	self:CDBar("stages", 133 * enrageMod, 180068) -- Leap
end

function mod:FoulEnergy(args)
	self:SendMessage("BigWigs_StopBars", self)
	foulCount = 4
	phase = 2
	tankDebuffCount = 1

	self:Message("stages", "Neutral", "Info", args.spellName, false)
	self:Bar(181299, 13 * enrageMod, 181300) -- Dragging Hands
	self:Bar(181307, 25 * enrageMod) -- Foul Crush
	self:CDBar(180244, 36 * enrageMod) -- Pound
	self:Bar(181292, 46 * enrageMod, shadowCount > 0 and 181293) -- [Empowered] Fel Outpouring
	self:Bar(181296, 69 * enrageMod, explosiveCount > 0 and 181297) -- [Empowered] Explosive Runes
	self:CDBar("stages", 133 * enrageMod, 180068) -- Leap
end

function mod:ExplosiveBurst(args)
	self:TargetMessage(args.spellId, args.destName, "Urgent", "Warning", nil, nil, true)
	self:TargetBar(args.spellId, 10, args.destName)
	tankDebuffCount = tankDebuffCount + 1
	if tankDebuffCount < 4 then
		self:Bar(args.spellId, tankDebuffCount == 2 and (38 * enrageMod) or (50 * enrageMod))
	end
	self:PrimaryIcon(args.spellId, args.destName)
	self:Flash(args.spellId)
	if self:Me(args.destGUID) then
		self:Say(args.spellId)
		self:OpenProximity(args.spellId, 40)
	else
		self:OpenProximity(args.spellId, 40, args.destName)
	end
end

function mod:ExplosiveBurstRemoved(args)
	self:PrimaryIcon(args.spellId)
	self:CloseProximity(args.spellId)
end

function mod:FoulCrush(args)
	self:TargetMessage(args.spellId, args.destName, "Urgent", self:Tank() and "Warning")
	tankDebuffCount = tankDebuffCount + 1
	if tankDebuffCount < 4 then
		self:Bar(args.spellId, tankDebuffCount == 2 and (50 * enrageMod) or (38 * enrageMod))
	end
end

function mod:Swat(args)
	self:Message(args.spellId, "Attention", self:Tank() and "Warning", args.spellName)
	tankDebuffCount = tankDebuffCount + 1
	if tankDebuffCount < 4 then
		self:Bar(args.spellId, 38 * enrageMod)
	end
end

function mod:FelOutpouring(args)
	self:Message(181292, "Attention", "Long", args.spellId)
	self:CDBar(181292, 108 * enrageMod, shadowCount > 0 and 181293) -- [Empowered] Fel Outpouring
end

function mod:ExplosiveRunes(args)
	self:Message(181296, "Urgent", "Info", args.spellId)
	self:CDBar(181296, 108 * enrageMod, explosiveCount > 1 and 181297) -- [Empowered] Explosive Runes
end

function mod:GraspingHandsStart(args)
	self:OpenProximity(181299, 4)
end

function mod:GraspingHands(args)
	self:Message(181299, "Important", nil, args.spellId)
	self:CDBar(181299, 108 * enrageMod, foulCount > 0 and 181300) -- Grasping Hands / Dragging Hands
	self:ScheduleTimer("CloseProximity", 4, 181299) -- Hands spawn delayed and you still have time to move
end

function mod:Pound(args)
	self:Message(args.spellId, "Urgent", "Alert", CL.casting:format(args.spellName, poundCount))
	poundCount = poundCount + 1
	self:CDBar(args.spellId, phase == 3 and (54 * enrageMod) or (68 * enrageMod), CL.count:format(args.spellName, poundCount))
	self:OpenProximity(args.spellId, 5) -- 4 + 1 safety
end

function mod:PoundOver(args)
	self:CloseProximity(args.spellId)
end

function mod:Enrage(args)
	enrageMod = 0.84
	self:Message(args.spellId, "Important")
end
