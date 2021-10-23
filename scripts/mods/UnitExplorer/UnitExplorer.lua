-- luacheck: globals get_mod Imgui class ShowCursorStack Keyboard Managers
-- luacheck: globals LevelHelper Level Unit RESOLUTION_LOOKUP ScriptUnit Quaternion
-- luacheck: globals World Actor Color table
require 'scripts/mods/UnitExplorer/utils/level_IO'
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
mod.roll = true
mod.pitch = false
mod.yaw = false

function mod.update()
    mod.handle_inputs()

    if mod.dragging then mod.drag_unit() end

    --if mod.scaling then mod.scale_unit() end

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
    
    if mod.roll then 
        local y_axis = Vector3.zero()
        Vector3.set_y(y_axis, 1)
        local roll_rotation = Quaternion.axis_angle(y_axis, look_delta.x)
        local rolled_matrix = Quaternion.multiply(current_rotation, roll_rotation)
        return Quaternion.normalize(rolled_matrix)
    end
    if mod.pitch then
        local y_axis = Vector3.zero()
        Vector3.set_x(y_axis, 1)
        local roll_rotation = Quaternion.axis_angle(y_axis, look_delta.x)
        local rolled_matrix = Quaternion.multiply(current_rotation, roll_rotation)
        return Quaternion.normalize(rolled_matrix)
    end
    if mod.yaw then 
        local y_axis = Vector3.zero()
        Vector3.set_z(y_axis, 1)
        local roll_rotation = Quaternion.axis_angle(y_axis, look_delta.x)
        local rolled_matrix = Quaternion.multiply(current_rotation, roll_rotation)
        return Quaternion.normalize(rolled_matrix)
    end
    return current_rotation
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
	levelIO:RemovalList()
	mod:echo('loading')
	levelIO:load()	
	mod:echo('loaded')
end)

mod:command("clear_file", "deletes all saved untis from file", function()
	levelIO:clear()
	mod:echo('cleared')
end)