#include <amxmodx>

#if AMXX_VERSION_NUM < 183
#assert "AMX Mod X versions 1.8.2 and below are not supported."
#endif

#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

// ** COMPILER OPTIONS **
// Adjust as needed

// Enable if you want Compressor to process model names case insensitively
// Increases overhead
// Fixes instances of people cHaNgInG cAsEs because they were being funni or careless
// Fixes the case where the plugin would fail to recognize HLDM's MP5 models (9mmAR) < AR with upper case
#define CASE_INSENSITIVE   			true

// ** COMPILER OPTIONS END HERE **

#define PLUGIN_NAME         		"Compressor"
#define PLUGIN_VERSION      		"RC-25w21b"
#define PLUGIN_AUTHOR       		"szGabu"

#define TINY_STRING_LENGTH			8

#define pev_originalweaponmodel		pev_noise3

enum _:ReplacementData
{
	ReplacementModel[PLATFORM_MAX_PATH],
	ReplacementBodyGroup,
	ReplacementSkinGroup,
	ReplacementColorMap
};

new Trie:g_rgReplacements;
new Trie:g_rgMuzzleFlashes;
new Array:g_rgEntities;

new bool:g_bPostPrecache = false;

new g_hSetModelPForward = INVALID_HANDLE;
new g_hSetModelForward = INVALID_HANDLE;

public plugin_precache()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	if(LoadConfig())
	{
		register_forward(FM_PrecacheModel, "Forward_PrecacheModel_Pre");
		register_forward(FM_SetModel, "Forward_SetModel_Pre");
	}
}

public plugin_init()
{
	g_bPostPrecache = true;
	
	for(new iCursor = 0; iCursor < ArraySize(g_rgEntities); iCursor++)
	{
		new szClassName[MAX_NAME_LENGTH];
		ArrayGetString(g_rgEntities, iCursor, szClassName, charsmax(szClassName));

		if(equali(szClassName, "weapon_", 7))
		{
			RegisterHam(Ham_Item_Deploy, szClassName, "Event_CompressorItem_ItemDeploy_Post", true);
			RegisterHam(Ham_Weapon_PrimaryAttack, szClassName, "Event_CompressorItem_WeaponPrimaryAttack_Post", true);
			RegisterHam(Ham_Weapon_SecondaryAttack, szClassName, "Event_CompressorItem_WeaponSecondaryAttack_Post", true);
			RegisterHam(Ham_Item_AttachToPlayer, szClassName, "Event_CompressorItem_ItemAttachToPlayer_Post", true);
			RegisterHam(Ham_Weapon_WeaponIdle, szClassName, "Event_CompressorItem_WeaponWeaponIdle_Post", true);
			
			RegisterHam(Ham_Item_Holster, szClassName, "Event_CompressorItem_ItemHolster_Post", true);
		}
	}

	g_hSetModelPForward = CreateMultiForward("Compressor_ModelChanged_P", ET_IGNORE, FP_CELL, FP_STRING);
	g_hSetModelForward = CreateMultiForward("Compressor_ModelChanged", ET_IGNORE, FP_CELL, FP_STRING);
}

public OnConfigsExecuted()
{
	create_cvar("amx_compressor_version", PLUGIN_VERSION, FCVAR_SERVER);
	server_print("[NOTICE] %s::OnConfigsExecuted() - %s is free to download and distribute! If you paid for this plugin YOU GOT SCAMMED. Visit https://github.com/szGabu for all my plugins.", __BINARY__, PLUGIN_NAME);
}

public plugin_natives()
{
	register_library("compressor");
	register_native("Compressor_SetModel", "API_SetModel");
}

public bool:LoadConfig()
{
	new szCompressorReplacementConfigFile[PLATFORM_MAX_PATH];
	new szCompressorEntitiesConfigFile[PLATFORM_MAX_PATH];
	new szConfigsDir[PLATFORM_MAX_PATH];

	get_configsdir(szConfigsDir, charsmax(szConfigsDir));

	// Entities, try with Custom first
	formatex(szCompressorEntitiesConfigFile, charsmax(szCompressorEntitiesConfigFile), "%s/compressor_entities_custom.cfg", szConfigsDir);

	if(!file_exists(szCompressorEntitiesConfigFile))
	{
		new szModName[MAX_NAME_LENGTH];
		get_modname(szModName, charsmax(szModName));
		formatex(szCompressorEntitiesConfigFile, charsmax(szCompressorEntitiesConfigFile), "%s/compressor_entities_%s.cfg", szConfigsDir, szModName);

		if(!file_exists(szCompressorEntitiesConfigFile))
			set_fail_state("Entity file for Compressor missing.");
	}

	new iFileHandle = fopen(szCompressorEntitiesConfigFile, "rt");
	if(!iFileHandle)
		set_fail_state("Could not open Entity file for Compressor.");

	g_rgEntities = ArrayCreate(MAX_NAME_LENGTH);

	new szLine[512];

	new szEntity[MAX_NAME_LENGTH];

	while(!feof(iFileHandle))
	{
		fgets(iFileHandle, szLine, charsmax(szLine));

		trim(szLine);
		
		// Skip comments and empty lines
		if(szLine[0] == ';' || szLine[0] == '/' || szLine[0] == 0 || strlen(szLine) == 0)
			continue;

		parse(szLine, szEntity, charsmax(szEntity));

		//hamsandwich is case sensitive, we don't want to mess around with this

		if(strlen(szEntity) > 0)
			ArrayPushString(g_rgEntities, szEntity);
	}

	if(ArraySize(g_rgEntities) == 0)
		set_fail_state("No entities were registered.");

	fclose(iFileHandle);

	// Replacements, try with Custom first
	formatex(szCompressorReplacementConfigFile, charsmax(szCompressorReplacementConfigFile), "%s/compressor_replacements_custom.cfg", szConfigsDir);

	if(!file_exists(szCompressorReplacementConfigFile))
	{
		new szModName[MAX_NAME_LENGTH];
		get_modname(szModName, charsmax(szModName));
		formatex(szCompressorReplacementConfigFile, charsmax(szCompressorReplacementConfigFile), "%s/compressor_replacements_%s.cfg", szConfigsDir, szModName);

		if(!file_exists(szCompressorReplacementConfigFile))
			set_fail_state("Configuration file for Compressor missing.");
	}

	iFileHandle = fopen(szCompressorReplacementConfigFile, "rt");
	if(!iFileHandle)
		set_fail_state("Could not open Configuration file for Compressor.");

	g_rgReplacements = TrieCreate();

	new szModel[PLATFORM_MAX_PATH], szReplacement[PLATFORM_MAX_PATH], szBodyGroup[TINY_STRING_LENGTH], szSkinGroup[TINY_STRING_LENGTH], szColorMap[TINY_STRING_LENGTH];

	while(!feof(iFileHandle))
	{
		fgets(iFileHandle, szLine, charsmax(szLine));

		trim(szLine);
		
		// Skip comments and empty lines
		if(szLine[0] == ';' || szLine[0] == '/' || szLine[0] == 0 || strlen(szLine) == 0)
			continue;

		parse(szLine, szModel, charsmax(szModel), szReplacement, charsmax(szReplacement), szBodyGroup, charsmax(szBodyGroup), szSkinGroup, charsmax(szSkinGroup), szColorMap, charsmax(szColorMap));

		#if CASE_INSENSITIVE
		strtolower(szModel);
		strtolower(szReplacement);
		#endif

		if(file_exists(szModel, true) && file_exists(szReplacement, true))
		{
			precache_model(szReplacement);
			new rgData[ReplacementData];
			copy(rgData[ReplacementModel], PLATFORM_MAX_PATH, szReplacement);
			rgData[ReplacementBodyGroup] = str_to_num(szBodyGroup);
			rgData[ReplacementSkinGroup] = str_to_num(szSkinGroup);
			rgData[ReplacementColorMap] = str_to_num(szColorMap);
			TrieSetArray(g_rgReplacements, szModel, rgData, sizeof rgData, true);
		}
		else if(!file_exists(szModel, true))
			server_print("[WARNING] Trying to replace model %s but it doesn't exist", szModel);
		else if(!file_exists(szReplacement, true))
			server_print("[WARNING] Trying to replace model %s but its replacement %s doesn't exist", szModel, szReplacement);
	}

	fclose(iFileHandle);

	// Muzzleflash fake models, this one is optional and the plugin can work if none is found
	formatex(szCompressorReplacementConfigFile, charsmax(szCompressorReplacementConfigFile), "%s/compressor_muzzleflashes_custom.cfg", szConfigsDir);

	if(!file_exists(szCompressorReplacementConfigFile))
	{
		new szModName[MAX_NAME_LENGTH];
		get_modname(szModName, charsmax(szModName));
		formatex(szCompressorReplacementConfigFile, charsmax(szCompressorReplacementConfigFile), "%s/compressor_muzzleflashes_%s.cfg", szConfigsDir, szModName);
	}

	if(file_exists(szCompressorReplacementConfigFile))
	{
		iFileHandle = fopen(szCompressorReplacementConfigFile, "rt");
		if(iFileHandle)
		{
			g_rgMuzzleFlashes = TrieCreate();

			new szModel[PLATFORM_MAX_PATH], szMuzzle[PLATFORM_MAX_PATH];

			while(!feof(iFileHandle))
			{
				fgets(iFileHandle, szLine, charsmax(szLine));

				trim(szLine);
				
				// Skip comments and empty lines
				if(szLine[0] == ';' || szLine[0] == '/' || szLine[0] == 0 || strlen(szLine) == 0)
					continue;

				parse(szLine, szModel, charsmax(szModel), szMuzzle, charsmax(szMuzzle));

				#if CASE_INSENSITIVE
				strtolower(szModel);
				strtolower(szMuzzle);
				#endif

				if(file_exists(szModel, true) && file_exists(szMuzzle, true))
				{
					precache_model(szMuzzle);
					TrieSetString(g_rgMuzzleFlashes, szModel, szMuzzle, true);
				}
				else if(!file_exists(szModel, true))
					server_print("[WARNING] Trying to assign a muzzleflash to %s but it doesn't exist", szModel);
				else if(!file_exists(szMuzzle, true))
					server_print("[WARNING] Trying to assign a muzzleflash to %s but its intended model %s doesn't exist", szModel, szMuzzle);
			}

			fclose(iFileHandle);
		}
	}

	return true;
}

public Forward_PrecacheModel_Pre(const szModel[])
{
	#if CASE_INSENSITIVE
	new szLowerModel[PLATFORM_MAX_PATH];
	copy(szLowerModel, charsmax(szLowerModel), szModel);
	strtolower(szLowerModel);
	#endif
	if(g_bPostPrecache)
		return FMRES_SUPERCEDE;
	else
	{
		#if CASE_INSENSITIVE
		if(TrieKeyExists(g_rgReplacements, szLowerModel))
		#else 
		if(TrieKeyExists(g_rgReplacements, szModel))
		#endif
		{
			forward_return(FMV_CELL, 0)
			return FMRES_SUPERCEDE;
		}

		return FMRES_IGNORED;
	}
}  

public Forward_SetModel_Pre(iEntity, const szModel[])
{
	#if CASE_INSENSITIVE
	new szLowerModel[PLATFORM_MAX_PATH];
	copy(szLowerModel, charsmax(szLowerModel), szModel);
	strtolower(szLowerModel);

	server_print("trying to set model %s", szLowerModel);

	if(TrieKeyExists(g_rgReplacements, szLowerModel))
	#else
	if(TrieKeyExists(g_rgReplacements, szModel))
	#endif
	{
		new rgData[ReplacementData];
		#if CASE_INSENSITIVE
		TrieGetArray(g_rgReplacements, szLowerModel, rgData, sizeof rgData);
		#else
		TrieGetArray(g_rgReplacements, szModel, rgData, sizeof rgData);
		#endif
		
		engfunc(EngFunc_SetModel, iEntity, rgData[ReplacementModel]);

		ExecuteForward(g_hSetModelForward, _, iEntity, rgData[ReplacementModel]);

		set_pev(iEntity, pev_body, rgData[ReplacementBodyGroup]);
		set_pev(iEntity, pev_skin, rgData[ReplacementSkinGroup]);
		set_pev(iEntity, pev_colormap, rgData[ReplacementColorMap]);

		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE;
	}
	else
		return FMRES_IGNORED;
}

public Event_CompressorItem_ItemHolster_Post(iWeapon)
{
	set_pev(iWeapon, pev_model, NULL_STRING);
	set_pev(iWeapon, pev_body, 0);
	set_pev(iWeapon, pev_skin, 0);
	set_pev(iWeapon, pev_colormap, 0);
	SetItemVisibility(iWeapon, false);
}

public Event_CompressorItem_ItemDeploy_Post(iWeapon)
{
	CheckPlayerModel(iWeapon);
}

public Event_CompressorItem_WeaponPrimaryAttack_Post(iWeapon)
{
	CheckPlayerModel(iWeapon);
}

public Event_CompressorItem_WeaponSecondaryAttack_Post(iWeapon)
{
	CheckPlayerModel(iWeapon);
}

public Event_CompressorItem_WeaponWeaponIdle_Post(iWeapon)
{
	CheckPlayerModel(iWeapon);
}

public Event_CompressorItem_Think_Post(iWeapon)
{
	CheckPlayerModel(iWeapon);
}

public Event_CompressorItem_ItemAttachToPlayer_Post(iWeapon, iClient)
{
	CheckPlayerModel(iWeapon);
}

CheckPlayerModel(iWeapon)
{
	//current code is a mess, might need a refactor
	//but only this way I could achieve the desired functionality
	//keeping in mind that some p_ change dynamically, not on deploy (satchel charges, etc)
	if(pev_valid(iWeapon) == 2)
	{
		new bool:bFirstChange = false;
		new iClient = get_ent_data_entity(iWeapon, "CBasePlayerItem", "m_pPlayer");
		new szWeaponPlayerModel[PLATFORM_MAX_PATH];
		pev(iWeapon, pev_originalweaponmodel, szWeaponPlayerModel, charsmax(szWeaponPlayerModel));

		if(strlen(szWeaponPlayerModel) == 0)
		{
			pev(iClient, pev_weaponmodel2, szWeaponPlayerModel, charsmax(szWeaponPlayerModel));
			bFirstChange = true;
		}

		#if CASE_INSENSITIVE
		strtolower(szWeaponPlayerModel);
		#endif

		if(strlen(szWeaponPlayerModel) > 0 && TrieKeyExists(g_rgReplacements, szWeaponPlayerModel))
		{
			new rgData[ReplacementData];
			TrieGetArray(g_rgReplacements, szWeaponPlayerModel, rgData, sizeof rgData);

			//store weapon model, we can reuse this if needed
			set_pev(iWeapon, pev_originalweaponmodel, szWeaponPlayerModel);

			engfunc(EngFunc_SetModel, iWeapon, rgData[ReplacementModel]);
			set_pev(iWeapon, pev_body, rgData[ReplacementBodyGroup]);
			set_pev(iWeapon, pev_skin, rgData[ReplacementSkinGroup]);
			set_pev(iWeapon, pev_colormap, rgData[ReplacementColorMap]);


			if(0 < iClient <= MaxClients)
			{
				if(g_rgMuzzleFlashes && TrieKeyExists(g_rgMuzzleFlashes, szWeaponPlayerModel))
				{
					new szMuzzleFlash[PLATFORM_MAX_PATH];
					TrieGetString(g_rgMuzzleFlashes, szWeaponPlayerModel, szMuzzleFlash, charsmax(szMuzzleFlash));
					set_pev(iClient, pev_weaponmodel2, szMuzzleFlash);
				}
				else
					set_pev(iClient, pev_weaponmodel2, "");
			}

			if(bFirstChange)
				ExecuteForward(g_hSetModelPForward, _, iWeapon, rgData[ReplacementModel]);
			
			SetItemVisibility(iWeapon, true);
		}
	}
}

stock SetItemVisibility(iEntity, bool:bVisible = true) 
{
	set_pev(iEntity, pev_effects, bVisible ? pev(iEntity, pev_effects) & ~EF_NODRAW : pev(iEntity, pev_effects) | EF_NODRAW)
}

public API_SetModel(iPlugin, iParams)
{
	new szModel[PLATFORM_MAX_PATH];

	new iEntity = get_param(1);
	get_string(2, szModel, charsmax(szModel));

	#if CASE_INSENSITIVE
	strtolower(szModel);
	#endif

	if(TrieKeyExists(g_rgReplacements, szModel))
	{
		new rgData[ReplacementData];
		TrieGetArray(g_rgReplacements, szModel, rgData, sizeof rgData);
		
		engfunc(EngFunc_SetModel, iEntity, rgData[ReplacementModel]);
		set_pev(iEntity, pev_body, rgData[ReplacementBodyGroup]);
		set_pev(iEntity, pev_skin, rgData[ReplacementSkinGroup]);
		set_pev(iEntity, pev_colormap, rgData[ReplacementColorMap]);
	}
	else
		engfunc(EngFunc_SetModel, iEntity, szModel);
}