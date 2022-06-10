// Disassembly Result Multiplier by pMarK
// v1.01

public class DisassemblyResultMultiplierMod {
    private let materialsMultiplierBase : Float;
    private let materialsMultiplierCommon : Float;
    private let materialsMultiplierUncommon : Float;
    private let materialsMultiplierRare : Float;
    private let materialsMultiplierEpic : Float;
    private let materialsMultiplierLegendary : Float;
    private let chanceToAddMaterialsOneQualityUp : Float;
    private let debuggingMode : Bool;
    private let quantitiesArray : array<Int32>;
    private let blackBoard : ref<IBlackboard>;

    public static func Init(opt notificationsBlackBoard : ref<IBlackboard>) -> ref<DisassemblyResultMultiplierMod> {
        let settings = new DisassemblyResultMultiplierMod();
        settings.blackBoard = notificationsBlackBoard;
        settings.debuggingMode = false;

        // ------ Settings Start ------

        // Base multiplier for all received materials.
        // Default = 1.0
        settings.materialsMultiplierBase = 1.0;

        // Common materials multiplier.
        // Default = 1.0;
        settings.materialsMultiplierCommon = 1.0;

        // Uncommon materials multiplier.
        // Default = 1.0;
        settings.materialsMultiplierUncommon = 1.0;

        // Rare materials multiplier.
        // Default = 1.0;
        settings.materialsMultiplierRare = 1.0;

        // Epic materials multiplier.
        // Default = 1.0;
        settings.materialsMultiplierEpic = 1.0;

        // Legendary materials multiplier.
        // Default = 1.0;
        settings.materialsMultiplierLegendary = 1.0;

        // Chance to reveive materials that are one quality up of the disassembled item.
        // The dice roll from that perk happens before this one. The chance in that perk is 0.15 (15%).
        // Default = 0.0;
        settings.chanceToAddMaterialsOneQualityUp = 0.0;

        // ------ Settings End ------

        return settings;
    }

    public func ModifyQuantities(out values : array<IngredientData>) -> Void {
        let i : Int32 = 0;
        let k : Int32;
        let size : Int32 = ArraySize(values);
        let tempQualityRecord : wref<Quality_Record>;
        let tempQualityType : gamedataQuality;

        if this.debuggingMode {
            ArrayClear(this.quantitiesArray);
            ArrayResize(this.quantitiesArray, 10);
        }

        while i < size {
            tempQualityRecord = values[i].id.Quality();
            tempQualityType = tempQualityRecord.Type();

            if this.debuggingMode {
                k = this.GetQuantitiesArrayIndexByQuality(tempQualityType);
                this.quantitiesArray[k] = values[i].quantity;
            }

            values[i].quantity = this.GetModifiedQuantity(values[i].quantity, tempQualityType);

            if this.debuggingMode {
                this.quantitiesArray[k + 1] = values[i].quantity;
            }

            i += 1;
        }

        if this.debuggingMode {
            this.ShowMessage(this.GetDebugMessage());
        }
    }

    public func GetShouldAddMaterialOneQualityUp(itemQual : gamedataQuality) -> Bool {
        let result : Bool = false;

        if NotEquals(itemQual, gamedataQuality.Invalid) && itemQual <= gamedataQuality.Epic {
            result = RandF() < this.chanceToAddMaterialsOneQualityUp;
        }

        return result;
    }

    private func GetModifiedQuantity(quantity : Int32, qualityType : gamedataQuality) -> Int32 {
        let quantityFloat : Float = Cast(quantity);

        quantityFloat *= this.materialsMultiplierBase;

        switch qualityType {
            case gamedataQuality.Uncommon:
                quantityFloat *= this.materialsMultiplierUncommon;
                break;
            case gamedataQuality.Rare:
                quantityFloat *= this.materialsMultiplierRare;
                break;
            case gamedataQuality.Epic:
                quantityFloat *= this.materialsMultiplierEpic;
                break;
            case gamedataQuality.Legendary:
                quantityFloat *= this.materialsMultiplierLegendary;
                break;
            default:
                quantityFloat *= this.materialsMultiplierCommon;
        }

        if quantityFloat < 1.0 {
            quantityFloat = 1.0;
        }

        return RoundMath(quantityFloat);
    }

    private func GetQuantitiesArrayIndexByQuality(qualityType : gamedataQuality) -> Int32 {
        switch qualityType {
            case gamedataQuality.Uncommon:
                return 2;
            case gamedataQuality.Rare:
                return 4;
            case gamedataQuality.Epic:
                return 6;
            case gamedataQuality.Legendary:
                return 8;
            default:
                return 0;
        }
    }

    private func GetDebugMessage() -> String {
        let i : Int32 = 0;
        let result : String;

        while i < 10 {
            if this.quantitiesArray[i] > 0 || this.quantitiesArray[i] > 0 {
                result += this.GetQualityInitialByQuantitiesIndex(i) + "[" + ToString(this.quantitiesArray[i]) + ":" + ToString(this.quantitiesArray[i + 1]) + "] ";
            }

            i += 2;
        }

        return result;
    }

    private func GetQualityInitialByQuantitiesIndex(index : Int32) -> String {
        switch index {
            case 0:
                return "C";
            case 2:
                return "U";
            case 4:
                return "R";
            case 6:
                return "E";
            case 8:
                return "L";
            default:
                return "ERR";
        }
    }

    private func ShowMessage(message : String) -> Void {
        let warningMsg: SimpleScreenMessage;
        warningMsg.isShown = true;
        warningMsg.duration = 10.00;
        warningMsg.message = message;
        this.blackBoard.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warningMsg), true);
    }
}

@addField(CraftingSystem)
private let disassemblyResultMultiplierMod : ref<DisassemblyResultMultiplierMod>;

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

    if this.disassemblyResultMultiplierMod == null {
        this.disassemblyResultMultiplierMod = DisassemblyResultMultiplierMod.Init(GameInstance.GetBlackboardSystem(this.m_callback.player.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications));
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
