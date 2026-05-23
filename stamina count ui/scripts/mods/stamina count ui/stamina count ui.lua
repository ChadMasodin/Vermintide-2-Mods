local mod = get_mod("stamina count ui")

local SCREEN_WIDTH = 1920
local SCREEN_HEIGHT = 1080

local function get_x()
	local x = mod:get("offset_x") or 0
	local x_limit = SCREEN_WIDTH / 2
	local max_x = math.min(x, x_limit)
	local min_x = math.max(x, -x_limit)
	if x == 0 then return 0 end
	return x > 0 and max_x or min_x
end

local function get_y()
	local y = mod:get("offset_y") or 0
	local y_limit = SCREEN_HEIGHT / 2
	local max_y = math.min(y, y_limit)
	local min_y = math.max(y, -y_limit)
	if y == 0 then return 0 end
	return -(y > 0 and max_y or min_y)
end

local fake_input_service = {
	get = function() return end,
	has = function() return end,
}

local scenegraph_definition = {
	root = {
		scale = "fit",
		size = { 1920, 1080 },
		position = { 0, 0, UILayer.hud },
	},
}

local stamina_ui_definition = {
	scenegraph_id = "root",
	element = {
		passes = {
			{
				style_id = "stamina_text",
				pass_type = "text",
				text_id = "stamina_text",
				retained_mode = false,
				content_check_function = function(content)
					local show_mode = mod:get("show_mode")
					if show_mode == "blocking" then
						return content.is_blocking
					end
					return true
				end,
			},
			{
				style_id = "delay_text",
				pass_type = "text",
				text_id = "delay_text",
				retained_mode = false,
				content_check_function = function(content)
					return content.display_recovery_delay and content.has_delay
				end,
			},
		},
	},
	content = {
		stamina_text = "",
		delay_text = "",
		is_blocking = false,
		has_delay = false,
		display_recovery_delay = false,
	},
	style = {
		stamina_text = {
			font_type = "hell_shark",
			font_size = mod:get("font_size") or 24,
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				get_x(),
				get_y(),
				0,
			},
		},
		delay_text = {
			font_type = "hell_shark",
			font_size = mod:get("delay_font_size") or 18,
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				get_x(),
				get_y() - (mod:get("font_size") or 24),
				0,
			},
		},
	},
	offset = { 0, 0, 0 },
}

function mod:on_disabled()
	mod.ui_renderer = nil
	mod.ui_scenegraph = nil
	mod.ui_widget = nil
end

function mod:on_setting_changed()
	if not mod.ui_widget then return end
	
	local font_size = mod:get("font_size") or 24
	local delay_font_size = mod:get("delay_font_size") or 18
	
	mod.ui_widget.style.stamina_text.offset[1] = get_x()
	mod.ui_widget.style.stamina_text.offset[2] = get_y()
	mod.ui_widget.style.stamina_text.font_size = font_size
	
	mod.ui_widget.style.delay_text.offset[1] = get_x()
	mod.ui_widget.style.delay_text.offset[2] = get_y() - font_size
	mod.ui_widget.style.delay_text.font_size = delay_font_size
end

function mod:init()
	if mod.ui_widget then return end

	local world = Managers.world:world("top_ingame_view")
	mod.ui_renderer = UIRenderer.create(world, "material", "materials/fonts/gw_fonts")
	mod.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
	mod.ui_widget = UIWidget.init(stamina_ui_definition)
end

mod:hook_safe(IngameHud, "update", function(self, dt, t)
	local player_manager = Managers.player
	local local_player = player_manager and player_manager:local_player()
	local player_unit = local_player and local_player.player_unit

	if not player_unit or not Unit.alive(player_unit) then return end

	local status_system = ScriptUnit.has_extension(player_unit, "status_system")
	if not status_system or status_system:is_dead() then return end

	if not mod.ui_widget then
		mod:init()
	end

	local widget = mod.ui_widget
	local ui_renderer = mod.ui_renderer
	local ui_scenegraph = mod.ui_scenegraph

	-- ==========================================
	-- 1. РАСЧЕТ ВЫНОСЛИВОСТИ
	-- ==========================================
	local max_stamina = status_system:get_max_fatigue_points() or status_system.max_fatigue_points or 0
	local current_fatigue = status_system.fatigue or 0
	local max_fatigue = PlayerUnitStatusSettings and PlayerUnitStatusSettings.MAX_FATIGUE or 100

	if max_fatigue <= 0 then max_fatigue = 100 end

	local inverse_coef = max_stamina / max_fatigue
	local current_stamina = math.max(0, (max_fatigue - current_fatigue) * inverse_coef)

	local curr_str = string.format("%.2f", current_stamina)
	local max_str = string.format("%.0f", max_stamina)
	local display_text = curr_str .. "/" .. max_str

	if mod:get("show_prefix") then
		display_text = "Stamina: " .. display_text
	end

	widget.content.stamina_text = display_text
	widget.content.is_blocking = status_system:is_blocking()

	-- ==========================================
	-- 2. РАСЧЕТ ТАЙМЕРА ЗАДЕРЖКИ
	-- ==========================================
	local game_time = Managers.time:time("game")
	local last_gain_time = status_system.last_fatigue_gain_time or 0
	
	local base_delay = status_system.block_broken_degen_delay 
		or status_system.push_degen_delay 
		or (PlayerUnitStatusSettings and PlayerUnitStatusSettings.FATIGUE_DEGEN_DELAY) 
		or 1
	
	-- Применяем баффы "fatigue_regen", разделяя на них degen_delay
	local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
	local fatigue_regen_buff = 1
	if buff_extension and buff_extension.apply_buffs_to_value then
		fatigue_regen_buff = buff_extension:apply_buffs_to_value(1, "fatigue_regen")
	end
	if fatigue_regen_buff <= 0 then fatigue_regen_buff = 1 end
	
	base_delay = base_delay / fatigue_regen_buff
	
	-- Вычисляем оставшееся время задержки восстановления
	local time_left = (last_gain_time + base_delay) - game_time

	widget.content.display_recovery_delay = mod:get("display_recovery_delay")
	
	-- Показываем таймер, только если задержка активна и стамина потрачена (fatigue > 0)
	if time_left > 0 and current_fatigue > 0 then
		widget.content.has_delay = true
		widget.content.delay_text = string.format("%.2fs", time_left)
	else
		widget.content.has_delay = false
	end

	-- ==========================================
	-- 3. ОТРИСОВКА
	-- ==========================================
	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt)
	UIRenderer.draw_widget(ui_renderer, widget)
	UIRenderer.end_pass(ui_renderer)
end)