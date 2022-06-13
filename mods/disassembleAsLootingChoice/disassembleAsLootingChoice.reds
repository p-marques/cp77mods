// Disassemble As Looting Option by pMarK
// v1.0

public class DisassembleAsLootingOptionMod {
    private let lootingController: wref<LootingController>;
    private let gameInstance: GameInstance;
    private let dataManager: wref<InventoryDataManagerV2>;
    private let player: ref<PlayerPuppet>;
    private let blackboard: ref<IBlackboard>;
    private let craftingSystem: ref<CraftingSystem>;
    private let customChoice: InteractionChoiceData;
    private let settings: DisassembleAsLootingOptionModSettings;

    public static func Initialize(lootingController: wref<LootingController>, gi: GameInstance, dataManager: wref<InventoryDataManagerV2>, referenceChoice: InteractionChoiceData) -> ref<DisassembleAsLootingOptionMod> {
        let mod: ref<DisassembleAsLootingOptionMod> = new DisassembleAsLootingOptionMod();
        let excludedQualities: array<String>;
        mod.lootingController = lootingController;
        mod.gameInstance = gi;
        mod.dataManager = dataManager;
        mod.player = dataManager.GetPlayer();
        mod.blackboard = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_Notifications);
        mod.customChoice = new InteractionChoiceData(n"ChoiceDisassemble_Hold", EInputKey.IK_Z, true, "Disassemble", referenceChoice.type, referenceChoice.data, referenceChoice.captionParts);

        // ------ Settings Start ------

        // Item quality strings in here prevent the disassemble option from appearing.
        // Default -> excludedQualities = ["Legendary"];
        excludedQualities = ["Legendary"];

        // ------ Settings End ------

        mod.settings = DisassembleAsLootingOptionModSettings.Initialize(excludedQualities);

        return mod;
    }

    public func GetModifiedLootData(data: LootData) -> LootData {
        if this.CanCurrentItemBeDisassembled() && !this.IsDisassembleChoiceShowing(data) {
            ArrayPush(data.choices, this.customChoice);

            this.player.RegisterInputListener(this, n"ChoiceDisassemble_Hold");
        }
        else {
            this.player.UnregisterInputListener(this, n"ChoiceDisassemble_Hold");
        }

        return data;
    }

    private func CanCurrentItemBeDisassembled() -> Bool {
        let inventoryItemData: InventoryItemData = this.lootingController.GetCurrentItem();
        let itemData: ref<gameItemData> = InventoryItemData.GetGameItemData(inventoryItemData);

        // Why does RPGManager.CanItemBeDisassembled() return true on Ammo?
        if Equals(itemData.GetItemType(), gamedataItemType.Con_Ammo) {
            return false;
        }

        if DisassembleAsLootingOptionModSettings.IsQualityExcluded(this.settings, InventoryItemData.GetQuality(inventoryItemData)) {
            return false;
        }

        return RPGManager.CanItemBeDisassembled(this.gameInstance, itemData);
    }

    protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
        if Equals(ListenerAction.GetName(action), n"ChoiceDisassemble_Hold") && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_HOLD_COMPLETE) {
            let itemData: InventoryItemData = this.lootingController.GetCurrentItem();
            let itemID: ItemID = InventoryItemData.GetID(itemData);

            if this.CanCurrentItemBeDisassembled() {
                if !IsDefined(this.craftingSystem) {
                    this.craftingSystem = GameInstance.GetScriptableSystemsContainer(this.gameInstance).Get(n"CraftingSystem") as CraftingSystem;
                }

                this.DisassembleItem(itemID, InventoryItemData.GetQuantity(itemData));
            }
            else {
                this.ShowWarningMessage("Disassemble As Looting Option Mod:\\nInput was consumed despite the fact that the item can't be disassembled.\\nThis should not be hapenning.\\nPlease report this on nexusmods.");
            }
        }
    }

    private func DisassembleItem(itemID: ItemID, amount: Int32) -> Void {
        let restoredAttachments: array<ItemAttachments>;
        let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.gameInstance);
        let listOfIngredients: array<IngredientData> = this.craftingSystem.GetDisassemblyResultItems(this.player, itemID, amount, restoredAttachments);
        let playerGameObject: ref<GameObject> = this.player as GameObject;
        let i: Int32 = 0;

        while i < ArraySize(restoredAttachments) {
        transactionSystem.GiveItem(playerGameObject, restoredAttachments[i].itemID, 1);
        i += 1;
        };

        GameInstance.GetTelemetrySystem(this.gameInstance).LogItemDisassembled(playerGameObject, itemID);
        if (transactionSystem.RemoveItem(this.lootingController.GetLootOwner(), itemID, amount)) {
            this.lootingController.Hide();
        }

        i = 0;
        while i < ArraySize(listOfIngredients) {
        transactionSystem.GiveItem(playerGameObject, ItemID.FromTDBID(listOfIngredients[i].id.GetID()), listOfIngredients[i].quantity);
        i += 1;
        };

        this.craftingSystem.UpdateBlackboard(CraftingCommands.DisassemblingFinished, itemID, listOfIngredients);
    }

    private func IsDisassembleChoiceShowing(data: LootData) -> Bool {
        for choice in data.choices {
            if Equals(choice.localizedName, "Disassemble") {
                return true;
            }
        }

        return false;
    }

    private func ShowWarningMessage(message : String) -> Void {
        let warningMsg: SimpleScreenMessage;
        warningMsg.isShown = true;
        warningMsg.duration = 5.00;
        warningMsg.message = message;
        this.blackboard.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warningMsg), true);
    }
}

struct DisassembleAsLootingOptionModSettings {
    private let excludedQualities: array<CName>;

    public static func Initialize(qualitiesStrings: array<String>) -> DisassembleAsLootingOptionModSettings {
        let excludedQualities: array<CName>;
        let size: Int32 = ArraySize(qualitiesStrings);
        let i: Int32;

        ArrayGrow(excludedQualities, size);

        while i < size {
            excludedQualities[i] = StringToName(qualitiesStrings[i]);

            i += 1;
        }

        return new DisassembleAsLootingOptionModSettings(excludedQualities);
    }

    public static func IsQualityExcluded(self: DisassembleAsLootingOptionModSettings, quality: CName) -> Bool {
        return ArrayContains(self.excludedQualities, quality);
    }
}

@addField(LootingController)
private let disassembleAsLootingOptionMod: ref<DisassembleAsLootingOptionMod>;

@wrapMethod(LootingController)
private final func RefreshChoicesPool(choices: script_ref<array<InteractionChoiceData>>) -> Void {
    if !IsDefined(this.disassembleAsLootingOptionMod) {
        this.disassembleAsLootingOptionMod = DisassembleAsLootingOptionMod.Initialize(this, this.m_gameInstance, this.m_dataManager, this.m_currendData.choices[0]);
    }

    this.m_currendData = this.disassembleAsLootingOptionMod.GetModifiedLootData(this.m_currendData);

    wrappedMethod(this.m_currendData.choices);
}

@wrapMethod(LootingController)
public final func Hide() -> Void {
    this.m_dataManager.GetPlayer().UnregisterInputListener(this.disassembleAsLootingOptionMod, n"ChoiceDisassemble_Hold");
    wrappedMethod();
}

@addMethod(LootingController)
public func GetCurrentItem() -> InventoryItemData {
    let itemData: ref<gameItemData> = this.m_dataManager.GetExternalGameItemData(this.m_currendData.ownerId, this.m_currendData.itemIDs[this.m_currendData.currentIndex]);

    return this.m_dataManager.GetInventoryItemData(this.GetLootOwner(), itemData);
}

@addMethod(LootingController)
public func GetLootOwner() -> wref<GameObject> {
    return GameInstance.FindEntityByID(this.m_gameInstance, this.m_currendData.ownerId) as GameObject;
}

@addMethod(InventoryDataManagerV2)
public func GetPlayer() -> wref<PlayerPuppet> {
    return this.m_Player;
}
