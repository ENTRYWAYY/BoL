--[[ Pro Diana by ENTRYWAY

	Features:
			-Combo Settings:
				-Full Combo using Q, W, E, R
				-Toggle to use Q
				-Toggle to use W
				-Toggle to use E
				-Toggle to use R
				-Items Toggle 
				-Orbwalking Toggle	
			-Misaya Combo Settings:
				-Full Combo using Q, W, E, R
				-Will R instantly while Q Animation
				-High Risk, high Reward (it is really fast)
				-Toggle to use W
				-Toggle to use E
				-Items Toggle
				-Orbwalking Toggle
			-Harass Settings:
				-Uses Q and W for Harass
				-Toggle to use Q
				-Toggle to use W
				-Orbwalking Toggle
			-Farming Settings:
				-Toggle to farm with Q
			-Jungle Clear Settings:
				-Toggle to use Q in Jungle
				-Toggle to use W in Jungle
				-Toggle to use R in Jungle
				-Orbwalking Toggle
			-Kill Steal Settings:
				-Smart Killsteal with Overkillcheck
					-Checks for enemy health for different possible Killcombos
					-Misaya mechanics Toggle
				-Autoignite Toggle
			-Drawing Settings:
				-Toggle to draw if Enemy is killable(and the combo which will be used)
				-Toggle to draw Spellranges if available
				-Toggle to use Lagfree Circles by barasia, vadash and viseversa
			-Misc Settings:
				-Toggle for Auto Zhonyas / Wooglets
				-Toggle for Auto Mana / Health Pots
				-Sliders for setting up:
					-Min Mana % to Farm / Jungle Clear
					-Min Health % for Auto Zhonyas / Wooglets
					-Min Health % for Auto HP Pots

		Credits & Mentions: 
			-Skeem for helping me out a few times and allowing me to steal a couple of basic functions and his template
			-Sida / Manciuszz for orbwalking stuff
			-barasia, vadash and viseversa for Lagfree Circles
			-KKollective for testing
		
		Changelog:
			1.0 - Initial Release

	]]--

-- Hero Name & VIP Check --
if myHero.charName ~= "Diana" or not VIP_USER then return end

-- require Prodiction by Klokje --
require "Prodiction"

-- OnLoad Function --
function OnLoad()
	Variables()		
	DianaMenu()
	PrintChat("<font color='#FFFFFF'> >> Pro Diana 1.0 by ENTRYWAY loaded! <<</font>")
end

-- OnTick Function --
function OnTick()
	Checks()
	UseConsumables()
	DamageCalcs()

	-- Menu Variables --
	ComboKey = DianaMenu.combo.comboKey
	MisayaKey = DianaMenu.misaya.misayaKey
	HarassKey = DianaMenu.harass.harassKey
	FarmingKey = DianaMenu.farming.farmKey
	JungleKey = DianaMenu.jungle.jungleKey

	if ComboKey then Combo() end
	if MisayaKey then MisayaCombo() end
	if HarassKey then HarassCombo() end
	if JungleKey then JungleClear() end
	if DianaMenu.ks.killsteal then autoKs() end	
	if DianaMenu.ks.AutoIgnite then AutoIgnite() end
	if FarmingKey and not (ComboKey or MisayaKey) then FarmMinions() end
	if DianaMenu.misc.ZWItems and MyHealthLow() and Target and (ZNAREADY or WGTREADY) then CastSpell((wgtSlot or znaSlot)) end
end

-- Variables Function --
function Variables()
	qRange, wRange, eRange, eBuffRange, rRange = 830, 200, 425, 250, 825
	qName, wName, eName, rName = "Crescent Strike", "Pale Cascade", "Moonfall", "Lunar Rush"
	qReady, wReady, eReady, rReady = false, false, false, false
	qSpeed, qDelay, qWidth = 1800, 0.25, 10
	qLanded = false
	Prodict = ProdictManager.GetInstance()
	ProdictQ = Prodict:AddProdictionObject(_Q, qRange, qSpeed, qDelay, qWidth, myHero)
	hpReady, mpReady, fskReady, Recalling = false, false, false, false
	usingHPot, usingMPot = false, false
	TextList = {"Harass", "Q Kill", "Q+W Kill", "Q+R Kill", "Q + Rx2 Kill", "Q+W+R Kill", "Q+W+Rx2 Kill"}
	KillText = {}
	waittxt = {} -- prevents UI lags, all credits to Dekaron
	for i=1, heroManager.iCount do waittxt[i] = i*3 end
	enemyMinions = minionManager(MINION_ENEMY, qRange, player, MINION_SORT_HEALTH_ASC)
	JungleMobs = {}
	JungleFocusMobs = {}
	lastAnimation = nil
	lastSpell = nil
	lastAttack = 0
	lastAttackCD = 0
	lastWindUpTime = 0
	
	-- Stolen from Apple who Stole it from Sida --
	JungleMobNames = { -- List stolen from SAC Revamped. Sorry, Sida!
        ["wolf8.1.1"] = true,
        ["wolf8.1.2"] = true,
        ["YoungLizard7.1.2"] = true,
        ["YoungLizard7.1.3"] = true,
        ["LesserWraith9.1.1"] = true,
        ["LesserWraith9.1.2"] = true,
        ["LesserWraith9.1.4"] = true,
        ["YoungLizard10.1.2"] = true,
        ["YoungLizard10.1.3"] = true,
        ["SmallGolem11.1.1"] = true,
        ["wolf2.1.1"] = true,
        ["wolf2.1.2"] = true,
        ["YoungLizard1.1.2"] = true,
        ["YoungLizard1.1.3"] = true,
        ["LesserWraith3.1.1"] = true,
        ["LesserWraith3.1.2"] = true,
        ["LesserWraith3.1.4"] = true,
        ["YoungLizard4.1.2"] = true,
        ["YoungLizard4.1.3"] = true,
        ["SmallGolem5.1.1"] = true,
}

	FocusJungleNames = {
        ["Dragon6.1.1"] = true,
        ["Worm12.1.1"] = true,
        ["GiantWolf8.1.1"] = true,
        ["AncientGolem7.1.1"] = true,
        ["Wraith9.1.1"] = true,
        ["LizardElder10.1.1"] = true,
        ["Golem11.1.2"] = true,
        ["GiantWolf2.1.1"] = true,
        ["AncientGolem1.1.1"] = true,
        ["Wraith3.1.1"] = true,
        ["LizardElder4.1.1"] = true,
        ["Golem5.1.2"] = true,
		["GreatWraith13.1.1"] = true,
		["GreatWraith14.1.1"] = true,
}
	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil then
			if FocusJungleNames[object.name] then
				table.insert(JungleFocusMobs, object)
			elseif JungleMobNames[object.name] then
				table.insert(JungleMobs, object)
			end
		end
	end
end

-- Menu Function -- 
function DianaMenu()
	DianaMenu = scriptConfig("Pro Diana by ENTRYWAY", "Diana")

	DianaMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
		DianaMenu.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		DianaMenu.combo:addParam("comboQ", "Use "..qName.." (Q) in Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.combo:addParam("comboW", "Use "..wName.." (W) in Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.combo:addParam("comboE", "Use "..eName.." (E) in Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.combo:addParam("comboR", "Use "..rName.." (R) in Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.combo:addParam("comboItems", "Use Items in Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.combo:addParam("comboOrbwalk", "Orbwalk in Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.combo:permaShow("comboKey")

	DianaMenu:addSubMenu("["..myHero.charName.." - Misaya Combo Settings]", "misaya")
		DianaMenu.misaya:addParam("misayaKey", "Misaya Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
		DianaMenu.misaya:addParam("misayaW", "Use "..wName.." (W) in Misaya Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.misaya:addParam("misayaE", "Use "..eName.." (E) in Misaya Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.misaya:addParam("misayaItems", "Use Items in Misaya Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.misaya:addParam("misayaOrbwalk", "Orbwalk in Misaya Combo", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.misaya:permaShow("misayaKey")

	DianaMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
		DianaMenu.harass:addParam("harassKey", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, 88)
		DianaMenu.harass:addParam("harassQ", "Use "..qName.." (Q) in Harass", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.harass:addParam("harassW", "Use "..wName.." (W) in Harass", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.harass:addParam("harassOrbwalk", "Orbwalk in Harass", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.harass:permaShow("harassKey")

	DianaMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
		DianaMenu.farming:addParam("farmKey", "Farming ON/OFF", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
		DianaMenu.farming:addParam("farmQ", "Farm with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.farming:permaShow("farmKey")

	DianaMenu:addSubMenu("["..myHero.charName.." - Jungle Clear Settings]", "jungle")
		DianaMenu.jungle:addParam("jungleKey", "Jungle Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, 67)
		DianaMenu.jungle:addParam("jungleQ", "Clear with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.jungle:addParam("jungleW", "Clear with "..wName.." (W)", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.jungle:addParam("jungleR", "Clear with "..rName.." (R)", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.jungle:addParam("jungleOrbwalk", "Orbwalk while Clearing", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.jungle:permaShow("jungleKey")

	DianaMenu:addSubMenu("["..myHero.charName.." - Kill Steal Settings]", "ks")
		DianaMenu.ks:addParam("killsteal", "Use Smart KillSteal", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.ks:addParam("misayaKs", "Use Misaya Mechanics", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.ks:addParam("AutoIgnite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.ks:permaShow("killsteal")

	DianaMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")
		DianaMenu.drawing:addParam("mDraw", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
		DianaMenu.drawing:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.drawing:addParam("qDraw", "Draw "..qName.." (Q) Range", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.drawing:addParam("wDraw", "Draw "..wName.." (W) Range", SCRIPT_PARAM_ONOFF, false)
		DianaMenu.drawing:addParam("eDraw", "Draw "..eName.." (E) Range", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.drawing:addParam("rDraw", "Draw "..rName.." (R) Range", SCRIPT_PARAM_ONOFF, false)
		DianaMenu.drawing:addParam("LfcDraw", "Use Lagfree Circles (Requires reload!)", SCRIPT_PARAM_ONOFF, true)

	DianaMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
		DianaMenu.misc:addParam("aMP", "Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.misc:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
		DianaMenu.misc:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
		DianaMenu.misc:addParam("farmMana", "Min Mana % for Farming/Jungle Clear", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		DianaMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)

	TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_MAGIC)
	TargetSelector.name = "Diana"
	DianaMenu:addTS(TargetSelector)
end

-- Combo Function --
function Combo()
	if DianaMenu.combo.comboOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if Target ~= nil then
		if DianaMenu.combo.comboItems then UseItems(Target) end
		if DianaMenu.combo.comboQ and qReady and GetDistance(Target) <= qRange then CastQ(Target) end
		if DianaMenu.combo.comboW and wReady and GetDistance(Target) <= wRange then CastSpell(_W) end
		if DianaMenu.combo.comboE and eReady and GetDistance(Target) >= eBuffRange and GetDistance(Target) <= eRange then CastSpell(_E) end
		if DianaMenu.combo.comboR and rReady and qLanded and GetDistance(Target) <= rRange then
			CastSpell(_W)
			CastSpell(_R, Target)
		end
	end
end

-- Misaya Combo -- this needs a rework: take distance to enemy into account for calculating Q delay
function MisayaCombo()
	if DianaMenu.misaya.misayaOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if ValidTarget(Target) then
		if DianaMenu.misaya.misayaItems then UseItems(Target) end
		if qReady and rReady and GetDistance(Target) <= rRange then CastQ(Target) end
		if (lastAnimation == "Spell1") or (lastSpell == "DianaArc") then
			if rReady and GetDistance(Target) <= rRange then
				Packet("S_CAST", {spellId = _R, targetNetworkId = Target.networkID}):send()
			end
		end
		if DianaMenu.misaya.misayaW and wReady and GetDistance(Target) <= wRange then CastSpell(_W) end
		if DianaMenu.misaya.misayaE and eReady and GetDistance(Target) >= eBuffRange and GetDistance(Target) <= eRange then CastSpell(_E) end
	end
end

-- Harass Function --
function HarassCombo()
	if DianaMenu.harass.harassOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if Target ~= nil then
		if DianaMenu.harass.harassQ and qReady and GetDistance(Target) <= qRange then CastQ(Target) end
		if DianaMenu.harass.harassW and wReady and GetDistance(Target) <= wRange then CastSpell(_W) end
	end
end

-- Farming Function --
function FarmMinions()
	if not myManaLow() then 
		for _, minion in pairs(enemyMinions.object) do
			local qMinionDmg = getDmg("Q", minion, myHero)
			if ValidTarget(minion) then
				if DianaMenu.farming.farmQ and qReady and GetDistance(minion) <= qRange and minion.health <= qMinionDmg then
					CastSpell(_Q, minion.x, minion.z)
				end
			end
		end
	end
end

-- Farming Mana Function by Kain--
function myManaLow()
	if myHero.mana < (myHero.maxMana * (DianaMenu.misc.farmMana / 100)) then
		return true
	else
		return false
	end
end

-- Jungle Farming --
function JungleClear()
	JungleMob = GetJungleMob()
	if DianaMenu.jungle.jungleOrbwalk then 
		if JungleMob ~= nil then 
			OrbWalking(JungleMob)
		else
			moveToCursor()
		end
	end
	if JungleMob ~= nil and not myManaLow() then
		if DianaMenu.jungle.jungleQ and GetDistance(JungleMob) <= qRange then CastSpell(_Q, JungleMob.x, JungleMob.z) end
		if DianaMenu.jungle.jungleR and GetDistance(JungleMob) <= rRange then DelayAction(function()CastSpell(_R, JungleMob) end, 0.5) end
		if DianaMenu.jungle.jungleW and GetDistance(JungleMob) <= wRange then CastSpell(_W) end
	end
end

-- Get Jungle Mob--
function GetJungleMob()
        for _, Mob in pairs(JungleFocusMobs) do
                if ValidTarget(Mob, qRange) then return Mob end
        end
        for _, Mob in pairs(JungleMobs) do
                if ValidTarget(Mob, qRange) then return Mob end
        end
end

-- Castin Q into Enemies --
function CastQ(enemy)
	if not enemy then
		enemy = Target
	end
	if Target ~= nil then
			if qPos ~= nil then
				CastSpell(_Q, qPos.x, qPos.z)
			end
	end
end

-- Using Items --
function UseItems(enemy)
	if not enemy then
		enemy = Target
	end
	if Target ~= nil then
		if dfgReady and GetDistance(enemy) <= 750 then CastSpell(dfgSlot, enemy) end
		if hxgReady and GetDistance(enemy) <= 600 then CastSpell(hxgSlot, enemy) end
		if bwcReady and GetDistance(enemy) <= 450 then CastSpell(bwcSlot, enemy) end
		if brkReady and GetDistance(enemy) <= 450 then CastSpell(brkSlot, enemy) end
		if tmtReady and GetDistance(enemy) <= 185 then CastSpell(tmtSlot) end
		if hdrReady and GetDistance(enemy) <= 185 then CastSpell(hdrSlot) end
	end
end

-- Killsteal Function -- 
function autoKs()
	if Target ~= nil then
		if DianaMenu.ks.misayaKs then
			if (lastAnimation == "Spell1") or (lastSpell == "DianaArc") then
				if Target.health <= (qDmg + wDmg + rDmg*2) and rReady and GetDistance(Target) <= rRange then
					Packet("S_CAST", {spellId = _R, targetNetworkId = Target.networkID}):send()
				end
			end
			if qReady and Target.health <= qDmg and GetDistance(Target) <= qRange then
				CastQ(Target)
			elseif rReady and Target.health <= rDmg and GetDistance(Target) <= rRange then
				CastSpell(_R, Target)
			elseif qReady and rReady and Target.health <= (qDmg + rDmg) and GetDistance(Target) <= rRange then
				CastQ(Target)
			elseif qReady and wReady and rReady and Target.health <= (qDmg + wDmg + rDmg) and GetDistance(Target) <= rRange then
				CastSpell(_W)
				CastQ(Target)
			elseif qReady and rReady and Target.health <= (qDmg + rDmg*2) and GetDistance(Target) <= rRange then
				CastQ(Target)
				DelayAction(function()CastSpell(_R, Target) end, 0.3)
			elseif qReady and wReady and rReady and Target.health <= (qDmg + wDmg + rDmg*2) and GetDistance(Target) <= rRange then
				CastSpell(_W)
				CastQ(Target)
				DelayAction(function()CastSpell(_R, Target) end, 0.3)
			end
		else
			if qReady and Target.health <= qDmg and GetDistance(Target) <= qRange then
				CastQ(Target)
			elseif rReady and Target.health <= rDmg and GetDistance(Target) <= rRange then
				CastSpell(_R, Target)
			elseif qReady and rReady and Target.health <= (qDmg + rDmg) and GetDistance(Target) <= rRange then
				CastQ(Target)
				if qLanded then
				 	CastSpell(_R, Target)
				 end
			elseif qReady and wReady and rReady and Target.health <= (qDmg + wDmg + rDmg) and GetDistance(Target) <= rRange then
				CastSpell(_W)
				CastQ(Target)
				if qLanded then 
					CastSpell(_R, Target) 
				end
			elseif qReady and rReady and Target.health <= (qDmg + rDmg*2) and GetDistance(Target) <= rRange then
				CastQ(Target)
				if qLanded then 
					CastSpell(_R, Target) 
					DelayAction(function()CastSpell(_R, Target) end, 0.3)
				end
			elseif qReady and wReady and rReady and Target.health <= (qDmg + wDmg + rDmg*2) and GetDistance(Target) <= rRange then
				CastSpell(_W)
				CastQ(Target)	
				if qLanded then 
					CastSpell(_R, Target) 
					DelayAction(function()CastSpell(_R, Target) end, 0.3)
				end
			end
		end
	end
end

-- Auto Ignite --
function AutoIgnite()
	if Target ~= nil then
		if Target.health <= iDmg and GetDistance(Target) <= 600 then
			if iReady then CastSpell(ignite, Target) end
		end
	end
end

-- Health Function for Auto Zhonyas/Wooglets --
function MyHealthLow()
	if myHero.health < (myHero.maxHealth * ( DianaMenu.misc.ZWHealth / 100)) then
		return true
	else
		return false
	end
end

-- Using Consumables --
function UseConsumables()
	if not InFountain() and not Recalling and Target ~= nil then
		if DianaMenu.misc.aHP and myHero.health < (myHero.maxHealth * (DianaMenu.misc.HPHealth / 100))
			and not (usingHPot or usingFlask) and (hpReady or fskReady)	then
				CastSpell((hpSlot or fskSlot)) 
		end
		if DianaMenu.misc.aMP and myHero.mana < (myHero.maxMana * (DianaMenu.misc.farmMana / 100))
			and not (usingMPot or usingFlask) and (mpReady or fskReady) then
				CastSpell((mpSlot or fskSlot))
		end
	end
end

-- Damage Calculations --
function DamageCalcs()
	for i=1, heroManager.iCount do
	local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) then
			dfgDmg, hxgDmg, bwcDmg, iDmg  = 0, 0, 0, 0
			qDmg, wDmg, rDmg = 0, 0, 0
			aDmg = getDmg("AD",enemy,myHero)
			if qReady then qDmg = getDmg("Q", enemy, myHero) end
			if wReady then wDmg = getDmg("W", enemy, myHero) end
			if rReady then rDmg = getDmg("R", enemy, myHero) end
			if dfgReady then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if hxgReady then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if bwcReady then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if iReady then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            extraDmg = dfgDmg + hxgDmg + bwcDmg + onspellDmg + iDmg
            	KillText[i] = 1
          	if enemy.health <= qDmg then
          		KillText[i] = 2
          	elseif enemy.health <= (qDmg + wDmg) and enemy.health > qDmg and wDmg then
          		KillText[i] = 3
          	elseif enemy.health <= (qDmg + rDmg) and enemy.health > qDmg and rDmg then
          		KillText[i] = 4
          	elseif enemy.health <= (qDmg + rDmg*2) and enemy.health > qDmg and rDmg*2 then
          		KillText[i] = 5
          	elseif enemy.health <= (qDmg + wDmg + rDmg) and enemy.health > qDmg and wDmg and rDmg then
          		KillText[i] = 6
          	elseif enemy.health <= (qDmg + wDmg + rDmg*2) and enemy.health > qDmg and wDmg and rDmg*2 then
          		KillText[i] = 7	
           	end	
        end
    end
end

-- Object Handling Functions --
function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name:find("Global_Item_HealthPotion.troy") then
			if GetDistance(obj, myHero) <= 70 then
				usingHPot = true
				usingFlask = true
			end
		end
		if obj.name:find("Global_Item_ManaPotion.troy") then
			if GetDistance(obj, myHero) <= 70 then
				usingFlask = true
				usingMPot = true
			end
		end
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = true
			end
		end
		if FocusJungleNames[obj.name] then
			table.insert(JungleFocusMobs, obj)
		elseif JungleMobNames[obj.name] then
            table.insert(JungleMobs, obj)
		end
	end
end

function OnDeleteObj(obj)
	if obj ~= nil then
			if obj.name:find("Global_Item_HealthPotion.troy") then
			if GetDistance(obj) <= 70 then
				usingHPot = false
				usingFlask = false
			end
		end
		if obj.name:find("Global_Item_ManaPotion.troy") then
			if GetDistance(obj) <= 70 then
				usingMPot = false
				usingFlask = false
			end
		end
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = false
			end
		end
		for i, Mob in pairs(JungleMobs) do
			if obj.name == Mob.name then
				table.remove(JungleMobs, i)
			end
		end
		for i, Mob in pairs(JungleFocusMobs) do
			if obj.name == Mob.name then
				table.remove(JungleFocusMobs, i)
			end
		end
	end
end

-- Buff Handling Functions --
function OnGainBuff(Unit, buff)
	if buff and buff.type ~= nil and Unit.team ~= myHero.team then
		local jugnleMob = GetJungleMob()
		if Unit == (Target or JungleMob) and buff.name == "dianamoonlight" then
			qLanded = true
		end
	end
end

function OnLoseBuff(Unit, buff)
	if buff and buff.type ~= nil and Unit.team ~= myHero.team then
		if buff.name == "dianamoonlight" then
			qLanded = false
		end
	end
end

-- Recalling Functions --
function OnRecall(hero, channelTimeInMs)
	if hero.networkID == player.networkID then
		Recalling = true
	end
end

function OnAbortRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end

function OnFinishRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end

-- Function Ondraw --
function OnDraw()
	-- Ranges --
	if not DianaMenu.drawing.mDraw and not myHero.dead then
		if qReady and DianaMenu.drawing.qDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, ARGB(255,127,0,110))
		end
		if wReady and DianaMenu.drawing.wDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, ARGB(255,95,159,159))
		end
		if eReady and DianaMenu.drawing.eDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, ARGB(255,204,50,50))
		end
		if rReady and DianaMenu.drawing.rDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, rRange, ARGB(255,69,139,0))
		end
	end

	-- Drawing Texts --
	if DianaMenu.drawing.cDraw then
		for i=1, heroManager.iCount do
			local Unit = heroManager:GetHero(i)
			if ValidTarget(Unit) then
				if waittxt[i] == 1 and (KillText[i] ~= nil or 0 or 1) then
					PrintFloatText(Unit, 0, TextList[KillText[i]])
				end
			end
			if waittxt[i] == 1 then
				waittxt[i] = 30
			else
				waittxt[i] = waittxt[i]-1
			end
		end
	end
end

-- Lagfree Circles by barasia, vadash and viseversa
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
		quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
		quality = 2 * math.pi / quality
		radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end

function round(num) 
	if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 75)	
    end
end

--Based on Manciuzz Orbwalker http://pastebin.com/jufCeE0e
function OrbWalking(Target)
	if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
		myHero:Attack(Target)
    elseif heroCanMove() then
        moveToCursor()
    end
end

function TimeToAttack()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function moveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		myHero:MoveTo(moveToPos.x, moveToPos.z)
    end        
end

function OnProcessSpell(object,spell)
	if object == myHero then
		if spell and lastSpell ~= spell.name then lastSpell = spell.name end
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
        end
    end
end

function OnAnimation(unit, animationName)
    if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end

-- Spells and Items Checks --
function Checks()
	-- Target Update --
	TargetSelector:update()
	Target = TargetSelector.target

	-- Ignite Slot --
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ignite = SUMMONER_2
	end

	-- Slots for Items / Pots / Wards --
	rstSlot, ssSlot, swSlot, vwSlot =    GetInventorySlotItem(2045),
									     GetInventorySlotItem(2049),
									     GetInventorySlotItem(2044),
									     GetInventorySlotItem(2043)
	dfgSlot, hxgSlot, bwcSlot, brkSlot = GetInventorySlotItem(3128),
										 GetInventorySlotItem(3146),
										 GetInventorySlotItem(3144),
										 GetInventorySlotItem(3153)
	hpSlot, mpSlot, fskSlot =            GetInventorySlotItem(2003),
							             GetInventorySlotItem(2004),
							             GetInventorySlotItem(2041)
	znaSlot, wgtSlot =                   GetInventorySlotItem(3157),
	                                     GetInventorySlotItem(3090)
	tmtSlot, hdrSlot = 					 GetInventorySlotItem(3077)
										 GetInventorySlotItem(3074)
	
	-- Spells --									 
	qReady = (myHero:CanUseSpell(_Q) == READY)
	wReady = (myHero:CanUseSpell(_W) == READY)
	eReady = (myHero:CanUseSpell(_E) == READY)
	rReady = (myHero:CanUseSpell(_R) == READY)
	iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	
	-- Items --
	dfgReady = (dfgSlot ~= nil and myHero:CanUseSpell(dfgSlot) == READY)
	hxgReady = (hxgSlot ~= nil and myHero:CanUseSpell(hxgSlot) == READY)
	bwcReady = (bwcSlot ~= nil and myHero:CanUseSpell(bwcSlot) == READY)
	brkReady = (brkSlot ~= nil and myHero:CanUseSpell(brkSlot) == READY)
	znaReady = (znaSlot ~= nil and myHero:CanUseSpell(znaSlot) == READY)
	wgtReady = (wgtSlot ~= nil and myHero:CanUseSpell(wgtSlot) == READY)
	tmtReady = (tmtSlot ~= nil and myHero:CanUseSpell(tmtSlot) == READY)
	hdrReady = (hdrSlot ~= nil and myHero:CanUseSpell(hdrSlot) == READY)
	
	-- Pots --
	hpReady = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
	mpReady = (mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
	fskReady = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)

	-- Updates Minions --
	enemyMinions:update()

	if ValidTarget(Target) then
		qPos = ProdictQ:GetPrediction(Target)
	end

	-- Lagfree Circles --
	if DianaMenu.drawing.LfcDraw then
		_G.DrawCircle = DrawCircle2
	end
end	
