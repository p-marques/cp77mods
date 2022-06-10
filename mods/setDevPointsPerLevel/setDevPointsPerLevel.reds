// Set Development Points Per Level by pMarK
// v1.1

public class SetDevPointsPerLevelMod {
	private let perkPointsOnSkillLevelUp : Int32;
	private let useConditionalPointGain : Bool;
	private let useCustomAttributePointsMap : Bool;
	private let customAttributePointsMap : array<Int32>;
	private let customAttributePointsMapDefaultValue : Int32;
	private let useCustomSkillPointsMap : Bool;
	private let customSkillPointsMap : array<Int32>;
	private let customSkillPointsMapDefaultValue : Int32;
	private let attributePointsOnCharacterLevelUp : Int32;
	private let perkPointsOnCharacterLevelUp : Int32;

	public static func Init() -> ref<SetDevPointsPerLevelMod> {
		let settings = new SetDevPointsPerLevelMod();

		// ------ Settings Start ------

		// Perk points gained on every skill level up. Compounds with perks gained from skill progression.
		// Default = 0
		settings.perkPointsOnSkillLevelUp = 0;

		// Flag to enable/disable conditional point gain on character level up. This flag also applies to custom maps.
		// Default = false
		settings.useConditionalPointGain = false;

		// Flag to enable/disable use of new attribute point map. You can define overrides on a level by level basis below.
		// Default = false
		settings.useCustomAttributePointsMap = false;

		// Attribute points custom map default value.
		// Default = 1
		settings.customAttributePointsMapDefaultValue = 1;

		// Flag to enable/disable use of new skill point map. You can define overrides on a level by level basis below.
		// Default = false
		settings.useCustomSkillPointsMap = false;

		// Skill points custom map default value.
		// Default = 1
		settings.customSkillPointsMapDefaultValue = 1;

		// Attribute points gained on character level up. Ignored if using custom map.
		// Default = 1
		settings.attributePointsOnCharacterLevelUp = 1;

		// Perk points gained on character level up. Ignored if using custom map.
		// Default = 1
		settings.perkPointsOnCharacterLevelUp = 1;

		// ------ Settings End ------

		return settings;
	}

	public func SetupNewPointMaps() -> Void {
		if this.useCustomAttributePointsMap {
			this.SetupAtttributePointMap();
		}

		if this.useCustomSkillPointsMap {
			this.SetupSkillPointMap();
		}
	}

	public func GetModifiedDevPoints(proficiencyType : gamedataProficiencyType, pointType : gamedataDevelopmentPointType, level : Int32, vanillaValue : Int32) -> Int32 {
		if Equals(gamedataProficiencyType.Level, proficiencyType) {

			if this.useConditionalPointGain && !this.ShouldAwardPointsOnCharacerLevelUp(level) {
				return 0;
			}

			if Equals(gamedataDevelopmentPointType.Attribute, pointType) {
				if this.useCustomAttributePointsMap {
					return this.customAttributePointsMap[level - 1];
				}

				return this.attributePointsOnCharacterLevelUp;
			}

			if Equals(gamedataDevelopmentPointType.Primary, pointType) {
				if this.useCustomSkillPointsMap {
					return this.customSkillPointsMap[level - 1];
				}

				return this.perkPointsOnCharacterLevelUp;
			}

		}
		else {

			if NotEquals(gamedataProficiencyType.StreetCred, proficiencyType) {

				if Equals(gamedataDevelopmentPointType.Primary, pointType) {
					return this.perkPointsOnSkillLevelUp;
				}
			}

		}

		return vanillaValue;
	}

	// Attribute point map setup.
	private func SetupAtttributePointMap() -> Void {
		let i : Int32 = 0;

		while i < 50 {
			ArrayPush(this.customAttributePointsMap, this.customAttributePointsMapDefaultValue);

			i += 1;
		}

		// ------ Attribute Points Map Overrides Starts ------

		// this.customAttributePointsMap[21] = 0; // Example. At level 22 don't give an attribute point.

		// ------ Attribute Points Map Overrides Ends ------
	}

	// Skill point map setup.
	private func SetupSkillPointMap() -> Void {
		let i : Int32 = 0;

		while i < 50 {
			ArrayPush(this.customSkillPointsMap, this.customSkillPointsMapDefaultValue);

			i += 1;
		}

		// ------ Skill Points Map Overrides Starts ------

		// this.customSkillPointsMap[21] = 0; // Example. At level 22 don't give a skill point.

		// ------ Skill Points Map Overrides Ends ------
	}

	// With this condition player is awarded points if level is even.
	private func ShouldAwardPointsOnCharacerLevelUp(level : Int32) -> Bool {
		if level % 2 == 0 {
			return true;
		}

		return false;
	}
}

@addField(PlayerDevelopmentData)
let setDevPointsPerLevelMod : ref<SetDevPointsPerLevelMod>;

// @addMethod(PlayerDevelopmentData)
// private func LogUI(value: String) -> Void {
// 	let warningMsg: SimpleScreenMessage;
// 	warningMsg.isShown = true;
// 	warningMsg.duration = 20.00;
// 	warningMsg.message = value;
// 	GameInstance.GetBlackboardSystem(this.m_owner.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications).SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warningMsg), true);
// }

@replaceMethod(PlayerDevelopmentData)
private final const func ModifyDevPoints(type: gamedataProficiencyType, level: Int32) -> Void {
	let val: Int32;
	let i: Int32 = 0;
	let currentPointType :  gamedataDevelopmentPointType;

	if this.setDevPointsPerLevelMod == null {
		this.setDevPointsPerLevelMod = SetDevPointsPerLevelMod.Init();
		this.setDevPointsPerLevelMod.SetupNewPointMaps();
	}

	while i <= EnumInt(gamedataDevelopmentPointType.Count) {
		currentPointType = IntEnum(i);

		val = this.GetDevPointsForLevel(level, type, currentPointType);

		val = this.setDevPointsPerLevelMod.GetModifiedDevPoints(type, currentPointType, level, val);

		if val > 0 {
			this.AddDevelopmentPoints(val, currentPointType);
		};

		i += 1;

	};
}
