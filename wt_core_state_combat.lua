-- Combat State for all professions
-- Holds "basic" combat routines, every profession has to add it´s own combat cause&effects to this combatstate

wt_core_state_combat = inheritsFrom(wt_core_state)
wt_core_state_combat.name = "Combat"
wt_core_state_combat.kelement_list = { }
wt_core_state_combat.CurrentTarget = 0

------------------------------------------------------------------------------
-- Death Check
local cc_check_died = inheritsFrom(wt_cause)
local ec_died = inheritsFrom(wt_effect)

function cc_check_died:evaluate()
	if ( Player.alive ~=true ) then
		return true
	end
	return false
end

function ec_died:execute()
	wt_core_controller.requestStateChange(wt_core_state_dead)
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- QuickLoot Cause & Effect (looting just the things that are in range already, this we can do while beeing infight)
local c_check_quickloot = inheritsFrom(wt_cause)
local e_quickloot = inheritsFrom(wt_effect)

function c_check_quickloot:evaluate()
	if ( ItemList.freeSlotCount > 0 ) then
		c_check_quickloot.EList = CharacterList("nearest,lootable,onmesh,maxdistance=120")
		if ( TableSize(c_check_quickloot.EList) > 0 ) then
			return true;
		end
		--stupidcheck since some enemies are not marked as lootable but they are lootable
		local e = Player:GetInteractableTarget()
		if (e ~= nil) then
			etable = CharacterList:Get(e)
			if ( etable ~= nil) then
				if (etable.healthstate == GW2.HEALTHSTATE.Defeated and (etable.attitude == GW2.ATTITUDE.Hostile or etable.attitude == GW2.ATTITUDE.Neutral) and etable.isMonster) then
					return true
				end
			end
		end
	end
	return false;
end

local e_quickloot_n_index = nil
function e_quickloot:execute()
 	local NextIndex = 0
	local LootTarget = nil
	NextIndex , LootTarget = next(c_check_quickloot.EList)
	if ( NextIndex ~= nil and NextIndex == Player:GetInteractableTarget()) then
		if ( e_quickloot_n_index ~= NextIndex ) then
			e_quickloot_n_index = NextIndex
			wt_debug("Combat: QuickLooting")
		end
		Player:Interact(NextIndex)
	else
		local e = Player:GetInteractableTarget()
		if (e ~= nil) then
			etable = CharacterList:Get(e)
			if ( etable ~= nil) then
				if (etable.healthstate == GW2.HEALTHSTATE.Defeated and (etable.attitude == GW2.ATTITUDE.Hostile or etable.attitude == GW2.ATTITUDE.Neutral) and etable.isMonster) then
					if ( e_quickloot_n_index ~= e ) then
						e_quickloot_n_index = e
						wt_debug("Combat: QuickLooting..")
					end
					Player:Interact(e)
					return
				end
			end
		end
	end
	wt_error("No Target to Quick-Loot")
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat over Check
local c_combat_over = inheritsFrom(wt_cause)
local e_combat_over = inheritsFrom(wt_effect)

function c_combat_over:evaluate()
	--local CurrentTarget = Player:GetTarget()
	if ( wt_core_state_combat.CurrentTarget == nil or wt_core_state_combat.CurrentTarget == 0 ) then
		return true
	else
		local T = CharacterList:Get(wt_core_state_combat.CurrentTarget)
		if ( T == nil or not T.alive) then
			return true
		end
	end
	return false
end

function e_combat_over:execute()
	Player:StopMoving()
	Player:ClearTarget()
	wt_debug("Combat finished")
	wt_core_state_combat.CurrentTarget = 0
	wt_core_controller.requestStateChange(wt_core_state_idle)
	return
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Search for a better target Check
local c_better_target_search = inheritsFrom(wt_cause)
local e_better_target_search = inheritsFrom(wt_effect)

function c_better_target_search:evaluate()
	c_better_target_search.TargetList = CharacterList("lowesthealth,noCritter,onmesh,attackable,alive,maxdistance="..wt_global_information.AttackRange..",exclude="..wt_core_state_combat.CurrentTarget)
	return (TableSize(c_better_target_search.TargetList) > 0)
end

function e_better_target_search:execute()
	nextTarget , E  = next(c_better_target_search.TargetList)
	if (nextTarget ~=nil) then
		wt_debug("Combat: Switching to better target "..nextTarget)
		Player:StopMoving()
		wt_core_state_combat.setTarget(nextTarget)
	end
end


------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- gets set by core_state_idle before switching to this combat state
function wt_core_state_combat.setTarget(CurrentTarget)
	if (CurrentTarget ~= nil and CurrentTarget ~= 0) then
		wt_core_state_combat.CurrentTarget = CurrentTarget
	else
		wt_core_state_combat.CurrentTarget = 0
	end
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------

function wt_core_state_combat:initialize()

		local ke_died = wt_kelement:create("Died",cc_check_died,ec_died, wt_effect.priorities.interrupt )
		wt_core_state_combat:add(ke_died)

		local ke_quickloot = wt_kelement:create("QuickLoot",c_check_quickloot,e_quickloot,175)
		wt_core_state_idle:add(ke_quickloot)

		local ke_combat_over = wt_kelement:create("combat_over",c_combat_over,e_combat_over, 150 )
		wt_core_state_combat:add(ke_combat_over)

		local ke_better_target_search = wt_kelement:create("better_target_search",c_better_target_search,e_better_target_search, 125 )
		wt_core_state_combat:add(ke_better_target_search)
end

wt_core_state_combat:initialize()
wt_core_state_combat:register()
