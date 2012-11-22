-- The Idle State
-- Check for Buffs/Debuffs
-- Check for Full Inventory
-- Check for Goals
-- ...

-- We inherit from wt_core_state, which gives us: function wt_core_state:run(), function wt_core_state:add( kelement ) and function wt_core_state:register()
wt_core_state_idle = inheritsFrom(wt_core_state)
wt_core_state_idle.name = "Idle"
wt_core_state_idle.kelement_list = { }
wt_core_state_idle.selectedMarkerList = { }
wt_core_state_idle.selectedMarkerIndex = 0

------------------------------------------------------------------------------
-- Died Cause & Effect
local c_check_died = inheritsFrom(wt_cause)
local e_died = inheritsFrom(wt_effect)

function c_check_died:evaluate()
	return not Player.alive
end

function e_died:execute()
		-- change state to handle the dead situation
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
		NextIndex , LootTarget = next(c_check_quickloot.EList)
		if ( NextIndex ~= nil ) then
			if ( NextIndex == Player:GetInteractableTarget()) then
				return true;
			end
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
			wt_debug("Idle: QuickLooting")
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
						wt_debug("Idle: QuickLooting..")
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
-- Aggro Cause & Effect
local c_check_aggro = inheritsFrom(wt_cause)
local e_aggro = inheritsFrom(wt_effect)

function c_check_aggro:evaluate()
	if (Player.inCombat) then
		c_check_aggro.TargetList = (CharacterList("attackable,alive,incombat,maxdistance=1200,noCritter,onmesh"))
		if ( TableSize(c_check_aggro.TargetList) > 0 ) then
			nextTarget , E  = next(c_check_aggro.TargetList)
			if (nextTarget ~=nil) then
				return true
			end
		end
	end

	c_check_aggro.TargetList = (CharacterList("los,attackable,alive,maxdistance=500,noCritter,onmesh"))
	if ( TableSize(c_check_aggro.TargetList) > 0 ) then
		return true
	end
	return false
end

function e_aggro:execute()
	if ( TableSize(c_check_aggro.TargetList) > 0 ) then
		nextTarget , E  = next(c_check_aggro.TargetList)
		if (nextTarget ~=nil) then
			wt_debug("Idle: Begin Combat, Possible aggro target found")
			wt_core_state_combat.setTarget(nextTarget)
			wt_core_controller.requestStateChange(wt_core_state_combat)
		end
	end
end


------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- DepositItems Cause & Effect
local c_deposit = inheritsFrom(wt_cause)
local e_deposit = inheritsFrom(wt_effect)

function c_deposit:evaluate()
	if(ItemList.freeSlotCount == 0) then
		if ( wt_global_information.InventoryFull == 0 ) then
			return true
		else
			return false -- already tried to deposit stuff, still have 0 space in inventory -> vendoringcheck will jump in
		end
	else
		wt_global_information.InventoryFull = 0
	end
	return false
end
e_deposit.throttle = 1000
function e_deposit:execute()
	wt_debug("Deposing Collectables..")
	wt_global_information.InventoryFull = 1
	Inventory:DepositCollectables()
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Vendoring Check Cause & Effect
local c_vendorcheck = inheritsFrom(wt_cause)
local e_vendorcheck = inheritsFrom(wt_effect)

function c_vendorcheck:evaluate()
	if(ItemList.freeSlotCount == 0 and wt_global_information.InventoryFull == 1 and wt_global_information.CurrentVendor ~= nil) then
		return true
	end
	return false
end

function e_vendorcheck:execute()
	wt_core_controller.requestStateChange(wt_core_state_vendoring)
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Search for Reviveable Targets Cause & Effect
local c_check_revive = inheritsFrom(wt_cause)
local e_revive = inheritsFrom(wt_effect)

function c_check_revive:evaluate()
	local TID = Player:GetInteractableTarget()
	if ( TID ~= nil) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			if ( T.distance < 600 and T.attitude == GW2.ATTITUDE.Friendly and T.healthstate == GW2.HEALTHSTATE.Defeated and T.pos.onmesh) then
				return true;
			end
		end
	end
	return false;
end

function e_revive:execute()
 	local TID = Player:GetInteractableTarget()
	if ( TID ~= nil) then
		local T = CharacterList:Get(TID)
		if ( T ~= nil ) then
			if ( T.healthstate == GW2.HEALTHSTATE.Defeated and T.attitude == GW2.ATTITUDE.Friendly and T.pos.onmesh) then
				if ( T.distance > 100 ) then
					wt_debug("moving to reviveable target..." ..T.distance)
					Player:MoveTo(T.pos.x, T.pos.y,T.pos.z , 80 )
				elseif( T.distance < 100 ) then
					Player:StopMoving()
					if (Player:GetCurrentlyCastedSpell() == 17) then
						wt_debug("reviving...")
						Player:Interact(TID)
					end
				end
			end
		end
	else
		wt_error("No Target to revive")
	end
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Loot Cause & Effect
local c_check_loot = inheritsFrom(wt_cause)
local e_loot = inheritsFrom(wt_effect)

function c_check_loot:evaluate()
	if ( ItemList.freeSlotCount > 0 ) then
		c_check_loot.EList = CharacterList("nearest,lootable,onmesh,maxdistance=1200")
		if ( TableSize(c_check_loot.EList) > 0 ) then
			return true;
		end
	end
	return false;
end

local e_loot_t_size, e_loot_n_index = 0, nil
function e_loot:execute()
	if ( e_loot_t_size ~= TableSize(c_check_loot.EList) ) then
		e_loot_t_size = TableSize(c_check_loot.EList)
		wt_debug("Idle: loottable size " .. TableSize(c_check_loot.EList))
	end
 	local NextIndex = 0
	local LootTarget = nil
	NextIndex , LootTarget = next(c_check_loot.EList)
	if ( NextIndex ~= nil ) then
		if ( LootTarget.distance > 130 ) then
			if ( e_loot_n_index ~= NextIndex ) then
				e_loot_n_index = NextIndex
				wt_debug("Idle: moving to loot")
			end
			Player:MoveTo(LootTarget.pos.x, LootTarget.pos.y,LootTarget.pos.z , 0 )
		elseif ( LootTarget.distance < 100  and  NextIndex == Player:GetInteractableTarget() ) then
			Player:StopMoving()
			if (Player:GetCurrentlyCastedSpell() == 17) then
				if ( e_loot_n_index ~= NextIndex ) then
					e_loot_n_index = NextIndex
					wt_debug("Idle: looting")
				end
				Player:Interact(NextIndex)
			end
		elseif ( LootTarget.distance < 150 ) then
			if ( e_loot_n_index ~= NextIndex ) then
				e_loot_n_index = NextIndex
				wt_debug("Idle: directly moving to loot")
			end
			Player:MoveToStraight(LootTarget.pos.x, LootTarget.pos.y,LootTarget.pos.z , 0 )
		end
	else
		wt_error("No Target to Loot")
	end
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Rest Cause & Effect
local c_rest = inheritsFrom(wt_cause)
local e_rest = inheritsFrom(wt_effect)

local c_rest_debug, c_rest_heal = true, true
function c_rest:evaluate()
	local HP = Player.health.percent
	if ( HP < wt_global_information.Currentprofession.RestHealthLimit) then
		return true
	end
	if ( c_rest_debug ~= true ) then
		c_rest_debug = not c_rest_debug
	end
	if ( c_rest_heal ~= true ) then
		c_rest_heal = not c_rest_heal
	end
	return false
end

function e_rest:execute()
	if ( c_rest_debug ) then
		c_rest_debug = not c_rest_debug
		wt_debug("Idle: resting...")
	end
	local s6 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_6 )
	if(Player.health.percent < 65 and not Player:IsSpellOnCooldown(GW2.SKILLBARSLOT.Slot_6)) then
		if ( c_rest_heal ) then
			c_rest_heal = not c_rest_heal
			wt_debug("Idle: Using "..tostring( s6.name ).." for resting... "..Player.health.percent.."%")
		end
		Player:CastSpell(GW2.SKILLBARSLOT.Slot_6)
	end
	return
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Gatherbale Cause & Effect
local c_check_gatherable = inheritsFrom(wt_cause)
local e_gather = inheritsFrom(wt_effect)
c_check_gatherable.GatherTargetTime = 0

function c_check_gatherable:evaluate()

	if (c_check_gatherable.GatherTargetID ~= nil and wt_global_information.Now - c_check_gatherable.GatherTargetTime < 2000) then
		return true
	end

	if ( ItemList.freeSlotCount > 0 ) then
		c_check_gatherable.EList = GadgetList("onmesh,shortestpath,gatherable,maxdistance=4000")
		if ( TableSize(c_check_gatherable.EList) > 0 ) then
			local GatherTarget = nil
			local resourceType = nil
			c_check_gatherable.GatherTargetID , GatherTarget = next(c_check_gatherable.EList)
			return true
		else
			c_check_gatherable.GatherTargetID = nil
		end
	end
	return false;
end

function e_gather:execute()
 	local NextIndex = c_check_gatherable.GatherTargetID
	local GatherTarget = GadgetList:Get(c_check_gatherable.GatherTargetID)
	if (GatherTarget ~= nil) then
			wt_debug("found target to gather")
			if ( GatherTarget.distance > 100 ) then
				wt_debug("moving to gatherable..." ..GatherTarget.distance)
				Player:MoveTo(GatherTarget.pos.x, GatherTarget.pos.y,GatherTarget.pos.z ,50 )
			elseif ( GatherTarget.distance <= 100 ) then
				Player:StopMoving()
				if (Player:GetCurrentlyCastedSpell() == 17) then
					wt_debug("gathering...")
					Player:Use(NextIndex)
				end
			end
	else
		c_check_gatherable.GatherTargetID = nil
		wt_error("No Target to gather")
	end
end


------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Search for Targets Cause & Effect
local c_check_target = inheritsFrom(wt_cause)
local e_targetsearch = inheritsFrom(wt_effect)

function c_check_target:evaluate()
	local TargetID = Player:GetTarget()
	local Target = nil
	if ( TargetID ~= 0 ) then
		Target = CharacterList:Get(TargetID)
	end
	if (Target == nil or not Target.alive) then
		c_check_target.TargetList = (CharacterList("shortestpath,onmesh,noCritter,attackable,alive,maxdistance=2000,maxlevel="..(Player.level + wt_global_information.AttackEnemiesLevelMaxRangeAbovePlayerLevel)))
		return TableSize(c_check_target.TargetList) > 0
	end
	return false
end

function e_targetsearch:execute()
	nextTarget , E  = next(c_check_target.TargetList)
	if (nextTarget ~=nil) then
		wt_debug("Idle: Begin Combat, Found target "..nextTarget)
		Player:StopMoving()
		wt_core_state_combat.setTarget(nextTarget)
		wt_core_controller.requestStateChange(wt_core_state_combat)
	end
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Search for NextMarker Cause & Effect
local c_marker = inheritsFrom(wt_cause)
local e_marker = inheritsFrom(wt_effect)

function c_marker:evaluate()
	if (wt_global_information.CurrentMarkerList == nil or MarkersNeedUpdate()) then
		wt_debug("Updating MarkerList")
		wt_global_information.CurrentMarkerList = MarkerList()
		wt_global_information.SelectedMarker = nil
		wt_core_state_idle.selectedMarkerList = nil
	end
	local distance = 0

	if ( wt_global_information.SelectedMarker ~= nil ) then
		distance =  Distance3D(wt_global_information.SelectedMarker.x,wt_global_information.SelectedMarker.y,wt_global_information.SelectedMarker.z,Player.pos.x,Player.pos.y,Player.pos.z)
		if (distance <= 150) then
			wt_global_information.SelectedMarker = nil
		end
	end
	return ( TableSize(wt_global_information.CurrentMarkerList)>0 and (wt_global_information.SelectedMarker == nil or distance>150) )
end

function e_marker:execute()
	UpdateNextMarker()
	if ( wt_global_information.SelectedMarker ~= nil) then
			wt_debug("Walking towards Next Marker")
			Player:MoveTo(wt_global_information.SelectedMarker.x,wt_global_information.SelectedMarker.y,wt_global_information.SelectedMarker.z,150)
	end
end


local c_keepdoinganything = inheritsFrom(wt_cause)
local e_keepdoinganything = inheritsFrom(wt_effect)

function c_keepdoinganything:evaluate()
	return false
	--c_keepdoinganything.TargetList = (CharacterList("nearest,onmesh,attackable,alive"))
	--return TableSize(c_keepdoinganything.TargetList)>0
end

function e_keepdoinganything:execute()
	nextTarget , E  = next(c_keepdoinganything.TargetList)		
	if (nextTarget ~=nil) then
		wt_debug("found last hope target")
		Player:StopMoving()
		wt_core_state_combat.setTarget(nextTarget)
		wt_core_controller.requestStateChange(wt_core_state_combat)
	end	
end 



------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Marker-Navigation Logic
function UpdateNextMarker()
	if ( wt_global_information.SelectedMarker == nil or Distance3D(wt_global_information.SelectedMarker.x,wt_global_information.SelectedMarker.y,wt_global_information.SelectedMarker.z,Player.pos.x,Player.pos.y,Player.pos.z) < 450 ) then
		if (wt_core_state_idle.selectedMarkerList == nil or (#wt_core_state_idle.selectedMarkerList <= wt_core_state_idle.selectedMarkerIndex) or (wt_core_state_idle.selectedMarkerList[wt_core_state_idle.selectedMarkerIndex] ~= nil and Player.level > wt_core_state_idle.selectedMarkerList[wt_core_state_idle.selectedMarkerIndex].maxlevel)) then
			wt_debug("Generating new MarkerList for our Level")
			if (wt_global_information.CurrentMarkerList ~=nil) then
				wt_core_state_idle.selectedMarkerList = { }
				nextMarker,v = next(wt_global_information.CurrentMarkerList)
				while ( nextMarker ~= nil ) do
					if ( v ~= wt_global_information.SelectedMarker and Distance3D(v.x,v.y,v.z,Player.pos.x,Player.pos.y,Player.pos.z) > 250 and (Player.level >= v.minlevel and Player.level <= v.maxlevel)) then
						table.insert(wt_core_state_idle.selectedMarkerList,v)
					end
				   nextMarker,v = next(wt_global_information.CurrentMarkerList,nextMarker)
				end
				wt_core_state_idle.selectedMarkerIndex = 0
			else
				wt_debug("Error, CurrentMarkerList is empty!")
			end
		else
			if ( #wt_core_state_idle.selectedMarkerList > wt_core_state_idle.selectedMarkerIndex ) then
				wt_debug("Selecting next Marker")
				wt_core_state_idle.selectedMarkerIndex = wt_core_state_idle.selectedMarkerIndex + 1
				wt_global_information.SelectedMarker = wt_core_state_idle.selectedMarkerList[wt_core_state_idle.selectedMarkerIndex]
				wt_debug(wt_core_state_idle.selectedMarkerList[wt_core_state_idle.selectedMarkerIndex])
			end
		end
	end
end


local c_deposit = inheritsFrom(wt_cause)
local e_deposit = inheritsFrom(wt_effect)

function c_deposit:evaluate()
	return false -- (Inventory:GetNumberOfFreeInventorySlots() == 0) 
end

function e_deposit:execute()
	Inventory:DepositCollectables()
end 


------------------------------------------------------------------------------
------------------------------------------------------------------------------

function wt_core_state_idle:initialize()

	local ke_died = wt_kelement:create("Died",c_check_died,e_died, wt_effect.priorities.interrupt )
	wt_core_state_idle:add(ke_died)

	local ke_quickloot = wt_kelement:create("QuickLoot",c_check_quickloot,e_quickloot,110)
	wt_core_state_idle:add(ke_quickloot)

	local ke_aggro = wt_kelement:create("AggroCheck",c_check_aggro,e_aggro, 100 )
	wt_core_state_idle:add(ke_aggro)

	local ke_deposit = wt_kelement:create("DepositItems",c_deposit,e_deposit, 90)
	wt_core_state_idle:add(ke_deposit)

	local ke_vendorcheck = wt_kelement:create("VendoringCheck",c_vendorcheck,e_vendorcheck, 88)
	wt_core_state_idle:add(ke_vendorcheck)

	local ke_revive = wt_kelement:create("Revive",c_check_revive,e_revive, 85)
	wt_core_state_idle:add(ke_revive)

	local ke_rest = wt_kelement:create("Rest",c_rest,e_rest,75)
	wt_core_state_idle:add(ke_rest)

	local ke_loot = wt_kelement:create("Loot",c_check_loot,e_loot,50)
	wt_core_state_idle:add(ke_loot)

	local ke_gather = wt_kelement:create("Gather",c_check_gatherable,e_gather, 40)
	wt_core_state_idle:add(ke_gather)

	local ke_targetsearch = wt_kelement:create("Targetsearch",c_check_target,e_targetsearch,30)
	wt_core_state_idle:add(ke_targetsearch)

	local ke_marker= wt_kelement:create("Marker",c_marker,e_marker,20)
	wt_core_state_idle:add(ke_marker)

	--local ke_lasthope= wt_kelement:create("KeepMoving",c_keepdoinganything,e_keepdoinganything,10)
	--wt_core_state_idle:add(ke_lasthope)
	
end

-- setup kelements for the state
wt_core_state_idle:initialize()
-- register the State with the system
wt_core_state_idle:register()
