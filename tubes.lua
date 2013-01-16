-- This file supplies pneumatic tubes and a 'test' device

minetest.register_node("pipeworks:testobject", {
	description = "Pneumatic tube test object",
	tiles = {
		"pipeworks_testobject.png",
	},
	paramtype = "light",
	groups = {snappy=3, tubedevice=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	after_place_node = function(pos)
			tube_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
			tube_scanforobjects(pos)
	end,
})

tubenodes={}

-- tables

minetest.register_alias("pipeworks:tube", "pipeworks:tube_000000")

tube_leftstub = {
	{ -32/64, -9/64, -9/64, 9/64, 9/64, 9/64 },	-- tube segment against -X face
}

tube_rightstub = {
	{ -9/64, -9/64, -9/64,  32/64, 9/64, 9/64 },	-- tube segment against +X face
}

tube_bottomstub = {
	{ -9/64, -32/64, -9/64,   9/64, 9/64, 9/64 },	-- tube segment against -Y face
}


tube_topstub = {
	{ -9/64, -9/64, -9/64,   9/64, 32/64, 9/64 },	-- tube segment against +Y face
}

tube_frontstub = {
	{ -9/64, -9/64, -32/64,   9/64, 9/64, 9/64 },	-- tube segment against -Z face
}

tube_backstub = {
	{ -9/64, -9/64, -9/64,   9/64, 9/64, 32/64 },	-- tube segment against -Z face
} 

tube_selectboxes = {
	{ -32/64,  -10/64,  -10/64,  10/64,  10/64,  10/64 },
	{ -10/64 ,  -10/64,  -10/64, 32/64,  10/64,  10/64 },
	{ -10/64 , -32/64,  -10/64,  10/64,  10/64,  10/64 },
	{ -10/64 ,  -10/64,  -10/64,  10/64, 32/64,  10/64 },
	{ -10/64 ,  -10/64, -32/64,  10/64,  10/64,  10/64 },
	{ -10/64 ,  -10/64,  -10/64,  10/64,  10/64, 32/64 }
}

--  Functions

function tube_addbox(t, b)
	for i in ipairs(b)
		do table.insert(t, b[i])
	end
end

-- now define the nodes!
function register_tube(name,desc,plain_textures,noctr_textures,end_textures,short_texture,inv_texture,special)
for xm = 0, 1 do
for xp = 0, 1 do
for ym = 0, 1 do
for yp = 0, 1 do
for zm = 0, 1 do
for zp = 0, 1 do
	local outboxes = {}
	local outsel = {}
	local outimgs = {}

	if yp==1 then
		tube_addbox(outboxes, tube_topstub)
		table.insert(outsel, tube_selectboxes[4])
		table.insert(outimgs, noctr_textures[4])
	else
		table.insert(outimgs, plain_textures[4])
	end
	if ym==1 then
		tube_addbox(outboxes, tube_bottomstub)
		table.insert(outsel, tube_selectboxes[3])
		table.insert(outimgs, noctr_textures[3])
	else
		table.insert(outimgs, plain_textures[3])
	end
	if xp==1 then
		tube_addbox(outboxes, tube_rightstub)
		table.insert(outsel, tube_selectboxes[2])
		table.insert(outimgs, noctr_textures[2])
	else
		table.insert(outimgs, plain_textures[2])
	end
	if xm==1 then
		tube_addbox(outboxes, tube_leftstub)
		table.insert(outsel, tube_selectboxes[1])
		table.insert(outimgs, noctr_textures[1])
	else
		table.insert(outimgs, plain_textures[1])
	end
	if zp==1 then
		tube_addbox(outboxes, tube_backstub)
		table.insert(outsel, tube_selectboxes[6])
		table.insert(outimgs, noctr_textures[6])
	else
		table.insert(outimgs, plain_textures[6])
	end
	if zm==1 then
		tube_addbox(outboxes, tube_frontstub)
		table.insert(outsel, tube_selectboxes[5])
		table.insert(outimgs, noctr_textures[5])
	else
		table.insert(outimgs, plain_textures[5])
	end

	local jx = xp+xm
	local jy = yp+ym
	local jz = zp+zm

	if (jx+jy+jz) == 1 then
		if xm == 1 then 
			table.remove(outimgs, 3)
			table.insert(outimgs, 3, end_textures[3])
		end
		if xp == 1 then 
			table.remove(outimgs, 4)
			table.insert(outimgs, 4, end_textures[4])
		end
		if ym == 1 then 
			table.remove(outimgs, 1)
			table.insert(outimgs, 1, end_textures[1])
		end
		if xp == 1 then 
			table.remove(outimgs, 2)
			table.insert(outimgs, 2, end_textures[2])
		end
		if zm == 1 then 
			table.remove(outimgs, 5)
			table.insert(outimgs, 5, end_textures[5])
		end
		if zp == 1 then 
			table.remove(outimgs, 6)
			table.insert(outimgs, 6, end_textures[6])
		end
	end

	local tname = xm..xp..ym..yp..zm..zp
	local tgroups = ""

	if tname ~= "000000" then
		tgroups = {snappy=3, tube=1, not_in_creative_inventory=1}
		tubedesc = desc.." ("..tname..")... You hacker, you."
		iimg=nil
		wscale = {x=1,y=1,z=1}
	else
		tgroups = {snappy=3, tube=1}
		tubedesc = desc
		iimg=inv_texture
		outimgs = {
			short_texture,short_texture,
			end_textures[3],end_textures[4],
			short_texture,short_texture
		}
		outboxes = { -24/64, -9/64, -9/64, 24/64, 9/64, 9/64 }
		outsel = { -24/64, -10/64, -10/64, 24/64, 10/64, 10/64 }
		wscale = {x=1,y=1,z=0.01}
	end
	
	table.insert(tubenodes,name.."_"..tname)
	
	nodedef={
		description = tubedesc,
		drawtype = "nodebox",
		tiles = outimgs,
		inventory_image=iimg,
		wield_image=iimg,
		wield_scale=wscale,
		paramtype = "light",
		selection_box = {
	             	type = "fixed",
			fixed = outsel
		},
		node_box = {
			type = "fixed",
			fixed = outboxes
		},
		groups = tgroups,
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		drop = name.."_000000",
		tubelike=1,
		on_construct = function(pos)
			local meta = minetest.env:get_meta(pos)
			meta:set_int("tubelike",1)
			if minetest.registered_nodes[name.."_"..tname].on_construct_ then
				minetest.registered_nodes[name.."_"..tname].on_construct_(pos)
			end
		end,
		after_place_node = function(pos)
			tube_scanforobjects(pos)
			if minetest.registered_nodes[name.."_"..tname].after_place_node_ then
				minetest.registered_nodes[name.."_"..tname].after_place_node_(pos)
			end
		end,
		after_dig_node = function(pos)
			tube_scanforobjects(pos)
			if minetest.registered_nodes[name.."_"..tname].after_dig_node_ then
				minetest.registered_nodes[name.."_"..tname].after_dig_node_(pos)
			end
		end
	}
	
	if special==nil then special={} end

	for key,value in pairs(special) do
		if key=="on_construct" or key=="after_dig_node" or key=="after_place_node" then
			key=key.."_"
		end
		nodedef[key]=value
	end
	
	minetest.register_node(name.."_"..tname, nodedef)

end
end
end
end
end
end
end

noctr_textures={"pipeworks_tube_noctr.png","pipeworks_tube_noctr.png","pipeworks_tube_noctr.png",
		"pipeworks_tube_noctr.png","pipeworks_tube_noctr.png","pipeworks_tube_noctr.png"}
plain_textures={"pipeworks_tube_plain.png","pipeworks_tube_plain.png","pipeworks_tube_plain.png",
		"pipeworks_tube_plain.png","pipeworks_tube_plain.png","pipeworks_tube_plain.png"}
end_textures={"pipeworks_tube_end.png","pipeworks_tube_end.png","pipeworks_tube_end.png",
		"pipeworks_tube_end.png","pipeworks_tube_end.png","pipeworks_tube_end.png"}
short_texture="pipeworks_tube_short.png"
inv_texture="pipeworks_tube_inv.png"

register_tube("pipeworks:tube","Pneumatic tube segment",plain_textures,noctr_textures,end_textures,short_texture,inv_texture)

mese_noctr_textures={"pipeworks_mese_tube_noctr_1.png","pipeworks_mese_tube_noctr_2.png","pipeworks_mese_tube_noctr_3.png",
		"pipeworks_mese_tube_noctr_4.png","pipeworks_mese_tube_noctr_5.png","pipeworks_mese_tube_noctr_6.png"}

mese_plain_textures={"pipeworks_mese_tube_plain_1.png","pipeworks_mese_tube_plain_2.png","pipeworks_mese_tube_plain_3.png",
		"pipeworks_mese_tube_plain_4.png","pipeworks_mese_tube_plain_5.png","pipeworks_mese_tube_plain_6.png"}
mese_end_textures={"pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png",
		"pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png"}
mese_short_texture="pipeworks_mese_tube_short.png"
mese_inv_texture="pipeworks_mese_tube_inv.png"


meseadjlist={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=0,y=1,z=0},{x=0,y=-1,z=0},{x=1,y=0,z=0},{x=-1,y=0,z=0}}

register_tube("pipeworks:mese_tube","Mese pneumatic tube segment",mese_plain_textures,mese_noctr_textures,
	mese_end_textures,mese_short_texture,mese_inv_texture,
	{tube={can_go=function(pos,node,velocity,stack)
		tbl={}
		local meta=minetest.env:get_meta(pos)
		local inv=meta:get_inventory()
		local found=false
		local name=stack:get_name()
		for i,vect in ipairs(meseadjlist) do
			for _,st in ipairs(inv:get_list("line"..tostring(i))) do
				if st:get_name()==name then
					found=true
					table.insert(tbl,vect)
				end
			end
		end
		if found==false then
			for i,vect in ipairs(meseadjlist) do
				if inv:is_empty("line"..tostring(i)) then
					table.insert(tbl,vect)
				end
			end
		end
		return tbl
	end},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",
				"size[8,11]"..
				"list[current_name;line1;1,0;7,1;]"..
				"list[current_name;line2;1,1;7,1;]"..
				"list[current_name;line3;1,2;7,1;]"..
				"list[current_name;line4;1,3;7,1;]"..
				"list[current_name;line5;1,4;7,1;]"..
				"list[current_name;line6;1,5;7,1;]"..
				"image[0,0;1,1;white.png]"..
				"image[0,1;1,1;black.png]"..
				"image[0,2;1,1;green.png]"..
				"image[0,3;1,1;yellow.png]"..
				"image[0,4;1,1;blue.png]"..
				"image[0,5;1,1;red.png]"..
				"list[current_player;main;0,7;8,4;]")
		meta:set_string("infotext", "Mese pneumatic tube")
		local inv = meta:get_inventory()
		for i=1,6 do
			inv:set_size("line"..tostring(i), 7*1)
		end
	end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		return (inv:is_empty("line1") and inv:is_empty("line2") and inv:is_empty("line3") and
			inv:is_empty("line4") and inv:is_empty("line5") and inv:is_empty("line6"))
	end})