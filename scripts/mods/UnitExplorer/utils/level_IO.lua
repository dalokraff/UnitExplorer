local mod = get_mod("UnitExplorer")
require 'scripts/mods/UnitExplorer/utils/strManip'
levelIO = {}
levelIO.__index = levelIO

function levelIO:save(unit, rotBox, pos)
	local fileName = tostring(Managers.state.game_mode:level_key())..".txt"
	local level_file = io.open(fileName,"a")
	local unit_name_str = strManip:replacer(tostring(Unit.name_hash(unit)), true)
	local x,y,z,w = Quaternion.to_elements(Quaternion.normalize(QuaternionBox.unbox(rotBox)))
	local rot_tab = {tostring(x),tostring(y),tostring(z),tostring(w)}
	local rot_str = strManip:ceil(rot_tab)
	
	level_file:write(unit_name_str)
	level_file:write("\n")
	level_file:write(tostring(pos.x).."\n")
	level_file:write(tostring(pos.y).."\n")
	level_file:write(tostring(pos.z).."\n")
	level_file:write(rot_str)
	level_file:write("\n")
	level_file:close()
	return true
end

function levelIO:remove(unit)
	local file_name = tostring(Managers.state.game_mode:level_key())..".txt"
	local level_file = io.open(file_name,"r")
	local temp_file = level_file:read("*all")
	level_file:close()
	
	local unit_name = tostring(Unit.name_hash(unit))
	local unit_name_str = strManip:replacer(unit_name, true)
	local x1,y1,z1 = Vector3.to_elements(Unit.local_position(unit,0))
	local pos_str = tostring(x1).."\n"..tostring(y1).."\n"..tostring(z1).."\n"
	
	local norm_quat = Quaternion.normalize(Unit.local_rotation(unit,0))
	local x2,y2,z2,w2 = Quaternion.to_elements(norm_quat)
	local rot_tab ={tostring(x2),tostring(y2),tostring(z2),tostring(w2)}
	local rot_str = strManip:ceil(rot_tab)
	
	local search_string = unit_name_str.."\n"..pos_str..rot_str.."\n"
	local num_removed = 0
	search_string = string.gsub(search_string, "%-", "%%%-")
	temp_file,num_removed = string.gsub(temp_file, search_string, "")
	
	local new_level = io.open(file_name, "w")
	new_level:write(temp_file)
	new_level:close()
	
	local query = false
	if num_removed > 0 then
		query = true
	end
	
	return query
end

function levelIO:load()
	local file_name = tostring(Managers.state.game_mode:level_key())..".txt"
	local ctr = 0
	for _ in io.lines(file_name) do
	  ctr = ctr + 1
	end
	--9 is the number of lines used to store all the unit data
	local unit_cnt = ctr/9
	
	local world = Managers.world:world("level_world")
	local unit_table = {}
	local pos = Vector3.zero()
	
	local level_file = io.open(file_name, "r")
	
	for i=0,unit_cnt,1 do
		unit_table.unit_hash = level_file:read()
		unit_table.unit_hash = strManip:replacer(unit_table.unit_hash, false)
		
		unit_table.pos_x = level_file:read()
		unit_table.pos_y = level_file:read()
		unit_table.pos_z = level_file:read()
		Vector3.set_xyz(pos, unit_table.pos_x, unit_table.pos_y, unit_table.pos_z)
		
		unit_table.rot_x = level_file:read()
		unit_table.rot_y = level_file:read()
		unit_table.rot_z = level_file:read()
		unit_table.rot_w = level_file:read()
		local quat = Quaternion.from_elements(unit_table.rot_x, unit_table.rot_y, unit_table.rot_z, unit_table.rot_w)
		
		World.spawn_unit(world, unit_table.unit_hash, pos, Quaternion.normalize(quat))
		--this read is to read in the "\n "character that caps the end of each unit entry
		level_file:read()
	end
	level_file:close()	
end

function levelIO:clear()
	local file_name = tostring(Managers.state.game_mode:level_key())..".txt"
	local level_file = io.open(file_name, "w")
	level_file:write("")
	level_file:close()
end

return