#if defined _compressor_included
	#endinput
#endif
#define _compressor_included

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

/**
 * Changes an entity's model with Compressor optimization support.
 * If the model is meant to be replaced, it will automatically change it.
 *
 * @param iEntity   Entity index to set the model for
 * @param szModel   Model path to set (e.g. "models/w_9mmAR.mdl")
 */
native Compressor_SetModel(const iEntity, const szModel[] = "")