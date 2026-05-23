return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`stamina show` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("stamina show", {
			mod_script       = "scripts/mods/stamina show/stamina show",
			mod_data         = "scripts/mods/stamina show/stamina show_data",
			mod_localization = "scripts/mods/stamina show/stamina show_localization",
		})
	end,
	packages = {
		"resource_packages/stamina show/stamina show",
	},
}
