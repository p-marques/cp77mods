// Eddies Received Multiplier by pMarK
// v1.1

module EddiesReceivedMult.Menu
import EddiesReceivedMult.Base.EddiesReceivedMult

public class EddiesReceivedMultWithMenu extends EddiesReceivedMult {
    private let menuSettings: ref<ERMMenuSettings>;

    protected func SetupSettings() -> Void {
        this.menuSettings = new ERMMenuSettings();
        ModSettings.RegisterListenerToClass(this.menuSettings); // Hard "Mod Settings" dependency
    }

    protected func GetIsEnabled() -> Bool {
        return this.menuSettings.IsEnabled;
    }

    protected func GetMultiplier() -> Float {
        return this.menuSettings.EddiesMultiplier;
    }

    protected func GetShowDebugMsg() -> Bool {
        return this.menuSettings.ShowDebugMsg;
    }

    protected func GetDebugMsgDuration() -> Float {
        return this.menuSettings.DebugMsgDuration;
    }
}

public class ERMMenuSettings {
    @runtimeProperty("ModSettings.mod", "Eddies Received Mult")
    @runtimeProperty("ModSettings.category", "Main")
    @runtimeProperty("ModSettings.displayName", "Enabled")
    @runtimeProperty("ModSettings.description", "Enable/Disable mod.")
    public let IsEnabled: Bool = true;

    @runtimeProperty("ModSettings.mod", "Eddies Received Mult")
    @runtimeProperty("ModSettings.category", "Main")
    @runtimeProperty("ModSettings.displayName", "Multiplier")
    @runtimeProperty("ModSettings.description", "Eddies received will be multiplied by this value.")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "0.1")
    @runtimeProperty("ModSettings.max", "5.0")
    public let EddiesMultiplier: Float = 1.0;

    @runtimeProperty("ModSettings.mod", "Eddies Received Mult")
    @runtimeProperty("ModSettings.category", "Debug")
    @runtimeProperty("ModSettings.displayName", "Show Debug Message")
    @runtimeProperty("ModSettings.description", "Enable/Disable the showing of a debug message every time you receive eddies.")
    public let ShowDebugMsg: Bool = false;

    @runtimeProperty("ModSettings.mod", "Eddies Received Mult")
    @runtimeProperty("ModSettings.category", "Debug")
    @runtimeProperty("ModSettings.displayName", "Message Duration")
    @runtimeProperty("ModSettings.description", "Duration of the debug message.")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "1.0")
    @runtimeProperty("ModSettings.max", "20.0")
    public let DebugMsgDuration: Float = 10.0;
}
