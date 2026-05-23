local mod = get_mod("stamina count ui")

return {
	name = "Stamina Count UI",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "show_mode",
				type = "dropdown",
				default_value = "always",
				options = {
					{ text = "show_mode_always", value = "always" },
					{ text = "show_mode_blocking", value = "blocking" }
				},
			},
			{
				setting_id = "show_prefix",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "display_recovery_delay",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "offset_x",
				type = "numeric",
				default_value = 0,
				range = { -960, 960 },
			},
			{
				setting_id = "offset_y",
				type = "numeric",
				default_value = -200,
				range = { -540, 540 },
			},
			{
				setting_id = "font_size",
				type = "numeric",
				default_value = 32,
				range = { 8, 128 },
			},
			{
				setting_id = "delay_font_size",
				type = "numeric",
				default_value = 24,
				range = { 8, 128 },
			},
		},
	},
}