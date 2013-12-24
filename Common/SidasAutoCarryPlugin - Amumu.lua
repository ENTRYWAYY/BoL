--[[
	Sida's AutoCarry Plugin - Amumu the sad Mummy v1.1 by ENTRYWAY
	
	Changelog:
	v1.0 - Initial Release
	v1.1 - Added JungleClear (smart W usage in jungle will be fixed)

	]]--

require "Collision"
require "Prodiction"

if myHero.charName ~= "Amumu" or not VIP_USER then return end

------------------------------------------------------
--					   Variables            		--
------------------------------------------------------

local qRange = 1100
local wRange = 400
local eRange = 350
local rRange = 550
local wUsed = false

local qReady, wReady, eReady, rReady = false, false, false, false

local SkillQ = AutoCarry.Skills:NewSkill(true, _Q, qRange, "Bandage Toss", AutoCarry.SPELL_LINEAR_COL, 0, false, false, 2, 250, 80, true)

local enemyHeroes = GetEnemyHeroes()

------------------------------------------------------
--					 Main Functions					--
------------------------------------------------------

function PluginOnLoad()
	AutoCarry.Crosshair:SetSkillCrosshairRange(qRange)
	Menu()
	PrintChat("<font color='#FFFFFF'> >> Amumu - forever alone v1.0 loaded!<<</font>")
end

function PluginOnTick()
	Checks()
	if ValidTarget(Target) then 
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			castCombo()
		end
	end
	if AutoCarry.MainMenu.LaneClear then
		JungleClear()
	end
	if AutoCarry.PluginMenu.ksR then ksR() end
end

function PluginOnDraw()
	if not myHero.dead then
		if qReady and AutoCarry.PluginMenu.drawQ then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x7CFC00)
		end
		if wReady and AutoCarry.PluginMenu.drawW then
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x00FFFF)
		end
		if eReady and AutoCarry.PluginMenu.drawE then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x00FFFF)
		end
		if rReady and AutoCarry.PluginMenu.drawR then
			DrawCircle(myHero.x, myHero.y, myHero.z, rRange, 0x00FFFF)
		end
	end
end

------------------------------------------------------
--					   Functions					--
------------------------------------------------------

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("useW", "Use W in Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useR", "Use R in Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("eneNum", "Use R when X enemies in range", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	AutoCarry.PluginMenu:addParam("ksR", "Killsteal with R", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Jungle Clear ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("jungleW", "Use W in Jungle", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("jungleE", "Use E in Jungle", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("sep", "----- [ W Options ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("notW", "Don't use W below X% Mana", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Drawing ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("drawQ", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawW", "Draw W range", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("drawE", "Draw E range", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("drawR", "Draw R range", SCRIPT_PARAM_ONOFF, false)
end

function Checks()
	qReady = (myHero:CanUseSpell(_Q) == READY)
	wReady = (myHero:CanUseSpell(_W) == READY)
	eReady = (myHero:CanUseSpell(_E) == READY)
	rReady = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.Crosshair:GetTarget()
end

function castCombo()
	if qReady and ValidTarget(Target) then SkillQ:ForceCast(Target) end
	if eReady and ValidTarget(Target, eRange) then CastSpell(_E) end
	if wReady and AutoCarry.PluginMenu.useW and myHero.mana > (myHero.maxMana*(AutoCarry.PluginMenu.notW*0.01)) then
		if not wUsed and CountEnemyHeroInRange(wRange) >= 1 then
			CastSpell(_W)
		end
		if wUsed and not Target or GetDistance(Target) > wRange + 200 then
			CastSpell(_W)
		end
	end

	if rReady and AutoCarry.PluginMenu.useR then
		if CountEnemyHeroInRange(rRange) >= AutoCarry.PluginMenu.eneNum then
			CastSpell(_R)
		end
	end
end

function JungleClear()
	jungleMob = AutoCarry.Jungle:GetAttackableMonster()
	if jungleMob ~= nil then
		if AutoCarry.PluginMenu.jungleE and GetDistance(jungleMob) <= eRange and eReady then
			CastSpell(_E)
		end
		if AutoCarry.PluginMenu.jungleW and myHero.mana > (myHero.maxMana*(AutoCarry.PluginMenu.notW*0.01)) then
			if not wUsed and GetDistance(jungleMob) <= wRange then
				CastSpell(_W)
			end
			if wUsed and not jungleMob or GetDistance(jungleMob) > wRange then
				CastSpell(_W)
			end
		end
	end
end


function getHitBoxRadius(Target)
	return GetDistance(Target, Target.minBBox)
end

function ksR()
	for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if rReady and ValidTarget(Enemy, rRange) and Enemy.health < getDmg("R", Enemy) then 
			CastSpell(_R)
		end
	end
end

function OnGainBuff(unit, buff)
	if unit.name == myHero.name and buff ~= nil then
		if buff.name == "AuraofDespair" then
			wUsed = true
		end
	end
end

function OnLoseBuff(unit, buff)
	if unit.name == myHero.name and buff ~= nil then
		if buff.name == "AuraofDespair" then
			wUsed = false
		end
	end
end

function PluginOnCreateObj(obj)
	if obj ~= nil then 
		if GetDistance(obj) <= 50 and obj.name == "Despair_buf.troy" then
		 	wUsed = true 
		 end
	end
end
 
function PluginOnDeleteObj(obj)
   	if obj ~= nil then 
		if GetDistance(obj) <= 50 and obj.name == "Despair_buf.troy" then
		 	wUsed = false 
		 end
	end
end
