return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Gromril Fart SFX` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Gromril Fart SFX", {
			mod_script       = "scripts/mods/Gromril Fart SFX/Gromril Fart SFX",
			mod_data         = "scripts/mods/Gromril Fart SFX/Gromril Fart SFX_data",
			mod_localization = "scripts/mods/Gromril Fart SFX/Gromril Fart SFX_localization",
		})
	end,
	packages = {
		"resource_packages/Gromril Fart SFX/Gromril Fart SFX",
	},
}
