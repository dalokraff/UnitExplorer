-- luacheck: globals get_mod Imgui class ShowCursorStack Keyboard Managers
-- luacheck: globals LevelHelper Level Unit RESOLUTION_LOOKUP ScriptUnit Quaternion
-- luacheck: globals World Actor Color table
local mod = get_mod("UnitExplorer")

mod:dofile("scripts/mods/UnitExplorer/utils/unit")
mod:dofile("scripts/mods/UnitExplorer/utils/InputHandler")
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

function mod.update()
    mod.handle_inputs()

    if mod.dragging then
		mod.drag_unit()
	end

    if mod.unit_explorer and mod.unit_explorer._is_open then
        mod.unit_explorer:draw()
    end

    if mod.level_explorer and mod.level_explorer._is_open then
        mod.level_explorer:draw()
    end
end
