-- selects a random building and build it
function fai_build(id)
	local rb=math.random(1,7)
	local rann=math.random(1,30)
	local px=player(id,"tilex")
	local py=player(id,"tiley")
	local rx=math.random(-1,1)
	local ry=math.random(-1,1)
	local bx=px+rx
	local by=py+ry

	ai_selectweapon(id,74)
	if rb==1 then
		ai_build(id,5,bx,by) -- Wall 3
	elseif rb==2 then
		ai_build(id,6,bx,by) -- Gate Field
	elseif rb==3 then
		ai_build(id,7,bx,by) -- Dispenser
	elseif rb==4 then
		ai_build(id,8,bx,by) -- Turret
	elseif rb==5 then
		ai_build(id,9,bx,by) -- Supply
	elseif rb==6 then
		if vai_smode[id]==4 then -- only build an entrance at spawn
			ai_build(id,13,bx,by) -- Tele Entrance
		else
			ai_build(id,14,bx,by) -- Tele Exit
		end
	-- elseif rb==7 then
		-- ai_build(id,14,bx,by) -- Tele Exit
	elseif rb==7 then -- plant mines
		if fai_contains(playerweapons(id),77) then -- does the bot have mines? !!BUGBUG bots won't place mines if they don't have a wrench
			ai_selectweapon(id,77) -- select mines
			ai_attack(id)
		end
	end
	if vai_set_debug==1 then
		print("BOT finished building. buildtype: "..rb..", chatrand: "..rann..", @ ("..bx..","..by..")")
	end
	-- finished building
	vai_mode[id]=0
	vai_smode[id]=0
	local weapon=fai_getprimaryweapon(id)
	if weapon~=0 then
		ai_selectweapon(id,weapon)
	else
		ai_selectweapon(id,50)
	end
end

-- builds a specific building
function fai_build2(id, building)
	local px=player(id,"tilex")
	local py=player(id,"tiley")
	local rx=math.random(-1,1)
	local ry=math.random(-1,1)
	local bx=px+rx
	local by=py+ry

	ai_selectweapon(id,74)
	ai_build(id,building,bx,by)

	-- finished building
	vai_mode[id]=0
	vai_smode[id]=0
	local weapon=fai_getprimaryweapon(id)
	if weapon~=0 then
		ai_selectweapon(id,weapon)
	else
		ai_selectweapon(id,50)
	end
	
end