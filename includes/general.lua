
-- Wait
-- id: player id
-- mode: switch to this mode
function fai_wait(id,mode)
	-- check timer
	if vai_timer[id]>0 then
		-- decrease
		vai_timer[id]=vai_timer[id]-1
	else
		-- switch mode
		vai_mode[id]=mode
	end
end

-- Angle Delta
-- a1: angle 1
-- a2: angle 2
function fai_angledelta(a1,a2)
	local d=(a2-a1)%360
	if d<-180 then d=d+360 end
	if d>180 then d=d-360 end
	return d
end

-- Angle to
-- x1|y1: position 1
-- x2|y2: position 2
function fai_angleto(x1,y1,x2,y2)
	return math.deg(math.atan2(x2-x1,y1-y2))
end

-- Checks if table t has element e
-- t: table
-- e: element
function fai_contains(t,e)
	for _, value in pairs(t) do
		if value == e then
			return true
		end
	end
	return false
end

-- Returns the table t index of the given element e
-- t: table
-- e: element
function fai_gettableindex(t,e)
	for i, value in pairs(t) do
		if value == e then
			return i
		end
	end
	return nil
end

-- Clears the given table
-- t: table
function fai_cleartable(t)
	local count = #t
	for i=0, count do t[i]=nil end
end

-- Check if player has item in certain slot
-- id: player id
-- slot: slot
function fai_playerslotitems(id,slot)
	local items=playerweapons(id)
	for i=1,#items do
		if itemtype(items[i],"slot")==slot then
			return true
		end
	end
	return false
end

-- Walk Aim - aim in walking direction
-- id: player
function fai_walkaim(id)
	local x=player(id,"x")
	local y=player(id,"y")
	local angle=math.deg(math.atan2(x-(vai_px[id] or x),(vai_py[id] or y)-y))
	ai_aim(id,x+math.sin(math.rad(angle))*150,y-math.cos(math.rad(angle))*150)
	if vai_px[id]~=x then vai_px[id]=x end
	if vai_py[id]~=y then vai_py[id]=y end
end

-- Are two given players enemies?
-- id1: player 1
-- id2: player 2
function fai_enemies(id1,id2)
	-- Enemies if teams are different
	if player(id1,"team")~=player(id2,"team") then
		if player(id1,"team")>=2 and player(id2,"team")>=2 then
			-- Special case VIP: CTs (team 2) and VIP (team 3) are never enemies!
			return false
		else
			return true
		end
	-- Enemies if game mode is deathmatch
	elseif vai_set_gm==1 then
		return true
	end
	-- Otherwise: No Enemies
	return false
end

-- Get random (living) teammate
-- id: get random mate of this player (player id)
function fai_randommate(id)
	-- Get Team
	local team=player(id,"team")
	if team>2 then
		team=2
	end
	
	-- Get Random from Player Table
	local players=player(0,"team"..team.."living")
	if #players==0 then
		return 0
	end
	for i=1,10 do
		local randid=math.random(1,#players)
		if players[randid]~=id then
			return players[randid]
		end
	end
	
	-- No mate found
	return 0
end

-- Set destination to random adjacent tile
function fai_randomadjacent(id)
	px=player(id,"tilex")
	py=player(id,"tiley")
	
	-- 20 Search attempts
	for i=1,20 do
		-- Get coordinates of random adjacend tile
		x=px+math.random(-1,1)
		y=py+math.random(-1,1)
		
		-- It must not be the tile of the player...
		if (x~=px or y~=py) then
			-- ... and it must be walkable
			if tile(x,y,"walkable") then
				-- If all this is true, set it!
				vai_destx[id]=x
				vai_desty[id]=y
				return
			end
		end
	end
end

-- Set destination to random adjacent tile (entire map version)
function fai_randommaptile(id)
	px=player(id,"tilex")
	py=player(id,"tiley")
	
	-- 40 Search attempts
	for i=1,40 do
		-- Get coordinates of random adjacend tile
		x=math.random(0,map("xsize"))
		y=math.random(0,map("ysize"))
		
		-- It must not be the tile of the player...
		if (x~=px or y~=py) then
			-- ... and it must be walkable
			if tile(x,y,"walkable") then
				-- If all this is true, set it!
				vai_destx[id]=x
				vai_desty[id]=y
				if vai_set_debug==1 then
					print("Random Map Tile returned x: "..x..", y: "..y.."")
				end				
				return
			end
		end
	end
end

-- returns the destination to random adjacent tile
function fai_getrandommaptile(id)
	local x=-1
	local y=-1
	local rx=-1
	local ry=-1
	
	-- 40 Search attempts
	for i=1,40 do
		-- Get coordinates of random adjacend tile
		x=math.random(0,map("xsize"))
		y=math.random(0,map("ysize"))
		
		-- It must not be the tile of the player...
		if (x~=px or y~=py) then
			-- ... and it must be walkable
			if tile(x,y,"walkable") then
				-- If all this is true, set it!
				rx=x
				ry=y
				if vai_set_debug==1 then
					print("fai_getrandommaptile returned x: "..x..", y: "..y.."")
				end	
				return rx,ry
			end
		end
	end
end

-- sets the bot destx and desty to a random tile in a N radius of a specific origin
-- the radius must always be negative
function fai_gettilerandomradius(radius, x, y)
	local radius2=math.abs(radius)
	local x2=0
	local y2=0
	
	-- 20 Search attempts
	for i=1,20 do
		x2=math.random(radius,radius2)
		y2=math.random(radius,radius2)
		
		if tile(x+x2,y+y2,"walkable") then
			return x+x2,y+y2
		end
	end
end

-- given an object type, return if it's solid
function fai_isobjectsolid(obtype)
	if obtype==2 or obtype==6 or obtype==13 or obtype==14 or obtype==30 then
		return false
	else
		return true
	end
end

-- this function returns true if an object is enemy
-- id - player id
-- obteam - object Team
-- obtype - object type
function fai_isobjectenemy(plyteam, obteam, obtype)
	if obtype>=20 and obtype<=23 then
		return false
	end
	
	if obtype==30 then -- NPC
		return true
	end
	
	if obtype==40 then -- Dynamic Image
		return false
	end
	
	if obteam==plyteam then
		return false
	end
	
	-- Special case: VIP
	if obteam==3 and plyteam==2 then
		return false
	end
	
	-- Special case: VIP
	if obteam==2 and plyteam==3 then
		return false
	end
	
	if obteam==0 then -- NEUTRAL Team
		if obtype == 7 or obtype == 9 or obtype == 15 then -- dispenser,supply,super supply
			return false
		elseif obtype == 8 or obtype == 10 or obtype == 11 or obtype == 12 then -- turrets
			return true
		elseif obtype == 1 or obtype >= 3 and obtype <= 5 then -- barricade + walls
			return true
		else
			return false
		end
	end
	
	if plyteam ~= obteam then
		if fai_isobjectsolid(obtype) then
			return true
		else
			return false
		end
	end
end

-- object free line correction
-- only needed for solid objects
-- x1,y1 - player position
-- x2,y2 - object position
function fai_objflcorrection(x1, y1, x2, y2)
	local rx=0
	local ry=0
	
	-- for x
	if x1>x2 then -- right (object position)
		rx=x2+20
	else -- left, x2>x1
		rx=x2-20
	end
	-- for y
	if y1>y2 then -- botton (object position)
		ry=y2+20
		rx=x2
	else -- top, x2>x1
		ry=y2-20
		rx=x2
	end
	
	return rx,ry
end

-- Distance = square root( (x2-x1)^2 + (y2-y1)^2 )
function util_getdistance(x1,y1,x2,y2)
	local x3=0
	local y3=0
	local d=0
	
	x3 = math.pow(x2-x1, 2)
	y3 = math.pow(y2-y1, 2)

	d = math.sqrt(x3+y3)

	return d
end

function fai_findobjtarget(id)
	local ptx=player(id,"tilex")
	local pty=player(id,"tiley")
	local plyteam=player(id,"team")
	local px=player(id,"x")
	local py=player(id,"y")
	local std=512 -- shortest distance
	local dth=0 -- distance helper
	local targetid=0 -- ID of the closest object
	local objectlist=closeobjects(px,py,512)
	
	for _,oid in pairs(objectlist) do
		local ox=object(oid,"tilex")
		local oy=object(oid,"tiley")
		local obtype=object(oid,"type")
		local obteam=object(oid,"team")
		
		-- enemy check
		if fai_isobjectenemy(plyteam,obteam,obtype) then
			dth=util_getdistance(ptx,pty,ox,oy)
			if dth < std then
				std=dth
				targetid=oid
			end
		end
	end
	
	return targetid
end

-- find best position around object
-- player ID, object ID
function fai_findbpab(pid,oid)
	local ptx=player(pid,"tilex")
	local pty=player(pid,"tiley")
	local otx=object(oid,"tilex")
	local oty=object(oid,"tiley")
	local ix=0
	local iy=0
	local maxdist=999999
	local auxdist=0
	local fx=-1
	local fy=-1
	local validpos=true
	
	for i=1,8 do -- tests 8 positions around the object
		
		validpos=true
		if i == 1 then
			ix=-1
			iy=-1
		elseif i == 2 then
			ix=0
			iy=-1
		elseif i == 3 then
			ix=1
			iy=-1
		elseif i == 4 then
			ix=-1
			iy=0
		elseif i == 5 then
			ix=1
			iy=0
		elseif i == 6 then
			ix=-1
			iy=1
		elseif i == 7 then
			ix=0
			iy=1
		elseif i == 8 then
			ix=1
			iy=1
		end
		
		local oid=objectat(otx+ix,oty+iy)
		
		if not tile(otx+ix,oty+iy, "walkable") then -- tile is walkable
			validpos=false
		end
		
		if oid > 0 then
			if fai_isobjectsolid(object(oid,"type")) then
				validpos=false
			end
		end
		

		auxdist = util_getdistance(ptx,pty,otx+ix,oty+iy)	
		if validpos then
			if auxdist < maxdist then
				maxdist = auxdist
				fx=otx+ix
				fy=oty+iy
			end
		end
	end
	
	if fx > -1 then
		return fx,fy
	else
		return -1,-1
	end
end

-- find best position around object (no diagonal)
-- player ID, object ID
function fai_findbpab2(pid,oid)
	if not object(oid, "exists") then
		return -1, -1
	end

	local ptx=player(pid,"tilex")
	local pty=player(pid,"tiley")
	local otx=object(oid,"tilex")
	local oty=object(oid,"tiley")
	local ix=0
	local iy=0
	local maxdist=999999
	local auxdist=0
	local fx=-1
	local fy=-1
	local validpos=true
	
	for i=1,4 do -- tests 8 positions around the object
	
		validpos=true
		if i == 1 then -- top
			ix=0
			iy=-1
		elseif i == 2 then -- bottom
			ix=0
			iy=1
		elseif i == 3 then -- left
			ix=-1
			iy=0
		elseif i == 4 then -- right
			ix=1
			iy=0
		end
		
		local oid=objectat(otx+ix,oty+iy)
		
		if not tile(otx+ix,oty+iy, "walkable") then -- tile is walkable
			validpos=false
		end
		
		if oid > 0 then
			if fai_isobjectsolid(object(oid,"type")) then
				validpos=false
			end
		end
		

		auxdist = util_getdistance(ptx,pty,otx+ix,oty+iy)	
		if validpos then
			if auxdist < maxdist then
				maxdist = auxdist
				fx=otx+ix
				fy=oty+iy
			end
		end
	end
	
	if fx > -1 then
		return fx,fy
	else
		return -1,-1
	end
end

-- find best position around position
function fai_findbpapos(x1,y1,x2,y2)
	local ix=0
	local iy=0
	local maxdist=999999
	local auxdist=0
	local fx=-1
	local fy=-1
	local validpos=true
	
	for i=1,8 do -- tests 8 positions around the object
		
		validpos=true
		if i == 1 then
			ix=-1
			iy=-1
		elseif i == 2 then
			ix=0
			iy=-1
		elseif i == 3 then
			ix=1
			iy=-1
		elseif i == 4 then
			ix=-1
			iy=0
		elseif i == 5 then
			ix=1
			iy=0
		elseif i == 6 then
			ix=-1
			iy=1
		elseif i == 7 then
			ix=0
			iy=1
		elseif i == 8 then
			ix=1
			iy=1
		end
		
		local oid=objectat(x2+ix,y2+iy)
		
		if not tile(x2+ix,y2+iy, "walkable") then -- tile is walkable
			validpos=false
		end
		
		if oid > 0 then
			if fai_isobjectsolid(object(oid,"type")) then
				validpos=false
			end
		end
		

		auxdist = util_getdistance(x1,y1,x2+ix,y2+iy)	
		if validpos then
			if auxdist < maxdist then
				maxdist = auxdist
				fx=x2+ix
				fy=y2+iy
			end
		end
	end
	
	if fx > -1 then
		return fx,fy
	else
		return -1,-1
	end
end

-- find best position around position (no diagonal)
function fai_findbpapos2(x1,y1,x2,y2)
	local ix=0
	local iy=0
	local maxdist=999999
	local auxdist=0
	local fx=-1
	local fy=-1
	local validpos=true
	
	for i=1,4 do -- tests 8 positions around the object
	
		validpos=true
		if i == 1 then -- top
			ix=0
			iy=-1
		elseif i == 2 then -- bottom
			ix=0
			iy=1
		elseif i == 3 then -- left
			ix=-1
			iy=0
		elseif i == 4 then -- right
			ix=1
			iy=0
		end
		
		local oid=objectat(x2+ix,y2+iy)
		
		if not tile(x2+ix,y2+iy, "walkable") then -- tile is walkable
			validpos=false
		end
		
		if oid > 0 then
			if fai_isobjectsolid(object(oid,"type")) then
				validpos=false
			end
		end
		

		auxdist = util_getdistance(x1,y1,x2+ix,y2+iy)	
		if validpos then
			if auxdist < maxdist then
				maxdist = auxdist
				fx=x2+ix
				fy=y2+iy
			end
		end
	end
	
	if fx > -1 then
		return fx,fy
	else
		return -1,-1
	end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end