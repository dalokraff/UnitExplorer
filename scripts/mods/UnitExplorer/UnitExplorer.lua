-- luacheck: globals get_mod Imgui class ShowCursorStack Keyboard Managers
-- luacheck: globals LevelHelper Level Unit RESOLUTION_LOOKUP ScriptUnit Quaternion
-- luacheck: globals World Actor Color table
local mod = get_mod("UnitExplorer")

mod:dofile("scripts/mods/UnitExplorer/utils/unit")
mod:dofile("scripts/mods/UnitExplorer/utils/InputHandler")
mod:dofile("scripts/mods/UnitExplorer/utils/strManip")
local LevelExplorerUi = mod:dofile(
    "scripts/mods/UnitExplorer/ui/LevelExplorerUi")
local UnitExplorerUi = mod:dofile("scripts/mods/UnitExplorer/ui/UnitExplorerUi")
mod.level_explorer = LevelExplorerUi:new()
mod.unit_explorer = UnitExplorerUi:new()

mod.outlined_unit = nil

------------------
--	Dragging state
------------------
mod.dragged_unit = nil
mod.dragging = false
mod.dragged_unit_distance = 0

------------------
--	Rotation state
------------------
mod.rotating = false
mod.dragged_rotation = nil

function mod.update()
    mod.handle_inputs()

    if mod.dragging then mod.drag_unit() end

    if mod.unit_explorer and mod.unit_explorer._is_open then
        mod.unit_explorer:draw()
    end

    if mod.level_explorer and mod.level_explorer._is_open then
        mod.level_explorer:draw()
    end
end

local small_delta = math.pi / 15
local MAX_MIN_PITCH = math.pi
local function calculate_rotation(current_rotation, look_delta)
    local yaw = Quaternion.yaw(current_rotation) - look_delta.x

    -- if self.restrict_rotation_angle then
    -- 	yaw = math.clamp(yaw, -self.restrict_rotation_angle, self.restrict_rotation_angle)
    -- end

    local pitch = math.clamp(Quaternion.pitch(current_rotation) + look_delta.y, -MAX_MIN_PITCH, MAX_MIN_PITCH)
    local yaw_rotation = Quaternion(Vector3.up(), yaw)
    local pitch_rotation = Quaternion(Vector3.right(), pitch)
    local look_rotation = Quaternion.multiply(yaw_rotation, pitch_rotation)

    return look_rotation
end

mod:hook(CharacterStateHelper, "get_look_input", function(func, input_extension, status_extension, inventory_extension, is_3p)
    local look_delta = func(input_extension, status_extension, inventory_extension, is_3p)
    if mod.dragging and mod.rotating then
        mod.dragged_rotation = QuaternionBox(calculate_rotation(mod.dragged_rotation:unbox(), look_delta))
        return Vector3(0,0,0)
    else
        return look_delta
    end
end)

mod:command("spawn_lvls", "Spawn in saved units", function() 
	
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
		unit_table.unit_hash = mod.str_replacer(unit_table.unit_hash, false)
		
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
end)

mod:command("clear_file", "deletes all saved untis from file", function()
	local file_name = tostring(Managers.state.game_mode:level_key())..".txt"
	local level_file = io.open(file_name, "w")
	level_file:write("")
	level_file:close()
end)