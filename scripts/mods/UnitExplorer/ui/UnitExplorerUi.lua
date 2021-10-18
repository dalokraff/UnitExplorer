-- luacheck: globals UnitExplorerUi Imgui Managers LevelHelper Level ShowCursorStack class Keyboard Unit get_mod World
local mod = get_mod("UnitExplorer")

local function spawn_package_to_player (unit)
    mod:echo("Creating a '%s'", mod.unit_hash(unit))
    local player = Managers.player:local_player()
    local world = Managers.world:world("level_world")

    if world and player and player.player_unit then
        local player_unit = player.player_unit

        local position = Unit.local_position(player_unit, 0)
        local rotation = Unit.local_rotation(player_unit, 0)
        return World.spawn_unit(world, Unit.name_hash(unit), position, rotation)
    end

    return nil
end

local function spawn_package_at_look (unit)
    mod:echo("Creating a '%s'", mod.unit_hash(unit))
    local player = Managers.player:local_player()

    local world = Managers.world:world("level_world")
    local physics_world = World.get_data(world, "physics_world")

    local player_unit = Managers.player:local_player().player_unit
    local first_person_extension = ScriptUnit.extension(player_unit, "first_person_system")
    local camera_position = first_person_extension:current_position()
    local camera_rotation = first_person_extension:current_rotation()
    local camera_forward = Quaternion.forward(camera_rotation)
    local distance = 15999
    local hits = physics_world:immediate_raycast(
        camera_position, camera_forward, distance,
        "all", "collision_filter", "filter_lookat_object_ray"
        )

    local closest_hit_location = nil
    local closest_hit = 9999
    for _, hit in ipairs(hits) do
        local location = hit[1]
        local hit_distance = hit[2]
        local actor = hit[4]
        local hit_unit = Actor.unit(actor)
        if hit_unit ~= player_unit and hit_distance <= closest_hit then
            closest_hit_location = location
            closest_hit = hit_distance
        end
    end

    if world and player and player.player_unit and closest_hit_location then
        local rotation = Unit.local_rotation(player_unit, 0)
		
		local level_file = io.open("level.txt","a")
		local stor_rot = QuaternionBox(rotation)
		if true then
			local unit_name_str = mod.str_replacer(tostring(Unit.name_hash(unit)), true)
			level_file:write(unit_name_str)
			level_file:write("\n")
			
			level_file:write(tostring(closest_hit_location.x).."\n")
			level_file:write(tostring(closest_hit_location.y).."\n")
			level_file:write(tostring(closest_hit_location.z).."\n")
			
			local x,y,z,w = Quaternion.to_elements(Quaternion.normalize(QuaternionBox.unbox(stor_rot)))
			local rot_tab = {tostring(x),tostring(y),tostring(z),tostring(w)}
			local rot_str = mod.strTbl_ceil(rot_tab)
			level_file:write(rot_str)
			level_file:write("\n")
		end
		level_file:close()
		
        return World.spawn_unit(world, Unit.name_hash(unit), closest_hit_location, rotation)
    end

    return nil
end

local function destroy_unit(unit)
    mod:echo("Destroying a '%s'", mod.unit_hash(unit))
    local world = Managers.world:world("level_world")
	
	--copy added level data to a string for parsing
	local level_file = io.open("level.txt","r")
	local temp_file = level_file:read("*all")
	level_file:close()
	
	local unit_name = tostring(Unit.name_hash(unit))
	local unit_name_str = mod.str_replacer(unit_name, true)
	
	local x1,y1,z1 = Vector3.to_elements(Unit.local_position(unit,0))
	local pos_str = tostring(x1).."\n"..tostring(y1).."\n"..tostring(z1).."\n"
	local norm_quat = Quaternion.normalize(Unit.local_rotation(unit,0))
	local x2,y2,z2,w2 = Quaternion.to_elements(norm_quat)
	local rot_tab ={tostring(x2),tostring(y2),tostring(z2),tostring(w2)}
	local rot_str = mod.strTbl_ceil(rot_tab)
	
	local search_string = unit_name_str.."\n"..pos_str..rot_str.."\n"
	search_string = string.gsub(search_string, "%-", "%%%-")
	temp_file,_ = string.gsub(temp_file, search_string, "")
	local new_level = io.open("level.txt", "w")
	new_level:write(temp_file)
	new_level:close()
	
	world:destroy_unit(unit)
end

UnitExplorerUi = class(UnitExplorerUi)

function UnitExplorerUi.init(self)
    self._is_open = false
end

function UnitExplorerUi.toggle(self)
    if self._is_open then
        self:close()
    else
        self:open()
    end
end

function UnitExplorerUi.open(self, unit)
    self._unit = unit
    self._is_open = true
    Imgui.open_imgui()
    -- self:capture_input()
end

function UnitExplorerUi.capture_input()
    ShowCursorStack.push()
    Imgui.enable_imgui_input_system(Imgui.KEYBOARD)
    Imgui.enable_imgui_input_system(Imgui.MOUSE)
end

function UnitExplorerUi.draw(self)
    local unit = self._unit
    local data = mod.extract_unit_data(unit)
    Imgui.set_next_window_size(400, 400)
    Imgui.begin_window("Unit Explorer")
    Imgui.spacing()
    Imgui.text(string.format("ID: %s", data.id))
    Imgui.text(string.format("Hash: %s", data.hash))
    Imgui.text("Pos: " .. tostring(data.position:unbox()))
    Imgui.text("Rot: " .. tostring(data.rotation:unbox()))
    -- Imgui.text("Has idle anim: " .. (data.has_idle_anim and "true" or "false"))
    -- Imgui.text("Has state machine: " .. (data.has_animation_state_machine and "true" or "false"))
    -- Imgui.text("Bone mode: " .. data.bone_mode)

    if Imgui.tree_node("Extensions", #data.extensions > 0) then
        for _, extension in ipairs(data.extensions) do
            Imgui.text(extension)
        end

        Imgui.tree_pop()
    end

    Imgui.spacing()
    if Imgui.button("Create (Ins)") or Keyboard.pressed(Keyboard.button_index("insert")) then
        spawn_package_at_look(unit)
    end
    Imgui.same_line()
    if Imgui.button("Delete (Del)") or Keyboard.pressed(Keyboard.button_index("delete")) then
        destroy_unit(unit)
        self._unit = nil
        self:close()
    end
    Imgui.end_window()
    if Keyboard.pressed(Keyboard.button_index("esc")) then
        self:close()
    end
end

function UnitExplorerUi.release_input()
    ShowCursorStack.pop()
    Imgui.disable_imgui_input_system(Imgui.KEYBOARD)
    Imgui.disable_imgui_input_system(Imgui.GAMEPAD)
end

function UnitExplorerUi.close(self)
    self._is_open = false
    Imgui.close_imgui()
    -- self:release_input()
end

return UnitExplorerUi
