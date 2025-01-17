local mod = get_mod("UnitExplorer")
require 'scripts/mods/UnitExplorer/utils/strManip'
levelIO = {}
levelIO.__index = levelIO

function levelIO:save(unit, rotBox, pos, scale)
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
	level_file:write(tostring(scale.x).."\n")
	level_file:write(tostring(scale.y).."\n")
	level_file:write(tostring(scale.z).."\n")
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

	local scale = Unit.local_scale(unit, 0)
	local xS,yS,zS = Vector3.to_elements(scale)
	local scale_str = tostring(xS).."\n"..tostring(yS).."\n"..tostring(zS).."\n"
	
	local search_string = unit_name_str.."\n"..pos_str..rot_str..scale_str.."\n"
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

function levelIO:addRemovalList(unit)
	local didremove = false
	if Unit.id32(unit) and Unit.alive(unit) then
		
		local fileName = tostring(Managers.state.game_mode:level_key()).."_removal.txt"
		local level_file = io.open(fileName,"a+")
		local file_string = level_file:read("*all")
		if file_string and Unit.id32(unit) then
			local i, j = string.find(file_string, tostring(Unit.id32(unit)))
			if i == nil then
				level_file:write(Unit.id32(unit))
				level_file:write("\n")
				level_file:close()
				didremove = true
				return didremove
			end
		else 
			level_file:write(Unit.id32(unit))
			level_file:write("\n")
			level_file:close()
			didremove = true
			return didremove
		end		
	end
	
	return didremove
end


function levelIO:load()
	local file_name = tostring(Managers.state.game_mode:level_key())..".txt"
	local ctr = 0
	for _ in io.lines(file_name) do
	  ctr = ctr + 1
	end
	--12 is the number of lines used to store all the unit data
	local unit_cnt = math.floor(ctr/12)
	
	local world = Managers.world:world("level_world")
	local unit_table = {}
	local pos = Vector3.zero()
	local scale = Vector3.zero()
	
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

		unit_table.scale_x = level_file:read()
		unit_table.scale_y = level_file:read()
		unit_table.scale_z = level_file:read()
		Vector3.set_xyz(scale, unit_table.scale_x, unit_table.scale_y, unit_table.scale_z)

		local pose_mat = Matrix4x4.zero()
		Matrix4x4.set_rotation(pose_mat, quat)
        Matrix4x4.set_scale(pose_mat, scale)
		Matrix4x4.set_translation(pose_mat, pos)
		local unit = World.spawn_unit(world, unit_table.unit_hash, pose_mat)
		--mod:echo(Matrix4x4.x(pose_mat))
		--mod:echo(Matrix4x4.y(pose_mat))
		--mod:echo(Matrix4x4.z(pose_mat))
		--Unit.set_local_scale(unit, 0, scale)

		--this read is to read in the "\n "character that caps the end of each unit entry
		if i < unit_cnt then 
			level_file:read()
		end
		didSpawn = true
	end
	level_file:close()
end


function levelIO:RemovalList()
	local didRemove = false
	local file_name = tostring(Managers.state.game_mode:level_key()).."_removal.txt"
	local ctr = 0
	for _ in io.lines(file_name) do
	  ctr = ctr + 1
	end
	local world = Managers.world:world("level_world")
	local unit_list = World.units(world)
	local level_file = io.open(file_name, "r")
	--level_file:read()
	local Unid = ""
	
	for i=0,ctr,1 do
		Unid = level_file:read()
		for _,v in pairs(unit_list) do 
			if (tostring(Unit.id32(v)) == Unid)then
				World.destroy_unit(world, v)
			end
		end
		world = Managers.world:world("level_world")
		unit_list = World.units(world)
		didRemove = true
	end
	return didRemove
end


function levelIO:clear()
	local file_name = tostring(Managers.state.game_mode:level_key())..".txt"
	local level_file = io.open(file_name, "w")
	level_file:write("")
	level_file:close()
	local file_name_remove = tostring(Managers.state.game_mode:level_key()).."_removal.txt"
	local level_file_remove = io.open(file_name_remove, "w")
	level_file_remove:write("")
	level_file_remove:close()
	return
end

return