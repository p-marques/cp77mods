// Disassembly Result Multiplier by pMarK
// v1.1

module DisassemblyResultMult.Base

public class DRM {
    private let materialsMultiplierBase: Float;
    private let materialsMultiplierCommon: Float;
    private let materialsMultiplierUncommon: Float;
    private let materialsMultiplierRare: Float;
    private let materialsMultiplierEpic: Float;
    private let materialsMultiplierLegendary: Float;
    private let chanceToAddMaterialsOneQualityUp: Float;
    private let debugMode: Bool;
    private let debugMsgDuration: Float;
    private let quantitiesArray: array<Int32>;
    private let blackBoard: ref<IBlackboard>;

    public func Setup(notificationsBlackBoard : ref<IBlackboard>) -> Void {
        this.blackBoard = notificationsBlackBoard;
        this.SetupSettings();
    }

    protected func SetupSettings() -> Void {
        // ------ Settings Start ------
        this.debugMode = false;
        this.debugMsgDuration = 10.0;

        // Base multiplier for all received materials.
        // Default = 1.0
        this.materialsMultiplierBase = 1.0;

        // Common materials multiplier.
        // Default = 1.0;
        this.materialsMultiplierCommon = 1.0;

        // Uncommon materials multiplier.
        // Default = 1.0;
        this.materialsMultiplierUncommon = 1.0;

        // Rare materials multiplier.
        // Default = 1.0;
        this.materialsMultiplierRare = 1.0;

        // Epic materials multiplier.
        // Default = 1.0;
        this.materialsMultiplierEpic = 1.0;

        // Legendary materials multiplier.
        // Default = 1.0;
        this.materialsMultiplierLegendary = 1.0;

        // Chance to reveive materials that are one quality up of the disassembled item.
        // The dice roll from that perk happens before this one. The chance in that perk is 0.15 (15%).
        // Default = 0.0;
        this.chanceToAddMaterialsOneQualityUp = 0.0;

        // ------ Settings End ------
    }

    public func ModifyQuantities(out values : array<IngredientData>) -> Void {
        let i: Int32 = 0;
        let k: Int32;
        let size: Int32 = ArraySize(values);
        let tempQualityRecord: wref<Quality_Record>;
        let tempQualityType: gamedataQuality;
        let debugFlag: Bool = this.GetShowDebugMsg();

        if !this.GetIsEnabled() {
            return;
        }

        if debugFlag {
            ArrayClear(this.quantitiesArray);
            ArrayResize(this.quantitiesArray, 10);
        }

        while i < size {
            tempQualityRecord = values[i].id.Quality();
            tempQualityType = tempQualityRecord.Type();

            if debugFlag {
                k = this.GetQuantitiesArrayIndexByQuality(tempQualityType);
                this.quantitiesArray[k] = values[i].quantity;
            }

            values[i].quantity = this.GetModifiedQuantity(values[i].quantity, tempQualityType);

            if debugFlag {
                this.quantitiesArray[k + 1] = values[i].quantity;
            }

            i += 1;
        }

        if debugFlag {
            this.ShowMessage(this.GetDebugMessage());
        }
    }

    protected func GetIsEnabled() -> Bool {
        return true;
    }

    protected func GetMaterialsBaseMultiplier() -> Float {
        return this.materialsMultiplierBase;
    }

    protected func GetMaterialsMultiplierCommon() -> Float {
        return this.materialsMultiplierCommon;
    }

    protected func GetMaterialsMultiplierUncommon() -> Float {
        return this.materialsMultiplierUncommon;
    }

    protected func GetMaterialsMultiplierRare() -> Float {
        return this.materialsMultiplierRare;
    }

    protected func GetMaterialsMultiplierEpic() -> Float {
        return this.materialsMultiplierEpic;
    }

    protected func GetMaterialsMultiplierLegendary() -> Float {
        return this.materialsMultiplierLegendary;
    }

    protected func GetChanceToAddMaterialsOneQualityUp() -> Float {
        return this.chanceToAddMaterialsOneQualityUp;
    }

    protected func GetShowDebugMsg() -> Bool {
        return this.debugMode;
    }

    protected func GetDebugMessageDuration() -> Float {
        return this.debugMsgDuration;
    }

    public func GetShouldAddMaterialOneQualityUp(itemQual : gamedataQuality) -> Bool {
        let result: Bool = false;

        if NotEquals(itemQual, gamedataQuality.Invalid) && itemQual <= gamedataQuality.Epic {
            result = RandF() < this.GetChanceToAddMaterialsOneQualityUp();
        }

        return result;
    }

    private func GetModifiedQuantity(quantity : Int32, qualityType : gamedataQuality) -> Int32 {
        let quantityFloat: Float = Cast(quantity);

        quantityFloat *= this.GetMaterialsBaseMultiplier();

        switch qualityType {
            case gamedataQuality.Uncommon:
                quantityFloat *= this.GetMaterialsMultiplierUncommon();
                break;
            case gamedataQuality.Rare:
                quantityFloat *= this.GetMaterialsMultiplierRare();
                break;
            case gamedataQuality.Epic:
                quantityFloat *= this.GetMaterialsMultiplierEpic();
                break;
            case gamedataQuality.Legendary:
                quantityFloat *= this.GetMaterialsMultiplierLegendary();
                break;
            default:
                quantityFloat *= this.GetMaterialsMultiplierCommon();
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
        let i: Int32 = 0;
        let result: String;

        while i < 10 {
            result += this.GetQualityNameByQuantitiesIndex(i) + " [" + ToString(this.quantitiesArray[i]) + " -> " + ToString(this.quantitiesArray[i + 1]) + "] ";

            i += 2;
        }

        return result;
    }

    private func GetQualityNameByQuantitiesIndex(index : Int32) -> String {
        switch index {
            case 0:
                return "Common";
            case 2:
                return "Uncommon";
            case 4:
                return "Rare";
            case 6:
                return "Epic";
            case 8:
                return "Legendary";
            default:
                return "ERR";
        }
    }

    private func ShowMessage(message : String) -> Void {
        let warningMsg: SimpleScreenMessage;
        warningMsg.isShown = true;
        warningMsg.duration = this.GetDebugMessageDuration();
        warningMsg.message = message;
        this.blackBoard.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warningMsg), true);
    }
}
