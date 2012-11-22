-- Dead State for all professions
-- Fights downed and respawns at nearby waypoint 

wt_core_state_dead = inheritsFrom(wt_core_state)
wt_core_state_dead.name = "Dead"
wt_core_state_dead.kelement_list = { }
wt_core_state_dead.CurrentTarget = 0
wt_core_state_dead.respawndelay = 0
wt_core_state_dead.resurrectdelay = 0



------------------------------------------------------------------------------
-- Alive again Check
local cd_check_respawn = inheritsFrom(wt_cause)
local ed_respawn = inheritsFrom(wt_effect)

function cd_check_respawn:evaluate()
 
	if ( (wt_core_state_dead.respawndelay ~= 0 and wt_core_state_dead.respawndelay > wt_global_information.Now) or (wt_core_state_dead.resurrectdelay ~= 0 and wt_core_state_dead.resurrectdelay > wt_global_information.Now)) then
		return true
	end
	return false
end

function ed_respawn:execute()
	wt_debug("Waiting for resurrection... ")
	if ( wt_core_state_dead.resurrectdelay ~= 0 and (wt_core_state_dead.resurrectdelay - 2000) < wt_global_information.Now) then
		wt_debug("RESPAWNING... ")
		wt_debug(Player:RespawnAtClosestResShrine())		
		wt_core_state_dead.resurrectdelay = 0
		wt_core_state_dead.respawndelay = (wt_global_information.Now + 3000)
	else if ( wt_core_state_dead.respawndelay ~= 0 and wt_core_state_dead.respawndelay < wt_global_information.Now) then
			wt_core_state_dead.respawndelay = 0
		end
	end
end

------------------------------------------------------------------------------
-- Alive again Check
local cd_check_alive = inheritsFrom(wt_cause)
local ed_alive = inheritsFrom(wt_effect)

function cd_check_alive:evaluate()
 
	if ( Player.alive == true ) then
		return true
	end
	return false
end

function ed_alive:execute()
	wt_core_controller.requestStateChange(wt_core_state_idle)
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Downed Combat Check
local c_downed_combat = inheritsFrom(wt_cause)
local e_downed_combat = inheritsFrom(wt_effect)

function c_downed_combat:evaluate()
	if (Player.healthstate == GW2.HEALTHSTATE.Downed) then 
		return true
	end	
	return false
end

function e_downed_combat:execute()
	wt_debug("e_downed_combat ")
	if ( Player.inCombat) then
		TargetList = (CharacterList("lowesthealth,attackable,incombat,alive,maxdistance=1200"))	
		if ( TableSize(TargetList) > 0 ) then
			targetID , E  = next(TargetList)		
			if (targetID ~=nil) then
				if (Player:GetTarget() ~= targetID) then
					Player:SetTarget(targetID)
				else
					if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_3)) then
						Player:CastSpell(GW2.SKILLBARSLOT.Slot_3,targetID)
					elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_2)) then
						Player:CastSpell(GW2.SKILLBARSLOT.Slot_2,targetID)	
					elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_4)) then
						Player:CastSpell(GW2.SKILLBARSLOT.Slot_4,targetID)	
					elseif (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_1)) then
						Player:CastSpell(GW2.SKILLBARSLOT.Slot_1,targetID)
					end
				end	
			end
		end
	else
		if (not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_4)) then
			Player:CastSpell(GW2.SKILLBARSLOT.Slot_4,targetID)
		end
	end
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Dead Check
local cd_dead_check = inheritsFrom(wt_cause)
local ed_dead = inheritsFrom(wt_effect)

function cd_dead_check:evaluate()
	if (Player.healthstate == GW2.HEALTHSTATE.Defeated) then 
		return true
	end	
	return false
end

function ed_dead:execute()
	wt_debug("RESPAWN AT NEAREST WAYPOINT ")
	if ( wt_core_state_dead.resurrectdelay == 0) then
		wt_core_state_dead.resurrectdelay  = ( wt_global_information.Now + 6000)
	end
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------

function wt_core_state_dead:initialize()
		
		local ke_respawn = wt_kelement:create("Respawn",cd_check_respawn,ed_respawn, 20000 )
		wt_core_state_dead:add(ke_respawn)
		
		local ke_alive = wt_kelement:create("Alive",cd_check_alive,ed_alive, 1000 )
		wt_core_state_dead:add(ke_alive)
		
		local ke_dead = wt_kelement:create("Dead",cd_dead_check,ed_dead, 200 )
		wt_core_state_dead:add(ke_dead)
		
		local ke_downed_combat = wt_kelement:create("DownedCombat",c_downed_combat,e_downed_combat, 150 )
		wt_core_state_dead:add(ke_downed_combat)
		
end

wt_core_state_dead:initialize()
wt_core_state_dead:register()
