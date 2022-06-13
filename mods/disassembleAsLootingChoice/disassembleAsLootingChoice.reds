// Disassemble as Looting Option by pMarK
// v1.0

@wrapMethod(LootingController)
private final func RefreshChoicesPool(choices: script_ref<array<InteractionChoiceData>>) -> Void {
    this.m_currendData = this.ModRefreshDisassembleChoice(this.m_currendData);

    wrappedMethod(this.m_currendData.choices);
}

@addField(LootingController)
private let disassembleInteractionChoiceData: InteractionChoiceData;

@addField(LootingController)
private let craftingSystemRef: ref<CraftingSystem>;

@addMethod(LootingController)
private func InitializeDisassembleChoice(choice: InteractionChoiceData) -> Void {
    this.disassembleInteractionChoiceData = new InteractionChoiceData(n"ChoiceDisassemble_Hold", EInputKey.IK_Z, true, "Disassemble", choice.type, choice.data, choice.captionParts);
}

@addMethod(LootingController)
private func ModRefreshDisassembleChoice(data: LootData) -> LootData {
    if this.CanCurrentItemBeDisassembled() && !this.IsDisassembleChoiceShowing() {
        this.InitializeDisassembleChoice(data.choices[0]);

        ArrayPush(data.choices, this.disassembleInteractionChoiceData);

        this.m_dataManager.GetPlayer().RegisterInputListener(this, n"ChoiceDisassemble_Hold");
    }
    else {
        this.m_dataManager.GetPlayer().UnregisterInputListener(this, n"ChoiceDisassemble_Hold");
    }

    return data;
}

@wrapMethod(LootingController)
public final func Hide() -> Void {
    this.m_dataManager.GetPlayer().UnregisterInputListener(this, n"ChoiceDisassemble_Hold");
    wrappedMethod();
}

@addMethod(LootingController)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if Equals(ListenerAction.GetName(action), n"ChoiceDisassemble_Hold") && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_HOLD_COMPLETE) {
        let itemData: InventoryItemData = this.GetCurrentItem();
        let itemID: ItemID = InventoryItemData.GetID(itemData);
        let lootOwner: wref<GameObject> = this.GetLootOwner();

        if this.CanCurrentItemBeDisassembled() {
            if !IsDefined(this.craftingSystemRef) {
                this.craftingSystemRef = GameInstance.GetScriptableSystemsContainer(this.m_gameInstance).Get(n"CraftingSystem") as CraftingSystem;
            }

            this.ModDisassembleItem(itemID, InventoryItemData.GetQuantity(itemData));
        }
        else {
            this.ModShowMessage("ChoiceDisassemble_Hold consumed despite the fact that the item can't be disassembled.");
        }
    }
}

@addMethod(LootingController)
private func ModDisassembleItem(itemID: ItemID, amount: Int32) -> Void {
    let restoredAttachments: array<ItemAttachments>;
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_gameInstance);
    let listOfIngredients: array<IngredientData> = this.craftingSystemRef.GetDisassemblyResultItems(this.m_dataManager.GetPlayer(), itemID, amount, restoredAttachments);
    let playerGameObject: ref<GameObject> = this.m_dataManager.GetPlayer() as GameObject;
    let i: Int32 = 0;

    while i < ArraySize(restoredAttachments) {
      transactionSystem.GiveItem(playerGameObject, restoredAttachments[i].itemID, 1);
      i += 1;
    };

    GameInstance.GetTelemetrySystem(this.m_gameInstance).LogItemDisassembled(playerGameObject, itemID);
    if (transactionSystem.RemoveItem(this.GetLootOwner(), itemID, amount)) {
        this.Hide();
    }

    i = 0;
    while i < ArraySize(listOfIngredients) {
      transactionSystem.GiveItem(playerGameObject, ItemID.FromTDBID(listOfIngredients[i].id.GetID()), listOfIngredients[i].quantity);
      i += 1;
    };

    this.craftingSystemRef.UpdateBlackboard(CraftingCommands.DisassemblingFinished, itemID, listOfIngredients);
}

@addMethod(LootingController)
private func IsDisassembleChoiceShowing() -> Bool {
    for choice in this.m_currendData.choices {
        if Equals(choice.localizedName, "Disassemble") {
            return true;
        }
    }

    return false;
}

@addMethod(LootingController)
private func CanCurrentItemBeDisassembled() -> Bool {
    let itemData: ref<gameItemData> = InventoryItemData.GetGameItemData(this.GetCurrentItem());

    // Why does RPGManager.CanItemBeDisassembled() return true on Ammo?
    if Equals(itemData.GetItemType(), gamedataItemType.Con_Ammo) {
        return false;
    }

    return RPGManager.CanItemBeDisassembled(this.m_gameInstance, itemData);
}

@addMethod(LootingController)
private func GetCurrentItem() -> InventoryItemData {
    let itemData: ref<gameItemData> = this.m_dataManager.GetExternalGameItemData(this.m_currendData.ownerId, this.m_currendData.itemIDs[this.m_currendData.currentIndex]);

    return this.m_dataManager.GetInventoryItemData(this.GetLootOwner(), itemData);
}

@addMethod(LootingController)
private func GetLootOwner() -> wref<GameObject> {
    return GameInstance.FindEntityByID(this.m_gameInstance, this.m_currendData.ownerId) as GameObject;
}

@addMethod(LootingController)
private func ModShowMessage(message : String) -> Void {
    let warningMsg: SimpleScreenMessage;
    warningMsg.isShown = true;
    warningMsg.duration = 5.00;
    warningMsg.message = message;
    GameInstance.GetBlackboardSystem(this.m_gameInstance).Get(GetAllBlackboardDefs().UI_Notifications).SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warningMsg), true);
}

@addMethod(InventoryDataManagerV2)
public func GetPlayer() -> wref<PlayerPuppet> {
    return this.m_Player;
}
