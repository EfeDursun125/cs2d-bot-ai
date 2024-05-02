--------------------------------------------------
-- CS2D Standard Bot AI                         --
-- V1: 01.08.2010 - www.UnrealSoftware.de       --
-- Last Update: 26.04.2017                      --
--                                              --
-- Used prefixes in this script                 --
-- ai_ = AI function (AI API, invoked by CS2D)  --
-- vai_ = AI variable                           --
-- gai_ = AI global shared variable				--
-- fai_ = AI helper function     				--
--        										--
--                                              --
--------------------------------------------------

-- Includes
dofile("bots/includes/settings.lua")	-- track settings
dofile("bots/includes/general.lua")		-- general helper functions
dofile("bots/includes/buy.lua")			-- buying
dofile("bots/includes/decide.lua")		-- decision making process
dofile("bots/includes/engage.lua")		-- engage/attack/battle (find target and attack)
dofile("bots/includes/fight.lua")		-- fight (attack if target is set)
dofile("bots/includes/fight_object.lua")	-- fight (attack if target is set)
dofile("bots/includes/follow.lua")		-- follow another player
dofile("bots/includes/collect.lua")		-- collect good nearby items
dofile("bots/includes/radio.lua")		-- radio message handling
dofile("bots/includes/bomb.lua")		-- bomb planting and defusing
dofile("bots/includes/hostages.lua")	-- rescue hostages
dofile("bots/includes/buildwhere.lua")  -- decides where the bot will build
dofile("bots/includes/build.lua")  		-- decides what the bot will build
dofile("bots/includes/entityscan.lua")  -- scans and interacts with nearby entities
dofile("bots/includes/objectscan.lua")  -- scans and interacts with nearby objects Note: This is for interacting with objects, not attacking then
dofile("bots/includes/chat.lua")  		-- chat message handling
dofile("bots/includes/hookers.lua")  	-- hook handling
dofile("bots/includes/config.lua")  	-- config handling

-- Setting Cache
vai_set_gm=0							-- Game Mode Setting (equals "sv_gamemode", Cache)
vai_set_botskill=0						-- Bot Skill Setting (equals "bot_skill", Cache) -- 0: very low, 1: low, 2: normal, 3: advanced, 4: professional
vai_set_botweapons=0					-- Bot Weapons Setting (equals "bot_weapons", Cache)
vai_set_debug=0							-- Debug Setting (equals "debugai", Cache)
vai_set_disphealth=-1					-- health from dispenser
vai_config_read=false					-- Did we read the config file for this map?
fai_update_settings()

-- Global Variables
gai_tuitems = {} 						-- unreachable items T
gai_ctuitems = {} 						-- unreachable items CT
gai_configdata = {}						-- data from config file

-- Per Player Variables
vai_mode={}; vai_smode={}				-- current mode (state) and sub-mode (sub-state / parameter)
vai_cache={}							-- cache helper
vai_timer={}							-- timer
vai_destx={}; vai_desty={}				-- destination x|y
vai_aimx={}; vai_aimy={}				-- aim at x|y
vai_px={}; vai_py={}					-- previous x|y
vai_objx={}; vai_objy={}				-- target obj x|y
vai_target={}							-- target
vai_targetobj={}						-- target (Object)
vai_reaim={}; vai_rescan={}				-- re-aim / re-scan (line of fire checks)
vai_itemscan={}							-- item scan countdown (for collecting items)
vai_entityscan={}						-- entity scan countdown (for interacting with entities)
vai_objectscan={}						-- object scan countdown (for interacting with objects)
vai_buyingdone={}						-- buying done?
vai_radioanswer={}						-- radio answer?
vai_radioanswert={}						-- radio answer timer
for i=1,32 do
	vai_mode[i]=-1; vai_smode[i]=0
	vai_cache[i]=0
	vai_timer[i]=0
	vai_destx[i]=0; vai_desty[i]=0
	vai_aimx[i]=0; vai_aimy[i]=0
	vai_px[i]=0; vai_px[i]=0
	vai_objx[i]=0; vai_objy[i]=0
	vai_target[i]=0
	vai_targetobj[i]=0
	vai_reaim[i]=0; vai_rescan[i]=0
	vai_itemscan[i]=0
	vai_entityscan[i]=0
	vai_objectscan[i]=0
	vai_buyingdone[i]=0
	vai_radioanswer[i]=0; vai_radioanswert[i]=0
end

-- "ai_onspawn" - AI On Spawn Function
-- This function is called by CS2D automatically after each spawn of a bot
-- Parameter: id = player ID of the bot
function ai_onspawn(id)
	-- reload settings
	fai_update_settings()
	if not vai_config_read then
		fai_read_config()
	end
	
	-- reset variables for the spawned bot
	vai_mode[id]=-1; vai_smode[id]=0
	vai_cache[id]=0
	vai_timer[id]=math.random(1,10)
	vai_destx[id]=0; vai_desty[id]=0
	vai_aimx[id]=player(id,"x")-50+math.random(0,100)
	vai_aimy[id]=player(id,"y")-50+math.random(0,100)
	vai_px[id]=player(id,"x")
	vai_py[id]=player(id,"y")
	vai_objx[id]=0; vai_objy[id]=0
	vai_target[id]=0
	vai_targetobj[id]=0
	vai_reaim[id]=0; vai_rescan[id]=0
	vai_itemscan[id]=1000
	vai_entityscan[id]=600
	vai_objectscan[id]=400
	vai_buyingdone[id]=0
	vai_radioanswer[id]=0; vai_radioanswert[id]=0;
end

-- "ai_update_living" - AI Update Living Function
-- This function is called by CS2D automatically for each *LIVING* bot each frame
-- Parameter: id = player ID of the bot
function ai_update_living(id)
	-- bot might get kicked or killed for teamkills etc - check if it is still in-game
	if not player(id,"exists") then
		return
	elseif player(id,"team")<=0 or player(id,"health")<=0 then
		return
	end

	-- Engage / Aim
	-- scan surroundings for close enemies and attack them if possible
	fai_engage(id)

	-- Scan surroundings for entities of interest
	fai_scanforentity(id)
	fai_scanforobject(id)
	
	-- Send radio answer when radio answer timer expires
	if vai_radioanswert[id]>0 then
		-- decrease timer
		vai_radioanswert[id]=vai_radioanswert[id]-1
		if vai_radioanswert[id]<=0 then
			-- send answer and reset timer
			ai_radio(id,vai_radioanswer[id])
			vai_radioanswer[id]=0; vai_radioanswert[id]=0
		end
	end
		
	-- Collect nearby items
	fai_collect(id)
	
	-- Set AI Debug Output (only visible if CS2D setting "debugai" is set to 1)
	if vai_set_debug then
		ai_debug(id,"m:"..vai_mode[id]..", sm:"..vai_smode[id].." ta:"..vai_target[id].." ti:"..vai_timer[id]..", es:"..vai_entityscan[id]..", os: "..vai_objectscan[id])
	end

	-- The AI is basically a state machine
	-- vai_mode contains the current state, vai_smode contains a sub mode or parameter for the state
	
	if vai_mode[id]==0 then
		-- ############################################################ 0: IDLE -> decide what to do next
		if vai_set_debug == 1 then
			print("BOT "..id.." is IDLE")
		end
		vai_timer[id]=0; vai_smode[id]=0
		vai_cache[id]=0
		fai_decide(id)
		
	elseif vai_mode[id]==1 then
		-- ############################################################ 1: CAMP -> do nothing (wait)
		fai_wait(id,0)
		
	elseif vai_mode[id]==2 then
		-- ############################################################ 2: GOTO -> go to destination
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result==1 then
			vai_mode[id]=0
		elseif result==0 then
			vai_mode[id]=0
		else
			fai_walkaim(id)
		end
		
	elseif vai_mode[id]==3 then
		-- ############################################################ 3: ROAM -> randomly run around
		if ai_move(id,vai_smode[id])==0 then
			-- Bot failed to walk (way blocked) -> turn
			if (id%2)==0 then
				vai_smode[id]=vai_smode[id]+45
			else
				vai_smode[id]=vai_smode[id]-45
			end
			vai_timer[id]=math.random(150,250)
		end
		fai_walkaim(id)
		fai_wait(id,0)

	elseif vai_mode[id]==4 then
		-- ############################################################ 4: FIGHT -> fight
		fai_fight(id)
	
	elseif vai_mode[id]==30 then
		-- ############################################################ 30: FOUND OBJECT -> the bot found an object, decide what to do.
		fai_enganeobject(id)

	elseif vai_mode[id]==32 then
		-- ############################################################ 32: RANGED OBJECT -> do a ranged attack on an object
		fai_rangedobject(id)
	
	elseif vai_mode[id]==31 then
		-- ############################################################ 31: MELEE OBJECT -> do a melee attack on an object
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result==1 then
			fai_meleeobject(id)
		elseif result==0 then
			vai_mode[id]=0
		else
			fai_walkaim(id)
		end

	elseif vai_mode[id]==5 then
		-- ############################################################ 5: HUNT -> hunt another player
		if player(vai_smode[id],"exists") then
			if player(vai_smode[id],"health")>0 then
				if ai_goto(id,player(vai_smode[id],"tilex"),player(vai_smode[id],"tiley"))~=2 then
					vai_mode[id]=0
				end
				return
			end
		end
		-- End Hunt
		vai_mode[id]=0
		
	elseif vai_mode[id]==6 then
		-- ############################################################ 6: COLLECT -> collect item
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result == 1 then
			vai_mode[id]=0
			vai_itemscan[id]=140
		elseif result == 0 then -- path failed
			vai_mode[id]=0
			vai_itemscan[id]=400
			fai_itempathfailed(id,vai_cache[id])
		else
			fai_walkaim(id)
		end
		
	elseif vai_mode[id]==7 then
		-- ############################################################ 7: FOLLOW -> follow another player
		fai_follow(id)
		
	elseif vai_mode[id]==8 then
		-- ############################################################ 8: FLASHED -> run around randomly because flashed
		if ai_goto(id,vai_destx[id],vai_desty[id])~=2 then
			fai_randomadjacent(id)
		end
		-- End Flash
		if player(id,"ai_flash")==0 then
			vai_mode[id]=0
		end
		
	elseif vai_mode[id]==9 then
		-- ############################################################ 9: GOTO SPECIAL -> go to destination (special)
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result==1 then
			if vai_smode[id] == 0  then -- camp/defend request
				vai_mode[id]=1
				vai_timer[id]=math.random(200,800)				
			elseif vai_smode[id] == 1 then -- upgrade help request
				vai_mode[id]=1
				vai_timer[id]=math.random(50,100)
				vai_objectscan[id]=math.random(25,50)
			elseif vai_smode[id] == 2 then -- use button/destroy breakable
				vai_mode[id]=1
				vai_timer[id]=math.random(50,100)
				vai_entityscan[id]=math.random(25,50)
			elseif vai_smode[id] == 3 then -- collect/pick up items
				vai_mode[id]=1
				vai_timer[id]=math.random(50,100)
				vai_itemscan[id]=math.random(25,50)
			elseif vai_smode[id] == 10 then -- go to bomb site
				vai_destx[id],vai_desty[id]=randomentity(5) -- info_bombspot
				if player(id,"bomb") then
					vai_mode[id]=51; vai_smode[id]=0; vai_timer[id]=0
				else
					vai_mode[id]=2; vai_smode[id]=0; vai_timer[id]=0
				end
			else
				vai_mode[id]=0
			end
		elseif result==0 then
			vai_mode[id]=0
		else
			fai_walkaim(id)
		end
		
	elseif vai_mode[id]==11	then
		-- ############################################################ 11: GO TO BREAKABLE -> go to an Env_Breakable
		if ai_goto(id,vai_destx[id],vai_desty[id])~=2 then
			vai_mode[id]=12
		else
			fai_walkaim(id)
		end
	
	elseif vai_mode[id]==12	then
		-- ############################################################ 12: ATTACK BREAKABLE -> attack an Env_Breakable
		fai_destroybreakable(id)
		
	elseif vai_mode[id]==20 then
		-- ############################################################ 20: INTERACT -> interact with an entity
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result==1 then -- bot arrived to destination
			fai_usentity(id)
		elseif result==0 then -- failed to find path
			vai_entityscan[id]=2500
			vai_mode[id]=0
		else
			fai_walkaim(id)
		end
		
	elseif vai_mode[id]==21 then
		-- ############################################################ 21: INTERACT OBJECT -> interact with an object
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result==1 then -- bot arrived to destination
			if vai_smode[id]==7 then -- dispenser
				fai_usedispenser(id)
			end
		elseif result==0 then -- failed to find path
			vai_objectscan[id]=2000
			vai_mode[id]=0
		else
			fai_walkaim(id)
		end	
		
	elseif vai_mode[id]==22 then
		-- ############################################################ 22: USING DISPENSER -> bot is using the dispenser
		fai_wait(id,0)
		
	elseif vai_mode[id]==23 then
		-- ############################################################ 23: USING TELEPORTER -> bot is using a teleporter
		if ai_goto(id,vai_destx[id],vai_desty[id])~=2 then -- this will only happen if the teleporter doesn't have an exit
			vai_mode[id]=0
			vai_smode[id]=0
			vai_objectscan[id]=900
		else
			fai_walkaim(id)
		end
		fai_checkteleport(id, vai_smode[id])
		
	elseif vai_mode[id]==24 then
		-- ############################################################ 24: UPGRADE OBJECT -> bot is using upgrading an object
		fai_upgradeobject(id,vai_cache[id])
	
	elseif vai_mode[id]==50 then
		-- ############################################################ 50: RESCUE -> rescue hostages
		fai_rescuehostages(id)

	elseif vai_mode[id]==51 then
		-- ############################################################ 51: PLANT -> plant bomb
		fai_plantbomb(id)
		
	elseif vai_mode[id]==52 then
		-- ############################################################ 52: DEFUSE -> defuse bomb
		fai_defuse(id)
		
	elseif vai_mode[id]==60 then
		-- ############################################################ 60: BUILDTARGET -> search for a place to build
		fai_findbuildspot(id)
	elseif vai_mode[id]==61 then
		-- ############################################################ 61: BUILDGOTO -> go to the place to build
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result==1 then -- bot arrived to destination
			vai_mode[id]=62
		elseif result==0 then -- failed to find path
			vai_mode[id]=0
		else
			fai_walkaim(id)
		end
		
	elseif vai_mode[id]==62 then
		-- ############################################################ 62: BUILD -> build something
		fai_build(id)
		
	elseif vai_mode[id]==63 then
		-- ############################################################ 63: BUILD TOLD -> build a specific building
		local result=ai_goto(id,vai_destx[id],vai_desty[id])
		if result==1 then -- bot arrived to destination
			fai_build2(id, vai_smode[id])
		elseif result==0 then -- failed to find path
			vai_mode[id]=0
		else
			fai_walkaim(id)
		end
	
	elseif vai_mode[id]==-1 then
		-- ############################################################ -1: BUY -> buy equipment
		fai_buy(id)
	
	else
		-- ############################################################ INVALID MODE -> select new mode
		-- This state should never be reached under normal circumstances
		if vai_set_debug == 1 then
			print("invalid AI mode: "..vai_mode[id])
		end
		vai_mode[id]=0
	end
		
end

-- "ai_update_dead" - AI Update Dead Function
-- This function is called by CS2D automatically for each *DEAD* bot each second
-- Parameter: id = player ID of the bot
function ai_update_dead(id)
	-- Try to respawn (if not in normal gamemode)
	fai_update_settings()
	if vai_set_gm~=0 then
		ai_respawn(id)
	end
end

-- "ai_hear_radio" - AI Hear Radio
-- This function is called once for each radio message
-- Parameter: source = player ID of the player who sent the radio message
-- Parameter: radio = radio message ID
function ai_hear_radio(source,radio)
	fai_radio(source,radio)
end

-- "ai_hear_chat" - AI Hear Chat
-- This function is called once for each chat message
-- Parameter: source = player ID of the player who sent the radio message
-- Parameter: msg = chat text message
-- Parameter: teamonly = team only chat message (1) or public chat message (0)
function ai_hear_chat(source,msg,teamonly)
	fai_chat(source,msg,teamonly)
end