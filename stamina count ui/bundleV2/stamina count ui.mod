return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`stamina count ui` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("stamina count ui", {
			mod_script       = "scripts/mods/stamina count ui/stamina count ui",
			mod_data         = "scripts/mods/stamina count ui/stamina count ui_data",
			mod_localization = "scripts/mods/stamina count ui/stamina count ui_localization",
		})
	end,
	packages = {
		"resource_packages/stamina count ui/stamina count ui",
	},
}
