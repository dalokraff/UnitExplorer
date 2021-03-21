-- luacheck: globals Unit get_mod
local mod = get_mod("UnitExplorer")

function mod.unit_hash(unit)
    local debug_name = Unit.debug_name(unit)
    debug_name = string.gsub(debug_name, "#ID%[", "")
    debug_name = string.gsub(debug_name, "%]", "")
    return debug_name
end

function mod.drag_unit(unit_explorer)
    local player_manager = Managers.player
    local local_player = player_manager:local_player()
    local viewport_name = local_player.viewport_name
    local camera_position = Managers.state.camera:camera_position(viewport_name)
    local camera_rotation = Managers.state.camera:camera_rotation(viewport_name)
    local camera_direction = Quaternion.forward(camera_rotation)

    local unit = mod.dragged_unit
    -- mod:echo(unit)
    local unit_position = Unit.local_position(unit, 0)
    local unit_rotation = Unit.local_rotation(unit, 0)
    local unit_hash = Unit.name_hash(unit)
    local spawn_position =
        camera_position + Vector3.normalize(camera_direction) *
            mod.dragged_unit_distance

    local world = Managers.world:world("level_world")
    world:destroy_unit(unit)

    mod.dragged_unit = World.spawn_unit(world, unit_hash, spawn_position,
                                        unit_rotation)

    mod.outline_unit(mod.dragged_unit)

    mod.unit_explorer._unit = mod.dragged_unit
end

function mod.outline_unit(unit)
    local flag = "outline_unit"
    local channel = Color(255, 0, 0, 255)
    local apply_method = "unit_and_childs"
    local outline_system = Managers.state.entity:system("outline_system")
    local do_outline = true
    outline_system:outline_unit(unit, flag, channel, do_outline, apply_method)
end
