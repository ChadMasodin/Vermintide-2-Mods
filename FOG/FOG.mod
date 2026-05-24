return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`FOG` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("FOG", {
			mod_script       = "scripts/mods/FOG/FOG",
			mod_data         = "scripts/mods/FOG/FOG_data",
			mod_localization = "scripts/mods/FOG/FOG_localization",
		})
	end,
	packages = {
		"resource_packages/FOG/FOG",
	},
}
