local mod = get_mod("FOG") --Get the mod
local scoreboard_extension = get_mod("scoreboard_extension") --Get the scoreboard_extension mod

local drinks_drunk = {}
local drunk_time = {}
local total_time = {}

mod:hook_safe(BuffFunctionTemplates.functions, "increase_intoxication_level", function(unit, buff, params, world)
	local player = Managers.player:owner(unit)
	local stats_id = player:stats_id()
	if drinks_drunk[stats_id] then
		drinks_drunk[stats_id] = drinks_drunk[stats_id] + 1
	else
		drinks_drunk[stats_id] = 1
	end
	mod.set_stats_display_enabled(true)
end)

mod.get_drinks = function(peer_id, local_player_id, stats_id, id)
	return drinks_drunk[stats_id] or 0
end

mod:hook_safe(BuffFunctionTemplates.functions, "update_intoxication_level", function(unit, buff, params, world)
	local player = Managers.player:owner(unit)

	if player then
		local stats_id = player:stats_id()
		local status_extension = ScriptUnit.extension(unit, "status_system")
		local intoxication_level = status_extension:intoxication_level()
		local timer_game = Managers.time._timers["game"]
		local dt = timer_game:delta_time()

		if not drunk_time[stats_id] then drunk_time[stats_id] = 0 end
		if not total_time[stats_id] then total_time[stats_id] = 0 end

		if intoxication_level > 0 then drunk_time[stats_id] = drunk_time[stats_id] + dt end
		total_time[stats_id] = total_time[stats_id] + dt
	end
end)

mod.get_drunk_percent = function(peer_id, local_player_id, stats_id, id)
	local drunk_t = drunk_time[stats_id] or 0
	local total_t = total_time[stats_id] or 1
	return math.round_with_precision(drunk_t/total_t*100, 2)
end

mod.set_stats_display_enabled = function(enabled)
	scoreboard_extension:set_entry("AQD_drinks", enabled)
	scoreboard_extension:set_entry("AQD_drunk", enabled)
end

scoreboard_extension:register_entry("AQD_drinks", "Drinks Drunk", "highest", mod.get_drinks)
scoreboard_extension:register_entry("AQD_drunk", "% of Time Spent Drunk", "highest", mod.get_drunk_percent)
mod.set_stats_display_enabled(false)

mod:hook_safe(StateIngame, "on_enter", function(self)
	drinks_drunk = {}
	drunk_time = {}
	total_time = {}
	mod.set_stats_display_enabled(false)
end)