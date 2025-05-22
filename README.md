# Compressor

![Version](https://img.shields.io/badge/version-Release%20Candidate-green)
![AMX Mod X](https://img.shields.io/badge/AMXX%201.9-Required-orange)

At its core, Compressor is nothing but a model replacement framework for servers. What makes it unique is that it was made with the objective of overcoming the 510 model resource limit while maintaining full functionality in servers. Compressor allows server operators to compress multiple model entries into a single one. Why unprecache shields in your CS1.6 server while you can use compressor to maintain full functionality?

## Features

Compressor works by intercepting model precaching and model setting calls, automatically substituting individual models with the respective entry in the configuration file. When a model that's configured for replacement is requested, the plugin:
1. Prevents the original model from being precached
2. Automatically loads the appropriate entry from the configuration file
3. Sets the correct body group, skin group, and colormap values (if they apply)

Just by installing Compressor with its vanilla settings servers can experience a huge imprevement on free precached model slots.

| Before Compressor    | After Compressor |
| -------- | ------- |
| ![Screenshot from 2025-05-21 22-32-09](https://github.com/user-attachments/assets/0663acb2-d32c-4be8-aaf1-65432fbade75)  | ![Screenshot from 2025-05-21 22-31-08](https://github.com/user-attachments/assets/40cc9a93-7431-4c2a-9a96-c24c2b726f79)    |






## Compatible Games
Compressor was made to be game agnostic. Although included configuration files only have support for two games:
- Half-Life
- Counter-Strike

Modders can give suport to any game assuming they can create the compressed .mdl file and the configuration entries for the game.

## Installation

1. Download the plugin and related files
2. Copy the files to the following directories:
   - `compressor.amxx` → `addons/amxmodx/plugins/`
   - Copy configuration files → `addons/amxmodx/configs/`:
     - `compressor_entities_[game].cfg`
     - `compressor_replacements_[game].cfg`
     - `compressor_muzzleflashes_[game].cfg` (optional)
   - Copy the needed .mdl files → `models/`:
     - `[game]_compressed_models.mdl`
     - `muzzle_heavy.mdl` (if it applies)
     - `muzzle_long.mdl` (if it applies)
     - `muzzle_short.mdl` (if it applies)
3. Add the plugin to your `plugins.ini` file:
```
compressor.amxx
```

## Configuration

### Entity Configuration Files

The entities configuration file (`compressor_entities_[game].cfg`) lists all weapon entities that the plugin should monitor for p_ model replacements. 

Example for Counter-Strike (`compressor_entities_cstrike.cfg`):
```ini
; List of weapon entity names for the game
; This will allow the plugin to properly set up the p_ model replacements
; Adding entities to this list other than weapons will cause problems
weapon_mp5navy
weapon_tmp
weapon_p90
weapon_mac10
weapon_ak47
weapon_sg552
weapon_m4a1
; ... additional weapons
```

### Replacement Configuration Files

The main configuration file (`compressor_replacements_[game].cfg`) defines which models should be replaced and their mapping to compressed model submodels.

Example for Counter-Strike (`compressor_replacements_cstrike.cfg`):
```ini
; This is the main file that handles model replacement.
; Any model in the list will be automatically replaced by the defined one.
; The original model will be removed from the precached resource files.
; When replacing a p_ model, you MUST add it to the compressor_entities.cfg file or else the server will crash.
; Do not replace a replacement model, bad things will happen because of recursion.
;
; The format is the following:
; [Original model to replace]                   [Model to replace with]                     [Submodel]          [Skingroup]         [Colormap]
"models/shield/p_shield_deagle.mdl"             "models/cstrike_compressed_models.mdl"      75                  0                   0
"models/shield/p_shield_fiveseven.mdl"          "models/cstrike_compressed_models.mdl"      77                  0                   0
"models/shield/p_shield_flashbang.mdl"          "models/cstrike_compressed_models.mdl"      78                  0                   0
"models/shield/p_shield_glock18.mdl"            "models/cstrike_compressed_models.mdl"      80                  0                   0
"models/shield/p_shield_hegrenade.mdl"          "models/cstrike_compressed_models.mdl"      78                  1                   0
"models/shield/p_shield_knife.mdl"              "models/cstrike_compressed_models.mdl"      94                  0                   0
"models/shield/p_shield_p228.mdl"               "models/cstrike_compressed_models.mdl"      86                  0                   0
"models/shield/p_shield_smokegrenade.mdl"       "models/cstrike_compressed_models.mdl"      78                  2                   0
"models/shield/p_shield_usp.mdl"                "models/cstrike_compressed_models.mdl"      92                  0                   0
"models/p_ak47.mdl"                             "models/cstrike_compressed_models.mdl"      1                   0                   0
"models/p_aug.mdl"                              "models/cstrike_compressed_models.mdl"      2                   0                   0
"models/p_awp.mdl"                              "models/cstrike_compressed_models.mdl"      3                   0                   0
"models/p_c4.mdl"                               "models/cstrike_compressed_models.mdl"      4                   0                   0
"models/p_deagle.mdl"                           "models/cstrike_compressed_models.mdl"      5                   0                   0
"models/p_elite.mdl"                            "models/cstrike_compressed_models.mdl"      6                   0                   0
; ... additional entries
```

Parameters:
- **Original model**: Path to the model being replaced
- **Replacement model**: Path to the compressed model file containing multiple submodels
- **Submodel**: Body group index within the compressed model
- **Skingroup**: Skin variation if it applies
- **Colormap**: Color mapping if it applies

### Muzzleflash Configuration Files (Optional)

This configuration is used in some games like Counter-Strike, where muzzleflash attachments are defined in p_ models themselves rather than player models, this file maps weapons to appropriate muzzleflash models.

Example (`compressor_muzzleflashes_cstrike.cfg`):
```
; This is an optional file.
; In games like Counter-Strike, the attachments where muzzleflashes appear are defined in the p_ models
; unlike games like Half-Life where all needed attachments are defined in the playermodel themselves.
;
; Default CS player models have two attachments, assumed to be for elites, more than enough to handle
; small firearm effects, for the rest we need to use fake p_ models to determine where the muzzleflash 
; will appear.
;
; This goes against Compressor objectives, but when pitting 3 possible p_ models vs the entire arsenal 
; the answer becomes clear.
;
; The format is the following:
; [Original model]                              [Muzzleflash model]
"models/p_ak47.mdl"                             "models/muzzle_long.mdl"
"models/p_aug.mdl"                              "models/muzzle_short.mdl"
"models/p_awp.mdl"                              "models/muzzle_long.mdl"
"models/p_famas.mdl"                            "models/muzzle_short.mdl"
"models/p_g3sg1.mdl"                            "models/muzzle_long.mdl"
"models/p_galil.mdl"                            "models/muzzle_long.mdl"
"models/p_m3.mdl"                               "models/muzzle_long.mdl"
"models/p_m3super90.mdl"                        "models/muzzle_long.mdl"    
"models/p_m4a1.mdl"                             "models/muzzle_long.mdl"
"models/p_m249.mdl"                             "models/muzzle_heavy.mdl"
"models/p_mp5.mdl"                              "models/muzzle_short.mdl"
"models/p_p90.mdl"                              "models/muzzle_short.mdl"
"models/p_scout.mdl"                            "models/muzzle_long.mdl"
"models/p_sg550.mdl"                            "models/muzzle_long.mdl"
"models/p_sg552.mdl"                            "models/muzzle_long.mdl"
"models/p_xm1014.mdl"                           "models/muzzle_heavy.mdl"
"models/p_m249.mdl"                             "models/muzzle_heavy.mdl"
```

## Compiler Options

The plugin includes compiler directives that can be modified before compilation:

```c
// Enable case-insensitive model name processing
// Fixes issues with inconsistent model name casing
// Increases overhead but improves compatibility
#define CASE_INSENSITIVE true
```

## API Reference

### Natives

```c
/**
 * Changes an entity's model with Compressor optimization support.
 * If the model is meant to be replaced, it will automatically change it.
 *
 * @param iEntity   Entity index to set the model for
 * @param szModel   Model path to set (e.g. "models/w_9mmAR.mdl")
 */
native Compressor_SetModel(const iEntity, const szModel[] = "")
```

### Forwards

```c
/**
 * Called when Compressor performs a model replacement on an entity,
 * allowing plugins to react to model changes.
 * 
 * @param iEntity    The entity index that had its model changed
 * @param szModel    The new model
 * 
 * @return           Return value is ignored
 */
forward Compressor_ModelChanged(const iEntity, const szModel[] = "")

/**
 * Called when Compressor performs a model replacement p_ model,
 * allowing plugins to react to model changes.
 * 
 * @param iEntity    The entity index (a weapon) that had its model changed
 * @param szModel    The new model 
 * 
 * @return           Return value is ignored
 */
forward Compressor_ModelChanged_P(const iEntity, const szModel[] = "")
```

## Incompatibilities
- BackWeapon Plugins (Any version) and SideWeapons by SoulWeaver16 
  - Currently incompatible with Compressor unless changes are made. Compressor will simply take priority and not show back weapons
- Any plugin changing an entity's model to a replaced model. 
  - These plugins require that any change of model goes through the `Compressor_SetModel()` native.
