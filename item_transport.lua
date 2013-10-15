modpath=minetest.get_modpath("pipeworks")

dofile(modpath.."/compat.lua")

--define the functions from https://github.com/minetest/minetest/pull/834 while waiting for the devs to notice it
local function dir_to_facedir(dir, is6d)
	--account for y if requested
	if is6d and math.abs(dir.y) > math.abs(dir.x) and math.abs(dir.y) > math.abs(dir.z) then
		
		--from above
		if dir.y < 0 then
			if math.abs(dir.x) > math.abs(dir.z) then
				if dir.x < 0 then
					return 19
				else
					return 13
				end
			else
				if dir.z < 0 then
					return 10
				else
					return 4
				end
			end
		
		--from below
		else
			if math.abs(dir.x) > math.abs(dir.z) then
				if dir.x < 0 then
					return 15
				else
					return 17
				end
			else
				if dir.z < 0 then
					return 6
				else
					return 8
				end
			end
		end
	
	--otherwise, place horizontally
	elseif math.abs(dir.x) > math.abs(dir.z) then
		if dir.x < 0 then
			return 3
		else
			return 1
		end
	else
		if dir.z < 0 then
			return 2
		else
			return 0
		end
	end
end

local function facedir_to_dir(facedir)
	--a table of possible dirs
	return ({{x=0, y=0, z=1},
					{x=1, y=0, z=0},
					{x=0, y=0, z=-1},
					{x=-1, y=0, z=0},
					{x=0, y=-1, z=0},
					{x=0, y=1, z=0}})
					
					--indexed into by a table of correlating facedirs
					[({[0]=1, 2, 3, 4, 
						5, 2, 6, 4,
						6, 2, 5, 4,
						1, 5, 3, 6,
						1, 6, 3, 5,
						1, 4, 3, 2})
						
						--indexed into by the facedir in question
						[facedir]]
end

--and an extra function for getting the right-facing vector
local function facedir_to_right_dir(facedir)
	
	--find the other directions
	local backdir = facedir_to_dir(facedir)
	local topdir = ({[0]={x=0, y=1, z=0},
									{x=0, y=0, z=1},
									{x=0, y=0, z=-1},
									{x=1, y=0, z=0},
									{x=-1, y=0, z=0},
									{x=0, y=-1, z=0}})[math.floor(facedir/4)]
	
	--return a cross product
		return {x=topdir.y*backdir.z - backdir.y*topdir.z,
						y=topdir.z*backdir.x - backdir.z*topdir.x,
						z=topdir.x*backdir.y - backdir.x*topdir.y}
end

minetest.register_craftitem("pipeworks:filter", {
	description = "Filter",
	stack_max = 99,
})

local fakePlayer = {
    get_player_name = function() return ":pipeworks" end,
    -- any other player functions called by allow_metadata_inventory_take anywhere...
    -- perhaps a custom metaclass that errors specially when fakePlayer.<property> is not found?
}

-- adding two tube functions
-- can_remove(pos,node,stack,dir) returns true if an item can be removed from that stack on that node
-- remove_items(pos,node,stack,dir,count) removes count items and returns them
-- both optional w/ sensible defaults and fallback to normal allow_* function
-- XXX: possibly change insert_object to insert_item

-- sname = the current name to allow for, or nil if it allows anything

function grabAndFire(frominv,frominvname,frompos,fromnode,sname,tube,idef,dir,all)
    for spos,stack in ipairs(frominv:get_list(frominvname)) do
        if ( sname == nil and stack:get_name() ~= "") or stack:get_name()==sname then
            local doRemove = true
            if tube.can_remove then
                doRemove = tube.can_remove(frompos, fromnode, stack, dir)
            elseif idef.allow_metadata_inventory_take then
                doRemove = idef.allow_metadata_inventory_take(frompos,"main",spos, stack, fakePlayer)
            end
            -- stupid lack of continue statements grumble
            if doRemove then
                local item
                local count
                if all then
                    count = stack:get_count()
                else
                    count = 1
                end
                if tube.remove_items then
                    -- it could be the entire stack...
                    item=tube.remove_items(frompos,fromnode,stack,dir,count)
                else
                    item=stack:take_item(count)
                    frominv:set_stack(frominvname,spos,stack)
                    if idef.on_metadata_inventory_take then
                        idef.on_metadata_inventory_take(frompos, "main", spos, item, fakePlayer)
                    end
                end
                item1=tube_item(frompos,item)
                item1:get_luaentity().start_pos = frompos
                item1:setvelocity(dir)
                item1:setacceleration({x=0, y=0, z=0})
                return -- only fire one item, please
            end
        end
    end
end

minetest.register_node("pipeworks:filter", {
	description = "Filter",
	tiles = {"pipeworks_filter_top.png", "pipeworks_filter_top.png", "pipeworks_filter_output.png",
		"pipeworks_filter_input.png", "pipeworks_filter_side.png", "pipeworks_filter_top.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,tubedevice=1,mesecon=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",
				"invsize[8,6.5;]"..
				"list[current_name;main;0,0;8,2;]"..
				"list[current_player;main;0,2.5;8,4;]")
		meta:set_string("infotext", "Filter")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_place_node = function(pos)
		tube_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
		tube_scanforobjects(pos)
	end,
	mesecons={effector={action_on=function(pos,node)
					minetest.registered_nodes[node.name].on_punch(pos,node,nil)
				end}},
	tube={connect_sides={right=1}},
	on_punch = function (pos, node, puncher)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	local dir = facedir_to_right_dir(node.param2)
	local frompos = {x=pos.x - dir.x, y=pos.y - dir.y, z=pos.z - dir.z}
	local fromnode=minetest.get_node(frompos)
    if not fromnode then return end
	local frominv
    local idef = minetest.registered_nodes[fromnode.name]
    -- assert(idef)
    local tube = idef.tube
    if not (tube and tube.input_inventory) then
        return
    end
	local frommeta=minetest.get_meta(frompos)
	local frominvname=tube.input_inventory
	local frominv=frommeta:get_inventory()
	for _,filter in ipairs(inv:get_list("main")) do
		local sname=filter:get_name()
		if sname ~="" then
            -- XXX: that's a lot of parameters
            grabAndFire(frominv,frominvname,frompos,fromnode,sname,tube,idef,dir)
		end
	end
	if inv:is_empty("main") then
        grabAndFire(frominv,frominvname,frompos,fromnode,nil,tube,idef,dir)
	end
end,
})

minetest.register_craftitem("pipeworks:mese_filter", {
	description = "Mese filter",
	stack_max = 99,
})

minetest.register_node("pipeworks:mese_filter", {
	description = "Mese filter",
	tiles = {"pipeworks_mese_filter_top.png", "pipeworks_mese_filter_top.png", "pipeworks_mese_filter_output.png",
		"pipeworks_mese_filter_input.png", "pipeworks_mese_filter_side.png", "pipeworks_mese_filter_top.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,tubedevice=1,mesecon=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",
				"invsize[8,6.5;]"..
				"list[current_name;main;0,0;8,2;]"..
				"list[current_player;main;0,2.5;8,4;]")
		meta:set_string("infotext", "Mese filter")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_place_node = function(pos)
		tube_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
		tube_scanforobjects(pos)
	end,
	mesecons={effector={action_on=function(pos,node)
					minetest.registered_nodes[node.name].on_punch(pos,node,nil)
				end}},
	tube={connect_sides={right=1}},
	on_punch = function (pos, node, puncher)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	local dir = facedir_to_right_dir(node.param2)
	local frompos = {x=pos.x - dir.x, y=pos.y - dir.y, z=pos.z - dir.z}
	local fromnode=minetest.get_node(frompos)
	local frominv
    local idef = minetest.registered_nodes[fromnode.name]
    -- assert(idef)
    local tube = idef.tube
    if not (tube and tube.input_inventory) then
        return
    end
	local frommeta=minetest.get_meta(frompos)
	local frominvname=minetest.registered_nodes[fromnode.name].tube.input_inventory
	local frominv=frommeta:get_inventory()
	for _,filter in ipairs(inv:get_list("main")) do
		local sname=filter:get_name()
		if sname ~="" then
            grabAndFire(frominv,frominvname,frompos,fromnode,sname,tube,idef,dir,true)
		end
	end
	if inv:is_empty("main") then
        grabAndFire(frominv,frominvname,frompos,fromnode,sname,tube,idef,dir,true)
	end
end,
})

function tube_item(pos, item)
	-- Take item in any format
	local stack = ItemStack(item)
	local obj = minetest.add_entity(pos, "pipeworks:tubed_item")
	obj:get_luaentity():set_item(stack:to_string())
	return obj
end

local function roundpos(pos)
	return {x=math.floor(pos.x+0.5),y=math.floor(pos.y+0.5),z=math.floor(pos.z+0.5)}
end

minetest.register_entity("pipeworks:tubed_item", {
	initial_properties = {
		hp_max = 1,
		physical = false,
--		collisionbox = {0,0,0,0,0,0},
		collisionbox = {0.1,0.1,0.1,0.1,0.1,0.1},
		visual = "sprite",
		visual_size = {x=0.5, y=0.5},
		textures = {""},
		spritediv = {x=1, y=1},
		initial_sprite_basepos = {x=0, y=0},
		is_visible = false,
		start_pos={},
		route={}
	},
	
	itemstring = '',
	physical_state = false,

	set_item = function(self, itemstring)
		self.itemstring = itemstring
		local stack = ItemStack(itemstring)
		local itemtable = stack:to_table()
		local itemname = nil
		if itemtable then
			itemname = stack:to_table().name
		end
		local item_texture = nil
		local item_type = ""
		if minetest.registered_items[itemname] then
			item_texture = minetest.registered_items[itemname].inventory_image
			item_type = minetest.registered_items[itemname].type
		end
		prop = {
			is_visible = true,
			visual = "sprite",
			textures = {"unknown_item.png"}
		}
		if item_texture and item_texture ~= "" then
			prop.visual = "sprite"
			prop.textures = {item_texture}
			prop.visual_size = {x=0.3, y=0.3}
		else
			prop.visual = "wielditem"
			prop.textures = {itemname}
			prop.visual_size = {x=0.15, y=0.15}
		end
		self.object:set_properties(prop)
	end,

	get_staticdata = function(self)
			if self.start_pos==nil then return end
			local velocity=self.object:getvelocity()
			--self.object:setvelocity({x=0,y=0,z=0})
			self.object:setpos(self.start_pos)
			return	minetest.serialize({
				itemstring=self.itemstring,
				velocity=velocity,
				start_pos=self.start_pos
				})
	end,

	on_activate = function(self, staticdata)
		if  staticdata=="" or staticdata==nil then return end
		local item = minetest.deserialize(staticdata)
		local stack = ItemStack(item.itemstring)
		local itemtable = stack:to_table()
		local itemname = nil
		if itemtable then
			itemname = stack:to_table().name
		end
		
		if itemname then 
		self.start_pos=item.start_pos
		self.object:setvelocity(item.velocity)
		self.object:setacceleration({x=0, y=0, z=0})
		self.object:setpos(item.start_pos)
		end
		self:set_item(item.itemstring)
	end,

	on_step = function(self, dtime)
	if self.start_pos==nil then
		local pos = self.object:getpos()
		self.start_pos=roundpos(pos)
	end
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	tubelike=meta:get_int("tubelike")
	local stack = ItemStack(self.itemstring)
	local drop_pos=nil
		
	local velocity=self.object:getvelocity()
	
	if velocity==nil then return end
	
	local velocitycopy={x=velocity.x,y=velocity.y,z=velocity.z}
	
	local moved=false
	local speed=math.abs(velocity.x+velocity.y+velocity.z)
	local vel={x=velocity.x/speed,y=velocity.y/speed,z=velocity.z/speed}
	
	if math.abs(vel.x)==1 then
		local next_node=math.abs(pos.x-self.start_pos.x)
		if next_node >= 1 then 
			self.start_pos.x=self.start_pos.x+vel.x
			moved=true
		end
	elseif math.abs(vel.y)==1 then
		local next_node=math.abs(pos.y-self.start_pos.y)
		if next_node >= 1 then 
			self.start_pos.y=self.start_pos.y+vel.y
			moved=true
		end	
	elseif math.abs(vel.z)==1 then
		local next_node=math.abs(pos.z-self.start_pos.z)
		if next_node >= 1 then 
			self.start_pos.z=self.start_pos.z+vel.z
			moved=true
		end
	end
	
	local sposcopy={x=self.start_pos.x,y=self.start_pos.y,z=self.start_pos.z}
	
	node = minetest.get_node(self.start_pos)
	if moved and minetest.get_item_group(node.name,"tubedevice_receiver")==1 then
		if minetest.registered_nodes[node.name].tube and minetest.registered_nodes[node.name].tube.insert_object then
			leftover = minetest.registered_nodes[node.name].tube.insert_object(self.start_pos,node,stack,vel)
		else
			leftover = stack
		end
		--drop_pos=minetest.find_node_near(self.start_pos,1,"air")
		--if drop_pos and not leftover:is_empty() then minetest.item_drop(leftover,"",drop_pos) end
		--self.object:remove()
		if leftover:is_empty() then
			self.object:remove()
			return
		end
		velocity.x=-velocity.x
		velocity.y=-velocity.y
		velocity.z=-velocity.z
		self.object:setvelocity(velocity)
		self:set_item(leftover:to_string())
		return
	end
	
	if moved then
		if go_next (self.start_pos, velocity, stack)==0 then
			drop_pos=minetest.find_node_near({x=self.start_pos.x+velocity.x,y=self.start_pos.y+velocity.y,z=self.start_pos.z+velocity.z}, 1, "air")
			if drop_pos then 
				minetest.item_drop(stack, "", drop_pos)
				self.object:remove()
			end
		end
	end
	
	if velocity.x~=velocitycopy.x or velocity.y~=velocitycopy.y or velocity.z~=velocitycopy.z or 
		self.start_pos.x~=sposcopy.x or self.start_pos.y~=sposcopy.y or self.start_pos.z~=sposcopy.z then
		self.object:setpos(self.start_pos)
		self.object:setvelocity(velocity)
	end

end
})


local function addVect(pos,vect)
	return {x=pos.x+vect.x,y=pos.y+vect.y,z=pos.z+vect.z}
end

adjlist={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=0,y=1,z=0},{x=0,y=-1,z=0},{x=1,y=0,z=0},{x=-1,y=0,z=0}}

function notvel(tbl,vel)
	tbl2={}
	for _,val in ipairs(tbl) do
		if val.x~=-vel.x or val.y~=-vel.y or val.z~=-vel.z then table.insert(tbl2,val) end
	end
	return tbl2
end

function go_next(pos,velocity,stack)
	local chests={}
	local tubes={}
	local cnode=minetest.get_node(pos)
	local cmeta=minetest.get_meta(pos)
	local node
	local meta
	local tubelike
	local tube_receiver
	local len=1
	local n
	local can_go
	local speed=math.abs(velocity.x+velocity.y+velocity.z)
	local vel={x=velocity.x/speed,y=velocity.y/speed,z=velocity.z/speed,speed=speed}
	if speed>=4.1 then
		speed=4
	elseif speed>=1.1 then
		speed=speed-0.1
	else
		speed=1
	end
	vel.speed=speed
	if minetest.registered_nodes[cnode.name] and minetest.registered_nodes[cnode.name].tube and minetest.registered_nodes[cnode.name].tube.can_go then
		can_go=minetest.registered_nodes[cnode.name].tube.can_go(pos,node,vel,stack)
	else
		can_go=notvel(adjlist,vel)
	end
	for _,vect in ipairs(can_go) do
		npos=addVect(pos,vect)
		node=minetest.get_node(npos)
		tube_receiver=minetest.get_item_group(node.name,"tubedevice_receiver")
		meta=minetest.get_meta(npos)
		tubelike=meta:get_int("tubelike")
		if tube_receiver==1 then
			if minetest.registered_nodes[node.name].tube and
				minetest.registered_nodes[node.name].tube.can_insert and
				minetest.registered_nodes[node.name].tube.can_insert(npos,node,stack,vect) then
				local i=1
				repeat
					if chests[i]==nil then break end
					i=i+1
				until false
				chests[i]={}
				chests[i].pos=npos
				chests[i].vect=vect
			end
		elseif tubelike==1 then
			local i=1
			repeat
				if tubes[i]==nil then break end
				i=i+1
			until false
			tubes[i]={}
			tubes[i].pos=npos
			tubes[i].vect=vect
		end
	end
	if chests[1]==nil then--no chests found
		if tubes[1]==nil then
			return 0
		else
			local i=1
			repeat
				if tubes[i]==nil then break end
				i=i+1
			until false
			n=meta:get_int("tubedir")+1
			repeat
				if n>=i then
					n=n-i+1
				else
					break
				end
			until false
			if CYCLIC then
				meta:set_int("tubedir",n)
			end
			velocity.x=tubes[n].vect.x*vel.speed
			velocity.y=tubes[n].vect.y*vel.speed
			velocity.z=tubes[n].vect.z*vel.speed
		end
	else
		local i=1
		repeat
			if chests[i]==nil then break end
			i=i+1
		until false
		n=meta:get_int("tubedir")+1
		repeat
			if n>=i then
				n=n-i+1
			else
				break
			end
		until false
		if CYCLIC then
			meta:set_int("tubedir",n)
		end
		velocity.x=chests[n].vect.x*speed
		velocity.y=chests[n].vect.y*speed
		velocity.z=chests[n].vect.z*speed
	end
	return 1
end
