-- This folder contains all the "technical" backend of lottmapgen, such as
-- the biome and height maps, and the code for getting the biome/height at
-- a certain position.

local modpath = minetest.get_modpath("lottmapgen") .. "/technical"

local biomes = dofile(modpath .. "/biome_map.lua")
local height = dofile(modpath .. "/height_map.lua")
dofile(modpath .. "/functions.lua")

function lottmapgen.register_biome(id, table)
	lottmapgen.biome[id] = table
end

function lottmapgen.biomes(noisy_x, noisy_z)
	local small_x = math.floor(noisy_x / 160)
	local small_z = math.floor(noisy_z / 160)
	small_x = small_x + 200
	small_z = (small_z - 200) * -1
	if biomes[small_z] and biomes[small_z][small_x] then
		return biomes[small_z][small_x]
	else
		return 99
	end
end

function lottmapgen.height(noisy_x, noisy_z)
	local small_x = math.floor(noisy_x / 160)
	local small_z = math.floor(noisy_z / 160)
	local dx = math.abs(small_x - (noisy_x / 160))
	local dz = math.abs(small_z - (noisy_z / 160))
	small_x = small_x + 200
	small_z = (small_z - 200) * -1
	if height[small_z] and height[small_z][small_x] then
		local noise = height[small_z][small_x] * 20
		for nz = -1, 1 do
		for nx = -1, 1 do
			local h = height[small_z + nz][small_x + nx]
			if h and h < height[small_z][small_x] then
				local mult = 20
				if nz == -1 and nx == -1 then
					mult =  math.floor(dx*20 + 1/dz)
				elseif nz == -1 and nx == 0 then
					mult = math.floor(1/dz)
				elseif nz == -1 and nx == 1 then
					mult = math.floor(1/dx + 1/dz)
				elseif nz == 0 and nx == -1 then
					mult = math.floor(dx*20)
				elseif nz == 0 and nx == 1 then
					mult = math.floor(1/dx)
				elseif nz == 1 and nx == -1 then
					mult = math.floor(dx*20 + dz*20)
				elseif nz == 1 and nx == 0 then
					mult = math.floor(dz*20)
				elseif nz == 1 and nx == 1 then
					mult = math.floor(1/dx + dz*20)
				end
				local new_noise = (height[small_z][small_x] - 1) * 20 + mult
				if new_noise < noise then
					noise = new_noise
				end
			end
		end
		end
		return noise
	else
		return 0
	end
end

local n_x = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 9130,
	octaves = 3,
	persist = 0.
}

local n_z = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -5500,
	octaves = 3,
	persist = 0.5
}

function lottmapgen.get_biome_at_pos(pos)
	local t1 = os.clock()
	local nx = math.floor(minetest.get_perlin(n_x):get2d({x=pos.x,y=pos.z}) * 128)
	local nz = math.floor(minetest.get_perlin(n_z):get2d({x=pos.x,y=pos.z}) * 128)
	local x = math.floor((pos.x + nx) / 160) + 200
	local z = (math.floor((pos.z + (nz - 1)) / 160) - 200) * -1
	if biomes[z] and biomes[z][x] then
		local id = biomes[z][x]
		local biome
		if lottmapgen.biome[id] then
			biome = lottmapgen.biome[id].name
		else
			biome = "Sea"
		end
		return id, biome
	end
	return nil
end

minetest.register_chatcommand("tpb", {
	params = "<image coords>",
	func = function(name, param)
		local x, z = string.match(param, "([^ ]+) (.+)")
		x = x - 200
		x = x * 160
		z = z * -1
		z = z + 200
		z = z * 160
		minetest.get_player_by_name(name):set_pos({x = x, y = 30, z = z})
	end,
})

minetest.register_chatcommand("bap", {
	func = function(name)
		local id, biome = lottmapgen.get_biome_at_pos(minetest.get_player_by_name(name):get_pos())
		minetest.chat_send_player(name, biome .. "\n(id = " .. id .. ")")
	end
})

minetest.register_chatcommand("tp", {
	params = "<biome>",
	func = function(name, param)
		param = string.lower(param)
		local player = minetest.get_player_by_name(name)
		if param == "lorien" or param == "l" then
			player:set_pos({x = 475, y = 30, z = -4175})
		elseif param == "lindon" or param == "li" then
			player:set_pos({x = -25200, y = 30, z = 4700})
		elseif param == "iron hills" or param == "iron_hills" or param == "ih" then
			player:set_pos({x = 18400, y = 30, z = 7500})
		elseif param == "breeland" or param == "bree" or param == "b" then
			player:set_pos({x = -11680, y = 30, z = 2400})
		elseif param == "eregion" or param == "e" then
			player:set_pos({x = -2900, y = 30, z = -700})
		elseif param == "blue mountains" or param == "blue_mountains" or param == "bm" then
			player:set_pos({x = -24000, y = 60, z = 12000})
		else
			minetest.chat_send_player(name, "List of places to teleport to:\n" ..
				minetest.colorize("orange", "lorien\t\tiron hills\t\tbreeland\t\teregion\t\tlindon\t\tblue mountains"))
		end
	end
})