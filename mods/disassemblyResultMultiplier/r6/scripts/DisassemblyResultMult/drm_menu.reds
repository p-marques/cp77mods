// Disassembly Result Multiplier by pMarK
// v1.1

module DisassemblyResultMult.Menu
import DisassemblyResultMult.Base.DRM

public class DRMWithMenu extends DRM {
    private let menuSettings: ref<DRMSettings>;

    protected func SetupSettings() -> Void {
        this.menuSettings = new DRMSettings();
        ModSettings.RegisterListenerToClass(this.menuSettings); // Hard "Mod Settings" dependency
    }

    protected func GetIsEnabled() -> Bool {
        return this.menuSettings.IsEnabled;
    }

    protected func GetMaterialsBaseMultiplier() -> Float {
        return this.menuSettings.BaseMultiplier;
    }

    protected func GetMaterialsMultiplierCommon() -> Float {
        return this.menuSettings.MaterialsCommonMultiplier;
    }

    protected func GetMaterialsMultiplierUncommon() -> Float {
        return this.menuSettings.MaterialsUncommonMultiplier;
    }

    protected func GetMaterialsMultiplierRare() -> Float {
        return this.menuSettings.MaterialsRareMultiplier;
    }

    protected func GetMaterialsMultiplierEpic() -> Float {
        return this.menuSettings.MaterialsEpicMultiplier;
    }

    protected func GetMaterialsMultiplierLegendary() -> Float {
        return this.menuSettings.MaterialsLegendaryMultiplier;
    }

    protected func GetChanceToAddMaterialsOneQualityUp() -> Float {
        return this.menuSettings.ChanceToBumpQuality;
    }

    protected func GetShowDebugMsg() -> Bool {
        return this.menuSettings.ShowDebugMsg;
    }

    protected func GetDebugMessageDuration() -> Float {
        return this.menuSettings.DebugMsgDuration;
    }
}

public class DRMSettings {
    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Main")
    @runtimeProperty("ModSettings.displayName", "Enabled")
    @runtimeProperty("ModSettings.description", "Enable/Disable mod.")
    public let IsEnabled: Bool = true;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Main")
    @runtimeProperty("ModSettings.displayName", "Base Multiplier")
    @runtimeProperty("ModSettings.description", "The disassembly result is multiplied by this value FIRST.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "5.0")
    public let BaseMultiplier: Float = 1.0;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Main")
    @runtimeProperty("ModSettings.displayName", "Chance To Bump Quality")
    @runtimeProperty("ModSettings.description", "Chance to reveive materials that are one quality up of the disassembled item.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "1.0")
    public let ChanceToBumpQuality: Float = 0.0;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Quality Multipliers")
    @runtimeProperty("ModSettings.displayName", "Common Material Multiplier")
    @runtimeProperty("ModSettings.description", "Common materials are multiplied by this value AFTER the Base Multiplier.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "5.0")
    public let MaterialsCommonMultiplier: Float = 1.0;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Quality Multipliers")
    @runtimeProperty("ModSettings.displayName", "Uncommon Material Multiplier")
    @runtimeProperty("ModSettings.description", "Uncommon materials are multiplied by this value AFTER the Base Multiplier.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "5.0")
    public let MaterialsUncommonMultiplier: Float = 1.0;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Quality Multipliers")
    @runtimeProperty("ModSettings.displayName", "Rare Material Multiplier")
    @runtimeProperty("ModSettings.description", "Rare materials are multiplied by this value AFTER the Base Multiplier.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "5.0")
    public let MaterialsRareMultiplier: Float = 1.0;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Quality Multipliers")
    @runtimeProperty("ModSettings.displayName", "Epic Material Multiplier")
    @runtimeProperty("ModSettings.description", "Epic materials are multiplied by this value AFTER the Base Multiplier.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "5.0")
    public let MaterialsEpicMultiplier: Float = 1.0;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Quality Multipliers")
    @runtimeProperty("ModSettings.displayName", "Legendary Material Multiplier")
    @runtimeProperty("ModSettings.description", "Legendary materials are multiplied by this value AFTER the Base Multiplier.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "5.0")
    public let MaterialsLegendaryMultiplier: Float = 1.0;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Debug")
    @runtimeProperty("ModSettings.displayName", "Show Debug Message")
    @runtimeProperty("ModSettings.description", "Enable/Disable the showing of a debug message every time you disassemble an item.")
    public let ShowDebugMsg: Bool = false;

    @runtimeProperty("ModSettings.mod", "Disassembly Result Mult")
    @runtimeProperty("ModSettings.category", "Debug")
    @runtimeProperty("ModSettings.displayName", "Message Duration")
    @runtimeProperty("ModSettings.description", "Duration of the debug message.")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "20.0")
    public let DebugMsgDuration: Float = 10.0;
}
