// Disassemble As Looting Option by pMarK
// v1.1.0

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
        let shouldPlaySound: Bool;

        mod.lootingController = lootingController;
        mod.gameInstance = gi;
        mod.dataManager = dataManager;
        mod.player = dataManager.GetPlayer();
        mod.blackboard = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_Notifications);
        mod.customChoice = new InteractionChoiceData(n"ChoiceDisassemble_Hold", EInputKey.IK_Z, true, GetLocalizedText("Gameplay-Devices-DisplayNames-DisassemblableItem"), referenceChoice.type, referenceChoice.data, referenceChoice.captionParts);

        // ------ Settings Start ------

        // Item quality strings in here prevent the disassemble option from appearing.
        // Possible qualities: "Common", "Uncommon", "Rare", "Epic" and "Legendary"
        // Default -> excludedQualities = ["Legendary"];
        excludedQualities = ["Legendary"];

        // Play a sound after disassemble? This is not the standard disassemble sound, just a stand-in.
        // Default -> shouldPlaySound = true;
        shouldPlaySound = true;

        // ------ Settings End ------

        mod.settings = DisassembleAsLootingOptionModSettings.Initialize(excludedQualities, shouldPlaySound);

        return mod;
    }

    public func HandleAdditionOfChoiceDisassemble(data: LootData) -> LootData {
        if this.CanCurrentItemBeDisassembled() {
            if !this.IsDisassembleChoiceShowing(data) {
                ArrayPush(data.choices, this.customChoice);
            }

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
        //let itemRecord: = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemData.GetID()));

        // Why does RPGManager.CanItemBeDisassembled() return true on Ammo?
        // Shards also come back as true.
        if Equals(itemData.GetItemType(), gamedataItemType.Con_Ammo) || itemData.HasTag(n"Shard") || itemData.HasTag(n"Quest") {
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
        }
    }

    private func DisassembleItem(itemID: ItemID, amount: Int32) -> Void {
        let restoredAttachments: array<ItemAttachments>;
        let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.gameInstance);
        let listOfIngredients: array<IngredientData> = this.craftingSystem.GetDisassemblyResultItems(this.lootingController.GetLootOwner(), itemID, amount, restoredAttachments);
        let playerGameObject: ref<GameObject> = this.player as GameObject;
        let i: Int32 = 0;

        while i < ArraySize(restoredAttachments) {
            transactionSystem.GiveItem(playerGameObject, restoredAttachments[i].itemID, 1);
            i += 1;
        };

        GameInstance.GetTelemetrySystem(this.gameInstance).LogItemDisassembled(playerGameObject, itemID);
        if (transactionSystem.RemoveItem(this.lootingController.GetLootOwner(), itemID, amount)) {
            this.ForceInteractionReactivation();
        }

        i = 0;
        while i < ArraySize(listOfIngredients) {
            transactionSystem.GiveItem(playerGameObject, ItemID.FromTDBID(listOfIngredients[i].id.GetID()), listOfIngredients[i].quantity);
            i += 1;
        };

        this.AwardExperience(listOfIngredients, amount);

        this.craftingSystem.UpdateBlackboard(CraftingCommands.DisassemblingFinished, itemID, listOfIngredients);

        if this.settings.playSoundAfterDisassemble {
            this.PlayDisassembleSound();
        }
    }

    private func AwardExperience(ingredients: array<IngredientData>, amount: Int32) -> Void {
        let ingredientQuality: gamedataQuality;
        let xpID: TweakDBID;
        let xpToAward: Int32;
        let i: Int32 = 0;

        while i < ArraySize(ingredients) {

            ingredientQuality = RPGManager.GetItemQualityFromRecord(TweakDBInterface.GetItemRecord(ingredients[i].id.GetID()));

            switch ingredientQuality {
                case gamedataQuality.Common:
                xpID = t"Constants.CraftingSystem.commonIngredientXP";
                break;
                case gamedataQuality.Uncommon:
                xpID = t"Constants.CraftingSystem.uncommonIngredientXP";
                break;
                case gamedataQuality.Rare:
                xpID = t"Constants.CraftingSystem.rareIngredientXP";
                break;
                case gamedataQuality.Epic:
                xpID = t"Constants.CraftingSystem.epicIngredientXP";
                break;
                case gamedataQuality.Legendary:
                xpID = t"Constants.CraftingSystem.legendaryIngredientXP";
                break;
            }

            xpToAward += TweakDBInterface.GetInt(xpID, 0) * ingredients[i].baseQuantity * amount;

            i += 1;
        }

        RPGManager.AwardXP(this.gameInstance, Cast<Float>(xpToAward) * 0.33, gamedataProficiencyType.Crafting);
    }

    private func IsDisassembleChoiceShowing(data: LootData) -> Bool {
        for choice in data.choices {
            if Equals(choice.localizedName, "Disassemble") {
                return true;
            }
        }

        return false;
    }

    private func PlayDisassembleSound() -> Void {
        GameObject.PlaySoundEvent(this.player, n"dev_vending_machine_can_falls");
    }

    private func ForceInteractionReactivation() -> Void {
        let event: ref<InteractionActivationEvent> = new InteractionActivationEvent();

        event.eventType = gameinteractionsEInteractionEventType.EIET_activate;
        event.hotspot = this.lootingController.GetLootOwner();
        event.activator = this.player;
        event.layerData = new InteractionLayerData(n"Loot");

        this.lootingController.GetLootOwner().QueueEvent(event);
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

    public let playSoundAfterDisassemble: Bool;

    public static func Initialize(qualitiesStrings: array<String>, playSound: Bool) -> DisassembleAsLootingOptionModSettings {
        let excludedQualities: array<CName>;
        let size: Int32 = ArraySize(qualitiesStrings);
        let i: Int32;

        ArrayGrow(excludedQualities, size);

        while i < size {
            excludedQualities[i] = StringToName(qualitiesStrings[i]);

            i += 1;
        }

        return new DisassembleAsLootingOptionModSettings(excludedQualities, playSound);
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

    this.m_currendData = this.disassembleAsLootingOptionMod.HandleAdditionOfChoiceDisassemble(this.m_currendData);

    wrappedMethod(this.m_currendData.choices);
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
