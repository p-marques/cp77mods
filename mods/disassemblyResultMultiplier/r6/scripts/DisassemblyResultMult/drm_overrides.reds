// Disassembly Result Multiplier by pMarK
// v1.1

module DisassemblyResultMult.Overrides
import DisassemblyResultMult.Base.DRM

@if(ModuleExists("DisassemblyResultMult.Menu"))
import DisassemblyResultMult.Menu.DRMWithMenu

@addField(CraftingSystem)
private let disassemblyResultMultiplierMod : ref<DRM>;

@replaceMethod(CraftingSystem)
public final const func GetDisassemblyResultItems(target: wref<GameObject>, itemID: ItemID, amount: Int32, out restoredAttachments: array<ItemAttachments>, opt calledFromUI: Bool) -> array<IngredientData> {
    let finalResult: array<IngredientData>;
    let i: Int32;
    let ingredients: array<wref<RecipeElement_Record>>;
    let itemData: wref<gameItemData>;
    let itemQual: gamedataQuality;
    let j: Int32;
    let newIngrData: IngredientData;
    let outResult: array<IngredientData>;
    let itemType: gamedataItemType = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)).ItemType().Type();
    let dissResult: wref<DisassemblingResult_Record> = TweakDBInterface.GetDisassemblingResultRecord(t"Crafting." + TDBID.Create(EnumValueToString("gamedataItemType", Cast(EnumInt(itemType)))));
    dissResult.Ingredients(ingredients);
    itemData = GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemData(target, itemID);
    itemQual = RPGManager.GetItemQuality(itemData);
    i = 0;
    while i < amount {
        ArrayClear(outResult);
        j = 0;
        while j < ArraySize(ingredients) {
            newIngrData = this.CreateIngredientData(ingredients[j]);
            this.AddIngredientToResult(newIngrData, outResult);
            j += 1;
        };
        if itemQual >= gamedataQuality.Uncommon {
            newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(gamedataQuality.Uncommon), 1);
            this.AddIngredientToResult(newIngrData, outResult);
        };
        if itemQual >= gamedataQuality.Rare {
            newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(gamedataQuality.Rare), 1);
            this.AddIngredientToResult(newIngrData, outResult);
            newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(gamedataQuality.Rare, true), 1);
            this.AddIngredientToResult(newIngrData, outResult);
        };
        if itemQual >= gamedataQuality.Epic {
            newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(gamedataQuality.Epic), 1);
            this.AddIngredientToResult(newIngrData, outResult);
            newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(gamedataQuality.Epic, true), 1);
            this.AddIngredientToResult(newIngrData, outResult);
        };
        if itemQual >= gamedataQuality.Legendary {
            newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(gamedataQuality.Legendary), 1);
            this.AddIngredientToResult(newIngrData, outResult);
            newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(gamedataQuality.Legendary, true), 1);
            this.AddIngredientToResult(newIngrData, outResult);
        };
        this.ProcessDisassemblingPerks(outResult, itemData, restoredAttachments, calledFromUI);
        this.MergeIngredients(outResult, finalResult);
        i += 1;
    };

    if !IsDefined(this.disassemblyResultMultiplierMod) {
        this.InitializeDisassemblyResultMultiplier();
        this.disassemblyResultMultiplierMod.Setup(GameInstance.GetBlackboardSystem(this.m_callback.player.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications));
    }

    if !calledFromUI && this.disassemblyResultMultiplierMod.GetShouldAddMaterialOneQualityUp(itemQual) {
        itemQual = RPGManager.GetBumpedQuality(itemQual);

        newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(itemQual), 1);
        this.AddIngredientToResult(newIngrData, outResult);

        newIngrData = this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(itemQual, true), 1);
        this.AddIngredientToResult(newIngrData, outResult);

        this.MergeIngredients(outResult, finalResult);
    }

    this.disassemblyResultMultiplierMod.ModifyQuantities(finalResult);

    return finalResult;
}

@if(ModuleExists("DisassemblyResultMult.Menu"))
@addMethod(CraftingSystem)
private func InitializeDisassemblyResultMultiplier() -> Void {
  this.disassemblyResultMultiplierMod = new DRMWithMenu();
}
@if(!ModuleExists("DisassemblyResultMult.Menu"))
@addMethod(CraftingSystem)
private func InitializeDisassemblyResultMultiplier() -> Void {
  this.disassemblyResultMultiplierMod = new DRM();
}
