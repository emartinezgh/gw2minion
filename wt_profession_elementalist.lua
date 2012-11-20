-- This file contains Elementalist specific combat routines

-- load routine only if player is a Elementalist
if ( 6 ~= Player.profession ) then
	return
end
-- The following values have to get set ALWAYS for ALL professions!!
wt_profession_elementalist  =  inheritsFrom( nil )
wt_profession_elementalist.professionID = 6 -- needs to be set
wt_profession_elementalist.professionRoutineName = "Elementalist"
wt_profession_elementalist.professionRoutineVersion = "1.0"
wt_profession_elementalist.RestHealthLimit = 70

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- NeedHeal Check
wt_profession_elementalist.c_heal_action = inheritsFrom(wt_cause)
wt_profession_elementalist.e_heal_action = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_heal_action:evaluate()
	return (Player.health.percent < 50 and not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_6))
end
wt_profession_elementalist.e_heal_action.usesAbility = true

function wt_profession_elementalist.e_heal_action:execute()
	wt_debug("e_heal_action")
	Player:CastSpell(GW2.SKILLBARSLOT.Slot_6)
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Move Closer to Target Check
wt_profession_elementalist.c_MoveCloser = inheritsFrom(wt_cause)
wt_profession_elementalist.e_MoveCloser = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_MoveCloser:evaluate()
	if ( wt_core_state_combat.CurrentTarget ~= 0 ) then
		local T = CharacterList:Get(wt_core_state_combat.CurrentTarget)
		local Distance = T ~= nil and T.distance or 0
		local LOS = T~=nil and T.los or false
		if (Distance >= wt_global_information.AttackRange  or LOS~=true) then
			return true
		else
			if( Player:GetTarget() ~= wt_core_state_combat.CurrentTarget) then
				Player:SetTarget(wt_core_state_combat.CurrentTarget)
			end
		end
	end
	return false;
end

function wt_profession_elementalist.e_MoveCloser:execute()
	wt_debug("e_MoveCloser ")
	local T = CharacterList:Get(wt_core_state_combat.CurrentTarget)
	if ( T ~= nil ) then
		Player:MoveTo(T.pos.x,T.pos.y,T.pos.z,120) -- the last number is the distance to the target where to stop
	end
end


------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Update Weapon Data 
wt_profession_elementalist.c_update_weapons = inheritsFrom(wt_cause)
wt_profession_elementalist.e_update_weapons = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_update_weapons:evaluate()
	wt_profession_elementalist.MHweapon = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.MainHandWeapon)
	wt_profession_elementalist.OHweapon = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.OffHandWeapon)
	return false
end

function wt_profession_elementalist.e_update_weapons:execute()	
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat Attack Staff
wt_profession_elementalist.c_attack_Staff = inheritsFrom(wt_cause)
wt_profession_elementalist.e_attack_Staff = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_attack_Staff:evaluate()
	if (MHweapon ~= nil and OHweapon == nil and MHweapon.weapontype == GW2.WEAPONTYPE.Staff ) then 
	  return wt_core_state_combat.CurrentTarget ~= 0
	end
	return false
end

wt_profession_elementalist.e_attack_Staff.usesAbility = true
function wt_profession_elementalist.e_attack_Staff:execute()
	Player:StopMoving()
	TID = wt_core_state_combat.CurrentTarget
	if ( TID ~= 0 ) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			wt_debug("attacking " .. TID .. " Distance " .. T.distance)
			Player:SetFacing(T.pos.x-Player.pos.x,T.pos.z-Player.pos.z,T.pos.y-Player.pos.y)
			local s1 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_1)
			local s2 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_2)
			local s3 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_3)
			local s4 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_4)
			local s5 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_5)
			if (s1 ~= nil) then
				wt_global_information.AttackRange = s1.maxRange
				if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_5) and s5~=nil and T.distance < s5.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_5,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_4) and s4~=nil and T.distance < s4.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_4,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_3) and s3~=nil and T.distance < s3.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_3,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_2) and s2~=nil and T.distance < s2.maxRange)  then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_2,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_1) and s1~=nil and T.distance < s1.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_1,TID)
				end
			end
		end
	end
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat Dagger
wt_profession_elementalist.c_attack_dagger = inheritsFrom(wt_cause)
wt_profession_elementalist.e_attack_dagger = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_attack_dagger:evaluate()
	if (MHweapon ~= nil and OHweapon == nil and MHweapon.weapontype == GW2.WEAPONTYPE.Dagger ) then 
	  return wt_core_state_combat.CurrentTarget ~= 0
	end
	return false
end

wt_profession_elementalist.e_attack_dagger.usesAbility = true
function wt_profession_elementalist.e_attack_dagger:execute()
	Player:StopMoving()
	TID =wt_core_state_combat.CurrentTarget
	if ( TID ~= 0 ) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			wt_debug("attacking " .. TID .. " Distance " .. T.distance)
			Player:SetFacing(T.pos.x-Player.pos.x,T.pos.z-Player.pos.z,T.pos.y-Player.pos.y)
			local s1 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_1)
			local s2 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_2)
			local s3 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_3)
			if (s1 ~= nil) then
				wt_global_information.AttackRange = s1.maxRange
				if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_3) and s3~=nil and T.distance < s3.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_3,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_2) and s2~=nil and T.distance < s2.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_2,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_1) and s1~=nil and T.distance < s1.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_1,TID)
				end
			end
		end
	end
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat Scepter
wt_profession_elementalist.c_attack_scepter = inheritsFrom(wt_cause)
wt_profession_elementalist.e_attack_scepter = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_attack_scepter:evaluate()
	if (MHweapon ~= nil and OHweapon == nil and MHweapon.weapontype == GW2.WEAPONTYPE.Scepter ) then 
	  return wt_core_state_combat.CurrentTarget ~= 0
	end
	return false
end

wt_profession_elementalist.e_attack_scepter.usesAbility = true
function wt_profession_elementalist.e_attack_scepter:execute()
	Player:StopMoving()
	TID = wt_core_state_combat.CurrentTarget
	if ( TID ~= 0 ) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			wt_debug("attacking " .. TID .. " Distance " .. T.distance)
			Player:SetFacing(T.pos.x-Player.pos.x,T.pos.z-Player.pos.z,T.pos.y-Player.pos.y)
			local s1 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_1)
			local s2 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_2)
			local s3 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_3)
			if (s1 ~= nil) then
				wt_global_information.AttackRange = s1.maxRange
				if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_3) and s3~=nil and (T.distance < s3.maxRange or T.distance < 300)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_3,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_2) and s2~=nil and T.distance < s2.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_2,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_1) and s1~=nil and T.distance < s1.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_1,TID)
				end
			end
		end
	end
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat Attack Dagger Dagger
wt_profession_elementalist.c_attack_daggerdagger = inheritsFrom(wt_cause)
wt_profession_elementalist.e_attack_daggerdagger = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_attack_daggerdagger:evaluate()
	if (MHweapon ~= nil and OHweapon ~= nil and MHweapon.weapontype == GW2.WEAPONTYPE.Dagger and OHweapon.weapontype == GW2.WEAPONTYPE.Dagger ) then 
	  return wt_core_state_combat.CurrentTarget ~= 0
	end
	return false
end

wt_profession_elementalist.e_attack_daggerdagger.usesAbility = true
function wt_profession_elementalist.e_attack_daggerdagger:execute()
	Player:StopMoving()
	TID =wt_core_state_combat.CurrentTarget
	if ( TID ~= 0 ) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			wt_debug("attacking " .. TID .. " Distance " .. T.distance)
			Player:SetFacing(T.pos.x-Player.pos.x,T.pos.z-Player.pos.z,T.pos.y-Player.pos.y)
			local s1 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_1)
			local s2 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_2)
			local s3 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_3)
			local s4 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_4)
			local s5 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_5)
			if (s1 ~= nil) then
				wt_global_information.AttackRange = s1.maxRange
				if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_5) and s5~=nil and T.distance < s5.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_5,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_4) and s4~=nil and (T.distance < s4.maxRange or T.distance < 200)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_4,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_3) and s3~=nil and T.distance < s3.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_3,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_2) and s2~=nil and T.distance < s2.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_2,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_1) and s1~=nil and T.distance < s1.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_1,TID)
				end
			end
		end
	end
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat Attack Dagger Dagger
wt_profession_elementalist.c_attack_daggerfocus = inheritsFrom(wt_cause)
wt_profession_elementalist.e_attack_daggerfocus = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_attack_daggerfocus:evaluate()
	if (MHweapon ~= nil and OHweapon ~= nil and MHweapon.weapontype == GW2.WEAPONTYPE.Dagger and OHweapon.weapontype == GW2.WEAPONTYPE.Focus ) then 
	  return wt_core_state_combat.CurrentTarget ~= 0
	end
	return false
end

wt_profession_elementalist.e_attack_daggerfocus.usesAbility = true
function wt_profession_elementalist.e_attack_daggerfocus:execute()
	Player:StopMoving()
	TID = wt_core_state_combat.CurrentTarget
	if ( TID ~= 0 ) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			wt_debug("attacking " .. TID .. " Distance " .. T.distance)
			Player:SetFacing(T.pos.x-Player.pos.x,T.pos.z-Player.pos.z,T.pos.y-Player.pos.y)
			local s1 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_1)
			local s2 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_2)
			local s3 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_3)
			local s4 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_4)
			local s5 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_5)
			if (s1 ~= nil) then
				wt_global_information.AttackRange = s1.maxRange
				if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_5) and s5~=nil and (T.distance < s5.maxRange or T.distance < 200)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_5,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_4) and s4~=nil and (T.distance < s4.maxRange or T.distance < 200)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_4,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_3) and s3~=nil and T.distance < s3.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_3,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_2) and s2~=nil and T.distance < s2.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_2,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_1) and s1~=nil and T.distance < s1.maxRange) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_1,TID)
				end
			end
		end
	end
end



------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat Default Attack 
wt_profession_elementalist.c_attack_default = inheritsFrom(wt_cause)
wt_profession_elementalist.e_attack_default = inheritsFrom(wt_effect)

function wt_profession_elementalist.c_attack_default:evaluate()
	  return wt_core_state_combat.CurrentTarget ~= 0
end

wt_profession_elementalist.e_attack_default.usesAbility = true
function wt_profession_elementalist.e_attack_default:execute()
	Player:StopMoving()
	TID = wt_core_state_combat.CurrentTarget
	if ( TID ~= 0 ) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			wt_debug("attacking " .. TID .. " Distance " .. T.distance)
			Player:SetFacing(T.pos.x-Player.pos.x,T.pos.z-Player.pos.z,T.pos.y-Player.pos.y)
			local s1 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_1)
			local s2 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_2)
			local s3 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_3)
			local s4 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_4)
			local s5 = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_5)
			if (s1 ~= nil) then
				wt_global_information.AttackRange = s1.maxRange
				if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_5) and s5~=nil and (T.distance < s5.maxRange or s5.maxRange < 100)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_5,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_4) and s4~=nil and (T.distance < s4.maxRange or s4.maxRange < 100)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_4,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_3) and s3~=nil and (T.distance < s3.maxRange or s3.maxRange < 100)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_3,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_2) and s2~=nil and (T.distance < s2.maxRange or s2.maxRange < 100)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_2,TID)
				elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_1) and s1~=nil and (T.distance < s1.maxRange or s1.maxRange < 100)) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_1,TID)
				end
			end
		end
	end
end


-----------------------------------------------------------------------------------
-- Registration and setup of causes and effects to the different states
-----------------------------------------------------------------------------------

-- We need to check if the players current profession is ours to only add our profession specific routines
if ( wt_profession_elementalist.professionID > -1 and wt_profession_elementalist.professionID == Player.profession) then

	wt_debug("Initalizing profession routine for Elementalist")
	-- Default Causes & Effects that are already in the wt_core_state_combat for all classes:
	-- Death Check 				- Priority 10000   --> Can change state to wt_core_state_dead.lua
	-- Combat Over Check 		- Priority 500      --> Can change state to wt_core_state_idle.lua
	
	
	-- Our C & E´s for Elementalist combat:
	local ke_heal_action = wt_kelement:create("heal_action",wt_profession_elementalist.c_heal_action,wt_profession_elementalist.e_heal_action, 100 )
		wt_core_state_combat:add(ke_heal_action)
		
	local ke_MoveClose_action = wt_kelement:create("Move closer",wt_profession_elementalist.c_MoveCloser,wt_profession_elementalist.e_MoveCloser, 75 )
		wt_core_state_combat:add(ke_MoveClose_action)

	local ke_Update_weapons = wt_kelement:create("UpdateWeaponData",wt_profession_elementalist.c_update_weapons,wt_profession_elementalist.e_update_weapons, 55 )
		wt_core_state_combat:add(ke_Update_weapons)
	
	local ke_Attack_Staff = wt_kelement:create("AttackStaff",wt_profession_elementalist.c_attack_Staff,wt_profession_elementalist.e_attack_Staff, 50 )
		wt_core_state_combat:add(ke_Attack_Staff)
		
	local ke_Attack_dagger = wt_kelement:create("AttackDagger",wt_profession_elementalist.c_attack_dagger,wt_profession_elementalist.e_attack_dagger, 50 )
		wt_core_state_combat:add(ke_Attack_dagger)
	
	local ke_Attack_scepter = wt_kelement:create("AttackScepter",wt_profession_elementalist.c_attack_scepter,wt_profession_elementalist.e_attack_scepter, 50 )
		wt_core_state_combat:add(ke_Attack_scepter)	

	local ke_Attack_daggerdagger = wt_kelement:create("AttackDaggerDagger",wt_profession_elementalist.c_attack_daggerdagger,wt_profession_elementalist.e_attack_daggerdagger, 50 )
		wt_core_state_combat:add(ke_Attack_daggerdagger)		

	local ke_Attack_daggerfocus = wt_kelement:create("AttackDaggerFocus",wt_profession_elementalist.c_attack_daggerfocus,wt_profession_elementalist.e_attack_daggerfocus, 50 )
		wt_core_state_combat:add(ke_Attack_daggerfocus)
		
	local ke_Attack_default = wt_kelement:create("Attackdefault",wt_profession_elementalist.c_attack_default,wt_profession_elementalist.e_attack_default, 45 )
		wt_core_state_combat:add(ke_Attack_default)
		

	-- We need to set the Currentprofession to our profession , so that other parts of the framework can use it.
	wt_global_information.Currentprofession = wt_profession_elementalist
	wt_global_information.AttackRange = 900
end
-----------------------------------------------------------------------------------














