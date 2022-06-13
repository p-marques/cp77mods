// Eddies Received Multiplier by pMarK
// v1.0

class EddiesReceivedMultiplierMod {
  private let multiplier: Float;
  private let player: ref<PlayerPuppet>;
  private let transactionSystem: ref<TransactionSystem>;
  private let blackboard: ref<IBlackboard>;
  private let flag: Bool;
  private let debugMode: Bool;

  public static func Init(player: ref<PlayerPuppet>) -> ref<EddiesReceivedMultiplierMod> {
    let settings = new EddiesReceivedMultiplierMod();
    settings.player = player;
    settings.transactionSystem = GameInstance.GetTransactionSystem(player.GetGame());
    settings.blackboard = GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications);
    settings.debugMode = false;

    // ------ Settings Start ------

    settings.multiplier = 1.0;

    // ------ Settings End ------

    return settings;
  }

  public func DeltaEddies(evt: ref<ItemAddedEvent>) -> Void {
    let originalValue: Int32;
    let newTotalValue: Int32;
    let delta: Int32;
    let msg: String;

    if this.ShouldDeltaEddies() {
      originalValue = evt.itemData.GetQuantity() - evt.currentQuantity;
      newTotalValue = Cast<Int32>(Cast<Float>(originalValue) * this.multiplier);
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

      if this.debugMode {
        msg = "Original value: " + originalValue + "\\n" + "New total: " + newTotalValue + "\\n" + "Delta: " + delta + "\\n" + "Multiplier: " + Cast<Int32>(this.multiplier * 100.0) + "%";

        this.ShowMessage(msg);
      }
    }
    else {
      this.flag = false;
    }
  }

  private func ShouldDeltaEddies() -> Bool {
    if this.multiplier == 1.0 || this.multiplier < 0.0 {
      return false;
    }

    return !this.flag;
  }

  private func ShowMessage(message : String) -> Void {
    let warningMsg: SimpleScreenMessage;
    warningMsg.isShown = true;
    warningMsg.duration = 15.00;
    warningMsg.message = message;
    this.blackboard.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warningMsg), true);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnItemAddedToInventory(evt: ref<ItemAddedEvent>) -> Bool {
  wrappedMethod(evt);

  if this.eddiesReceivedMultiplierMod == null {
    this.eddiesReceivedMultiplierMod = EddiesReceivedMultiplierMod.Init(this);
  }

  if Equals(evt.itemID, MarketSystem.Money()) {
    this.eddiesReceivedMultiplierMod.DeltaEddies(evt);
  }
}

@addField(PlayerPuppet)
private let eddiesReceivedMultiplierMod: ref<EddiesReceivedMultiplierMod>;