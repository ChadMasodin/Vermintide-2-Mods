local mod = get_mod("stamina show")

return {
    name = "Stamina Debug",
    description = mod:localize("mod_description"),
    is_togglable = true,

	-- Добавляем меню настроек для VMF
 options = {
    widgets = {
        {
				setting_id = "max_stamina_override",
				type = "numeric",
				default_value = 0,
                decimals_number = 0, 
				range = { 0, 100 },
        },
    },
	}
}