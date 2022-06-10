// Set XP Multiplier by pMarK
// v1.0

public class SetXPMultiplierMod {
	public static func MultiplyExperienceAmount(blackboard: ref<IBlackboard>, type: gamedataProficiencyType, xpValue: Int32) -> Int32 {
		let finalMultiplier: Float;
		let newXPValue: Int32;
		let settings: SetXPMultiplierModSettings;
		let debugMode: Bool = false;

		// ------ Settings Start ------

		// Use a single multiplier for XP gain?
		// Default = false
		settings.useFlatXPMultiplier = false;

		// If useFlatXPMultiplier is set to true, all XP gained will be multiplied by this value.
		// Default = 1.0
		settings.flatXPMultiplier = 1.0;

		// Multiplier for character level experience.
		// Default = 1.0
		settings.levelXPMultiplier = 1.0;

		// Multiplier for street cred experience.
		// Default = 1.0
		settings.streetCredMultiplier = 1.0;

		// Use a single multiplier for all skill experience gained?
		// Default = true
		settings.useFlatSkillXPMultiplier = true;
		settings.flatSkillXPMultiplier = 1.0;

		settings.assaultXPMultiplier = 1.0; // Assault multiplier.
		settings.athleticsXPMultiplier = 1.0; // Athletics multiplier.
		settings.streetBrawlerXPMultiplier = 1.0; // Street Brawler multiplier.
		settings.coldBloodXPMultiplier = 1.0; // Cold Blood multiplier.
		settings.quickhackingXPMultiplier = 1.0; // Quickhacking multiplier.
		settings.craftingXPMultiplier = 1.0; // Crafting multiplier.
		settings.annihilationXPMultiplier = 1.0; // Annihilation multiplier.
		settings.engineeringXPMultiplier = 1.0; // Engineering multiplier.
		settings.handgunsXPMultiplier = 1.0; // Handguns multiplier.
		settings.breachProtocolXPMultiplier = 1.0; // Breach Protocol multiplier.
		settings.bladesXPMultiplier = 1.0; // Blades multiplier.
		settings.ninjutsuXPMultiplier = 1.0; // Ninjutsu multiplier.

		// ------ Settings End ------

		finalMultiplier = SetXPMultiplierMod.GetMultiplier(settings, type);

		if finalMultiplier < 0.0 {
			finalMultiplier = 1.0;
		}

		newXPValue = Cast<Int32>(Cast<Float>(xpValue) * finalMultiplier);

		if debugMode {
			SetXPMultiplierMod.DisplayMsg(blackboard, type, xpValue, newXPValue, finalMultiplier);
		}

		return newXPValue;
	}

	private static func GetMultiplier(st: SetXPMultiplierModSettings, type: gamedataProficiencyType) -> Float {
		if st.useFlatXPMultiplier {
			return st.flatXPMultiplier;
		}

		if Equals(type, gamedataProficiencyType.Level) {
			return st.levelXPMultiplier;
		}

		if Equals(type, gamedataProficiencyType.StreetCred) {
			return st.streetCredMultiplier;
		}

		if st.useFlatSkillXPMultiplier {
			return st.flatSkillXPMultiplier;
		}

		switch type {
			case gamedataProficiencyType.Assault: return st.assaultXPMultiplier;
			case gamedataProficiencyType.Athletics: return st.athleticsXPMultiplier;
			case gamedataProficiencyType.Brawling: return st.streetBrawlerXPMultiplier;
			case gamedataProficiencyType.ColdBlood: return st.coldBloodXPMultiplier;
			case gamedataProficiencyType.CombatHacking: return st.quickhackingXPMultiplier;
			case gamedataProficiencyType.Crafting: return st.craftingXPMultiplier;
			case gamedataProficiencyType.Demolition: return st.annihilationXPMultiplier;
			case gamedataProficiencyType.Engineering: return st.engineeringXPMultiplier;
			case gamedataProficiencyType.Gunslinger: return st.handgunsXPMultiplier;
			case gamedataProficiencyType.Hacking: return st.breachProtocolXPMultiplier;
			case gamedataProficiencyType.Kenjutsu: return st.bladesXPMultiplier;
			case gamedataProficiencyType.Stealth: return st.ninjutsuXPMultiplier;

			default: return 1.0;
		}
	}

	private static func DisplayMsg(blackboard: ref<IBlackboard>, type: gamedataProficiencyType, oldAmount: Int32, newAmount: Int32, multiplier: Float) -> Void {
		let msg: SimpleScreenMessage;

		msg.isShown = true;
		msg.duration = 10.00;
		msg.message = EnumValueToString("gamedataProficiencyType", Cast<Int64>(EnumInt(type))) + ": " + oldAmount  + " -> " + newAmount + " (" + Cast<Int32>(multiplier * 100.0) + "%)";

		blackboard.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(msg), true);
	}
}

public struct SetXPMultiplierModSettings {
	public let useFlatXPMultiplier: Bool;

	public let flatXPMultiplier: Float;

	public let levelXPMultiplier: Float;

	public let streetCredMultiplier: Float;

	public let useFlatSkillXPMultiplier: Bool;

	public let flatSkillXPMultiplier: Float;

	public let assaultXPMultiplier: Float;

	public let athleticsXPMultiplier: Float;

	public let streetBrawlerXPMultiplier: Float;

	public let coldBloodXPMultiplier: Float;

	public let quickhackingXPMultiplier: Float;

	public let craftingXPMultiplier: Float;

	public let annihilationXPMultiplier: Float;

	public let engineeringXPMultiplier: Float;

	public let handgunsXPMultiplier: Float;

	public let breachProtocolXPMultiplier: Float;

	public let bladesXPMultiplier: Float;

	public let ninjutsuXPMultiplier: Float;
}

@replaceMethod(PlayerDevelopmentData)
public final const func AddExperience(amount: Int32, type: gamedataProficiencyType, telemetryGainReason: telemetryLevelGainReason) -> Void {
    let awardedAmount: Int32;
    let proficiencyProgress: ref<ProficiencyProgressEvent>;
    let reqExp: Int32;
    let telemetryEvt: TelemetryLevelGained;
    let pIndex: Int32 = this.GetProficiencyIndexByType(type);

	// EDIT+
	let blackboard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.m_owner.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications);

	amount = SetXPMultiplierMod.MultiplyExperienceAmount(blackboard, type, amount);
	// EDIT-

    if pIndex >= 0 && !this.IsProficiencyMaxLvl(type) {
      while amount > 0 && !this.IsProficiencyMaxLvl(type) {
        reqExp = this.GetRemainingExpForLevelUp(type);
        if amount - reqExp >= 0 {
          awardedAmount += reqExp;
          amount -= reqExp;
          this.m_proficiencies[pIndex].currentExp += reqExp;
          this.m_proficiencies[pIndex].expToLevel = this.GetRemainingExpForLevelUp(type);
          if this.CanGainNextProficiencyLevel(pIndex) {
            this.ModifyProficiencyLevel(type);
            this.UpdateUIBB();
            if this.m_owner.IsPlayerControlled() && NotEquals(telemetryGainReason, telemetryLevelGainReason.Ignore) {
              telemetryEvt.playerPuppet = this.m_owner;
              telemetryEvt.proficiencyType = type;
              telemetryEvt.proficiencyValue = this.m_proficiencies[pIndex].currentLevel;
              telemetryEvt.isDebugEvt = Equals(telemetryGainReason, telemetryLevelGainReason.IsDebug);
              telemetryEvt.perkPointsAwarded = this.GetDevPointsForLevel(this.m_proficiencies[pIndex].currentLevel, type, gamedataDevelopmentPointType.Primary);
              telemetryEvt.attributePointsAwarded = this.GetDevPointsForLevel(this.m_proficiencies[pIndex].currentLevel, type, gamedataDevelopmentPointType.Attribute);
              GameInstance.GetTelemetrySystem(this.m_owner.GetGame()).LogLevelGained(telemetryEvt);
            };
          } else {
            return;
          };
        } else {
          this.m_proficiencies[pIndex].currentExp += amount;
          this.m_proficiencies[pIndex].expToLevel = this.GetRemainingExpForLevelUp(type);
          awardedAmount += amount;
          amount -= amount;
        };
      };
      if awardedAmount > 0 {
        if this.m_displayActivityLog {
          if Equals(type, gamedataProficiencyType.StreetCred) && GameInstance.GetQuestsSystem(this.m_owner.GetGame()).GetFact(n"street_cred_tutorial") == 0 && GameInstance.GetQuestsSystem(this.m_owner.GetGame()).GetFact(n"disable_tutorials") == 0 && Equals(telemetryGainReason, telemetryLevelGainReason.Gameplay) && GameInstance.GetQuestsSystem(this.m_owner.GetGame()).GetFact(n"q001_show_sts_tut") > 0 {
            GameInstance.GetQuestsSystem(this.m_owner.GetGame()).SetFact(n"street_cred_tutorial", 1);
          };
        };
        proficiencyProgress = new ProficiencyProgressEvent();
        proficiencyProgress.type = type;
        proficiencyProgress.expValue = this.GetCurrentLevelProficiencyExp(type);
        proficiencyProgress.delta = awardedAmount;
        proficiencyProgress.remainingXP = this.GetRemainingExpForLevelUp(type);
        proficiencyProgress.currentLevel = this.GetProficiencyLevel(type);
        proficiencyProgress.isLevelMaxed = this.GetProficiencyLevel(type) + 1 == this.GetProficiencyAbsoluteMaxLevel(type);
        GameInstance.GetUISystem(this.m_owner.GetGame()).QueueEvent(proficiencyProgress);
        if Equals(type, gamedataProficiencyType.Level) {
          this.UpdatePlayerXP();
        };
      };
    };
}
