// Eddies Received Multiplier by pMarK
// v1.1

module EddiesReceivedMult.Base

public class EddiesReceivedMult {
  private let multiplier: Float;
  private let player: wref<PlayerPuppet>;
  private let transactionSystem: ref<TransactionSystem>;
  private let blackboard: ref<IBlackboard>;
  private let flag: Bool;
  private let debugMode: Bool;

  public func Setup(player: wref<PlayerPuppet>) -> Void {
    this.player = player;
    this.transactionSystem = GameInstance.GetTransactionSystem(player.GetGame());
    this.blackboard = GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications);
    this.SetupSettings();
  }

  protected func SetupSettings() -> Void {
    // ------ Settings Start ------

    this.debugMode = false; // Show debug message every time the player receives eddies.
    this.multiplier = 1.0;

    // ------ Settings End ------
  }

  public func DeltaEddies(itemDataQuantity: Int32, currentQuantity: Int32) -> Void {
    let originalValue: Int32;
    let newTotalValue: Int32;
    let delta: Int32;
    let msg: String;
    let multValue: Float = this.GetMultiplier();

    if this.ShouldDeltaEddies(multValue) {
      originalValue = itemDataQuantity - currentQuantity;
      newTotalValue = Cast<Int32>(Cast<Float>(originalValue) * multValue);
      delta = newTotalValue - originalValue;

      if originalValue == 0 {
        // For some reason the game invokes 0 eddies received events.
        // I noticed this when fighting enemies with bounties. At every kill a 0 eddie event is consumed.
        // You actually get the total money when the fight is over.
        return;
      }

      if delta < 0 {
        this.transactionSystem.RemoveItem(this.player, MarketSystem.Money(), -delta);
      }
      else {
        this.transactionSystem.GiveItem(this.player, MarketSystem.Money(), delta);

        this.flag = true;
      }

      if this.GetShowDebugMsg() {
        msg = "Original value: " + originalValue + "\\n" + "New total: " + newTotalValue + "\\n" + "Delta: " + delta + "\\n" + "Multiplier: " + Cast<Int32>(multValue * 100.0) + "%";

        this.ShowMessage(msg);
      }
    }
    else {
      this.flag = false;
    }
  }

  protected func GetIsEnabled() -> Bool {
    return true;
  }

  protected func GetMultiplier() -> Float {
    return this.multiplier;
  }

  protected func GetShowDebugMsg() -> Bool {
    return this.debugMode;
  }

  protected func GetDebugMsgDuration() -> Float {
    return 12.0;
  }

  private func ShouldDeltaEddies(multiplier: Float) -> Bool {
    if multiplier == 1.0 || multiplier < 0.0 {
      return false;
    }

    return !this.flag && this.GetIsEnabled();
  }

  protected func ShowMessage(message : String) -> Void {
    let warningMsg: SimpleScreenMessage;
    warningMsg.isShown = true;
    warningMsg.duration = this.GetDebugMsgDuration();
    warningMsg.message = message;
    this.blackboard.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warningMsg), true);
  }
}
