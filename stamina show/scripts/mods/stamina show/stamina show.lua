local mod = get_mod("stamina show") --Get the mod

local DamageDataIndex = DamageDataIndex
local MAX_INTOXICATION_LEVEL = 3
local MIN_INTOXICATION_LEVEL = -3
local NUM_PACK_MASTER_GRABS = 2
local NUM_GLOBADIER_POISONS = 2
local GLOBADIER_POISONS_TIMEOUT = 60
local NUM_TIMES_KNOCKED_DOWN = 2
local block_breaking_fatigue_types = {
	blocked_attack = true,
	blocked_attack_2 = true,
	blocked_attack_3 = true,
	blocked_berzerker = true,
	blocked_charge = true,
	blocked_headbutt = true,
	blocked_ranged = true,
	blocked_running = true,
	blocked_slam = true,
	blocked_sv_cleave = true,
	blocked_sv_sweep = true,
	blocked_sv_sweep_2 = true,
	chaos_cleave = true,
	chaos_spawn_combo = true,
	complete = true,
	ogre_shove = true,
	shield_blocked_slam = true,
	sv_push = true,
	sv_shove = true,
}
-- Хранилище для группировки одинаковых атак
mod.fatigue_accumulator = {
    type = nil,
    count = 0,
    total_cost = 0,
    single_cost = 0,
    initial_stamina = 0,
    current_stamina = 0,
    last_time = 0
}

-- Функция для формирования и вывода сообщения
function mod:flush_fatigue_echo()
    local acc = self.fatigue_accumulator
    if acc.count == 0 then return end

    local totalCostFormatted = string.format("%.3f", acc.total_cost)
    local singleCostFormatted = string.format("%.3f", acc.single_cost)
    local prevStaminaFormatted = string.format("%.3f", acc.initial_stamina)
    local newStaminaFormatted = string.format("%.3f", acc.current_stamina)
    local f_type = acc.type or "NIL FATIGUE TYPE"

    -- Если атак было больше одной, показываем количество и урон от одной
    if acc.count > 1 then
        self:echo("Stamina cost: " .. totalCostFormatted .. " (" .. acc.count .. "x, " .. singleCostFormatted .. " per hit) (" .. prevStaminaFormatted .. " -> " .. newStaminaFormatted .. ") " .. f_type)
    else
        self:echo("Stamina cost: " .. totalCostFormatted .. " (" .. prevStaminaFormatted .. " -> " .. newStaminaFormatted .. ") " .. f_type)
    end

    -- Сбрасываем счетчик после вывода
    acc.count = 0
end

-- Хук обновления (вызывается каждый кадр игрой).
-- Нужен, чтобы выводить сообщение, когда нас перестали бить.
mod.update = function(dt)
    local acc = mod.fatigue_accumulator
    if acc.count > 0 then
        local current_time = Managers.time:time("game")
        -- Если с момента последнего удара прошла 0.75 секунда — выводим результат
        if current_time and (current_time - acc.last_time) > 0.75 then
            mod:flush_fatigue_echo()
        end
    end
end

mod:hook_origin("GenericStatusExtension", "add_fatigue_points", function(self, fatigue_type, attacking_unit, blocking_weapon_unit, fatigue_point_costs_multiplier, is_timed_block)
	local buff_extension = self.buff_extension

	if Development.parameter("disable_fatigue_system") then
		return
	end

	local player = self.player

	if player and player.remote then
		Crashify.print_exception("[GenericStatusExtension]", "Tried adding fatigue points to a remote player.")

		return
	end

	local amount = PlayerUnitStatusSettings.fatigue_point_costs[fatigue_type]
	local t = Managers.time:time("game")
	local max_fatigue = PlayerUnitStatusSettings.MAX_FATIGUE
	local max_fatigue_points = self.max_fatigue_points
	local fatigue_cost = amount * (max_fatigue / max_fatigue_points) * (fatigue_point_costs_multiplier or 1)

	if is_timed_block then
		fatigue_cost = buff_extension:apply_buffs_to_value(fatigue_cost, "timed_block_cost")
	end

	if amount and fatigue_point_costs_multiplier and amount < 2 and fatigue_point_costs_multiplier < 1 and buff_extension:has_buff_perk("in_arc_block_cost_reduction") then
		fatigue_cost = 0
	end

	if blocking_weapon_unit then
		fatigue_cost = buff_extension:apply_buffs_to_value(fatigue_cost, "block_cost")

		if buff_extension:has_buff_perk("overcharged_block") then
			local overcharge_extension = ScriptUnit.has_extension(self.unit, "overcharge_system")

			if overcharge_extension and overcharge_extension:above_overcharge_threshold() then
				fatigue_cost = fatigue_cost * 0.5

				overcharge_extension:remove_charge(amount)
			end
		end
	end


	-- <DEBUG>
	local inverseCoef = max_fatigue_points / max_fatigue

	local previousFatigue = self.fatigue
	local previousStaminaPercent = max_fatigue - previousFatigue
	local previousStamina = previousStaminaPercent * inverseCoef
	
	local fatigue = math.clamp(self.fatigue + fatigue_cost, 0, max_fatigue)
	
	self:set_fatigue_points(fatigue, fatigue_type)
	
	local newFatigue = self.fatigue
	local newStaminaPercent = max_fatigue - newFatigue
	local newStamina = newStaminaPercent * inverseCoef
	
	local staminaCost = fatigue_cost * inverseCoef
	
	local current_time = Managers.time:time("game")
	
	local acc = mod.fatigue_accumulator

	-- Если тип усталости сменился, принудительно выводим то, что накопили до этого
	if acc.count > 0 and acc.type ~= fatigue_type then
		mod:flush_fatigue_echo()
	end

	-- Записываем новые данные или плюсуем к старым
	if acc.count == 0 then
		acc.type = fatigue_type
		acc.single_cost = staminaCost
		acc.total_cost = staminaCost
		acc.count = 1
		acc.initial_stamina = previousStamina
		acc.current_stamina = newStamina
	else
		acc.count = acc.count + 1
		acc.total_cost = acc.total_cost + staminaCost
		acc.current_stamina = newStamina -- обновляем до актуальной выносливости после всех ударов
	end
	acc.last_time = current_time
	-- </DEBUG>

	if blocking_weapon_unit then
		buff_extension:trigger_procs("on_block", attacking_unit, fatigue_type, blocking_weapon_unit)
	end

	if max_fatigue <= fatigue and block_breaking_fatigue_types[fatigue_type] then
		self:set_block_broken(true, t, attacking_unit)
	end

	if fatigue_cost > 0 then
		self.last_fatigue_gain_time = t
		self.show_fatigue_gui = true
	end

	if fatigue_type == "action_stun_push" then
		self.action_stun_push = true
	end

	local first_person_extension = self.first_person_extension

	if amount > PlayerUnitStatusSettings.fatigue_points_to_play_heavy_block_sfx and first_person_extension then
		first_person_extension:play_hud_sound_event("Play_player_combat_heavy_block_sweetner", nil, false)
	end

end)

-- Вмешиваемся в систему баффов, чтобы игра сама корректно 
-- пересчитала все лимиты, затраты на пуш-атаки и регенерацию.
mod:hook("BuffExtension", "apply_buffs_to_value", function(func, self, value, stat_buff)
    -- Сначала получаем оригинальное значение (с учетом оружия и свойств предметов)
    local result = func(self, value, stat_buff)
    
    -- Если игра запрашивает характеристику "максимальная выносливость"...
    if stat_buff == "max_fatigue" then
        local local_player = Managers.player:local_player()
        
        -- Проверяем, что бафф применяется именно к нашему персонажу (а не к ботам)
        if local_player and local_player.player_unit == self._unit then
            local custom_stamina = mod:get("max_stamina_override")
            
            -- Если ползунок больше 0, подменяем финальное значение стамины
            if custom_stamina and custom_stamina > 0 then
                return custom_stamina
            end
        end
    end
    
    return result
end)

	-- ==========================================
	-- Original script for show stamina by Prismism
	-- ==========================================
	
--[[
	local DamageDataIndex = DamageDataIndex
	local MAX_INTOXICATION_LEVEL = 3
	local MIN_INTOXICATION_LEVEL = -3
	local NUM_PACK_MASTER_GRABS = 2
	local NUM_GLOBADIER_POISONS = 2
	local GLOBADIER_POISONS_TIMEOUT = 60
	local NUM_TIMES_KNOCKED_DOWN = 2
	local block_breaking_fatigue_types = {
		blocked_attack = true,
		blocked_attack_2 = true,
		blocked_attack_3 = true,
		blocked_berzerker = true,
		blocked_charge = true,
		blocked_headbutt = true,
		blocked_ranged = true,
		blocked_running = true,
		blocked_slam = true,
		blocked_sv_cleave = true,
		blocked_sv_sweep = true,
		blocked_sv_sweep_2 = true,
		chaos_cleave = true,
		chaos_spawn_combo = true,
		complete = true,
		ogre_shove = true,
		shield_blocked_slam = true,
		sv_push = true,
		sv_shove = true,
	}
	
	mod:hook_origin("GenericStatusExtension", "add_fatigue_points", function(self, fatigue_type, attacking_unit, blocking_weapon_unit, fatigue_point_costs_multiplier, is_timed_block)
		local buff_extension = self.buff_extension
	
		if Development.parameter("disable_fatigue_system") then
			return
		end
	
		local player = self.player
	
		if player and player.remote then
			Crashify.print_exception("[GenericStatusExtension]", "Tried adding fatigue points to a remote player.")
	
			return
		end
	
		local amount = PlayerUnitStatusSettings.fatigue_point_costs[fatigue_type]
		local t = Managers.time:time("game")
		local max_fatigue = PlayerUnitStatusSettings.MAX_FATIGUE
		local max_fatigue_points = self.max_fatigue_points
		local fatigue_cost = amount * (max_fatigue / max_fatigue_points) * (fatigue_point_costs_multiplier or 1)
	
		if is_timed_block then
			fatigue_cost = buff_extension:apply_buffs_to_value(fatigue_cost, "timed_block_cost")
		end
	
		if amount and fatigue_point_costs_multiplier and amount < 2 and fatigue_point_costs_multiplier < 1 and buff_extension:has_buff_perk("in_arc_block_cost_reduction") then
			fatigue_cost = 0
		end
	
		if blocking_weapon_unit then
			fatigue_cost = buff_extension:apply_buffs_to_value(fatigue_cost, "block_cost")
	
			if buff_extension:has_buff_perk("overcharged_block") then
				local overcharge_extension = ScriptUnit.has_extension(self.unit, "overcharge_system")
	
				if overcharge_extension and overcharge_extension:above_overcharge_threshold() then
					fatigue_cost = fatigue_cost * 0.5
	
					overcharge_extension:remove_charge(amount)
				end
			end
		end
	
	
		-- <DEBUG>
		local inverseCoef = max_fatigue_points / max_fatigue
		
		local previousFatigue = self.fatigue
		local previousStaminaPercent = max_fatigue - previousFatigue
		local previousStamina = previousStaminaPercent * inverseCoef
		local previousStaminaFormatted = string.format("%.2f", previousStamina)
		-- </DEBUG>
	
		local fatigue = math.clamp(self.fatigue + fatigue_cost, 0, max_fatigue)
	
		self:set_fatigue_points(fatigue, fatigue_type)
	
		-- <DEBUG>
		local newFatigue = self.fatigue
		local newStaminaPercent = max_fatigue - newFatigue
		local newStamina = newStaminaPercent * inverseCoef
		local newStaminaFormatted = string.format("%.2f", newStamina)
		
		local staminaCost = fatigue_cost * inverseCoef
		local staminaCostFormatted = string.format("%.2f", staminaCost)
		
		mod:echo("Stamina cost: " .. staminaCostFormatted .. " (" .. previousStaminaFormatted .. " -> " .. newStaminaFormatted .. ") " .. (fatigue_type or "NIL FATIGUE TYPE"))
		-- </DEBUG>
	
		if blocking_weapon_unit then
			buff_extension:trigger_procs("on_block", attacking_unit, fatigue_type, blocking_weapon_unit)
		end
	
		if max_fatigue <= fatigue and block_breaking_fatigue_types[fatigue_type] then
			self:set_block_broken(true, t, attacking_unit)
		end
	
		if fatigue_cost > 0 then
			self.last_fatigue_gain_time = t
			self.show_fatigue_gui = true
		end
	
		if fatigue_type == "action_stun_push" then
			self.action_stun_push = true
		end
	
		local first_person_extension = self.first_person_extension
	
		if amount > PlayerUnitStatusSettings.fatigue_points_to_play_heavy_block_sfx and first_person_extension then
			first_person_extension:play_hud_sound_event("Play_player_combat_heavy_block_sweetner", nil, false)
		end
	end)
--]]