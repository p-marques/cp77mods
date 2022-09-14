// Eddies Received Multiplier by pMarK
// v1.1

module EddiesReceivedMult.Overrides
import EddiesReceivedMult.Base.EddiesReceivedMult

@if(ModuleExists("EddiesReceivedMult.Menu"))
import EddiesReceivedMult.Menu.EddiesReceivedMultWithMenu

@addField(PlayerPuppet)
private let eddiesReceivedMultiplierMod: ref<EddiesReceivedMult>;

@wrapMethod(PlayerPuppet)
protected cb func OnItemAddedToInventory(evt: ref<ItemAddedEvent>) -> Bool {
  wrappedMethod(evt);

  if Equals(evt.itemID, MarketSystem.Money()) {
    if !IsDefined(this.eddiesReceivedMultiplierMod) {
      this.InitializeEddiesReceivedMult();
      this.eddiesReceivedMultiplierMod.Setup(this);
    }

    this.eddiesReceivedMultiplierMod.DeltaEddies(evt.itemData.GetQuantity(), evt.currentQuantity);
  }
}

@if(ModuleExists("EddiesReceivedMult.Menu"))
@addMethod(PlayerPuppet)
private func InitializeEddiesReceivedMult() -> Void {
  this.eddiesReceivedMultiplierMod = new EddiesReceivedMultWithMenu();
}
@if(!ModuleExists("EddiesReceivedMult.Menu"))
@addMethod(PlayerPuppet)
private func InitializeEddiesReceivedMult() -> Void {
  this.eddiesReceivedMultiplierMod = new EddiesReceivedMult();
}
