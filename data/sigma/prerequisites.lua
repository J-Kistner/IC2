dofilepath("data:attr_parameters.lua")

---------------------------------------------------------------------
-- File    : prerequisites.lua
-- Desc    : 
-- Created : Wednesday, June 06, 2001
-- Author  : 
-- 
-- (c) 2001 Relic Entertainment Inc.
-- 

-- * data for prerequisites

-- * types are:
-- *	TYPE_Structure
-- *	TYPE_Research
-- *	TYPE_AddOn
-- *	TYPE_CreatureUpgrade

prerequisites = 
{
	rank3_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_Rank3,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank2,
	},

	rank4_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_Rank4,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank3,
	},

	rank5_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_Rank5,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank4,
	},

	advancedstructure_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_AdvancedStructure,
		reqtype = TYPE_Structure,
		reqitem = ResourceRenew_EC,
	},

	henchmanheal_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_HenchmanHeal,
		reqtype = TYPE_Structure,
		reqitem = VetClinic_EC,
	},

	henchmantag_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_HenchmanTag,
		reqtype = TYPE_Structure,
		reqitem = VetClinic_EC,
	},

	henchmanbinoculars_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_HenchmanBinoculars,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank3,
	},
	
	electrical_generator = 
	{
		newtype = TYPE_Structure,
		newitem = ElectricGenerator_EC,
		reqtype = TYPE_Structure,
		reqitem = ResourceRenew_EC,
	},

--		water_chamber = 
--		{
--			newtype = TYPE_Structure,
--			newitem = WaterChamber_EC,
--			reqtype = TYPE_Research,
--			reqitem = RESEARCH_Rank2,
--		},

	aviary =
	{
		newtype = TYPE_Structure,
		newitem = Aviary_EC,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank2,
	},

--	antiair_tower = 
--	{
--		newtype = TYPE_Structure,
--		newitem = AntiAirTower_EC,
--		reqtype = TYPE_Research,
--		reqitem = RESEARCH_AdvancedStructure,
--	},

--	soundbeam_tower = 
--	{
--		newtype = TYPE_Structure,
--		newitem = SoundBeamTower_EC,
--		reqtype = TYPE_Structure,
--		reqitem = ResourceRenew_EC,
--	},

--	foundry = 
--	{
--		newtype = TYPE_Structure,
--		newitem = Foundry_EC,
--		reqtype = TYPE_Structure,
--		reqitem = ResourceRenew_EC,
--	},

	genetic_amplifier = 
	{
		newtype = TYPE_Structure,
		newitem = GeneticAmplifier_EC,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank2,
	},

--	landingpad = 
--	{
--		newtype = TYPE_Structure,
--		newitem = LandingPad_EC,
--		reqtype = TYPE_Research,
--		reqitem = RESEARCH_AdvancedStructure,
--		limit	= 1,
--	},

	landingpadlimit = 
	{
		newtype = TYPE_Limit,
		newitem = LandingPad_EC,
		reqtype = TYPE_Limit,
		reqitem = LandingPad_EC,
		limit   = 1,
	},
	
	cliniclimit = 
	{
		newtype = TYPE_Limit,
		newitem = VetClinic_EC,
		reqtype = TYPE_Limit,
		reqitem = VetClinic_EC,
		limit   = 2,
	},


	gyrocopterlimit = 
	{
		newtype = TYPE_Limit,
		newitem = Gyrocopter_EC,
		reqtype = TYPE_Limit,
		reqitem = Gyrocopter_EC,
		limit   = 1,
	},

	lightningrodlimit = 
	{
		newtype = TYPE_Limit,
		newitem = ResourceRenew_EC,
		reqtype = TYPE_Limit,
		reqitem = ResourceRenew_EC,
		limit   = ((AttrParameters.six_rods==1) and 6 or 4),
	},
	
		bramblefencelimit = 
	{
		newtype = TYPE_Limit,
		newitem = BrambleFence_EC,
		reqtype = TYPE_Limit,
		reqitem = BrambleFence_EC,
		limit   = 150,				
	},

--	antiairtowerlimit = 
--	{
--		newtype = TYPE_Limit,
--		newitem = AntiAirTower_EC,
--		reqtype = TYPE_Limit,
--		reqitem = AntiAirTower_EC,
--		limit   = 35,
--	},

--	soundbeamtowerlimit = 
--	{
--		newtype = TYPE_Limit,
--		newitem = SoundBeamTower_EC,
--		reqtype = TYPE_Limit,
--		reqitem = SoundBeamTower_EC,
--		limit   = 15,
--	},

	radarpulse = 
	{
		newtype = TYPE_Command,
		newitem = CMD_RadarPulse,
		reqtype = TYPE_Structure,
		reqitem = AntiAirTower_EC,
	},

	labdefense = 
	{
		newtype = TYPE_Command,
		newitem = CMD_LabDefenseTurnOff,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank3,
	},

--	labdefense_research= 
--	{
--		newtype = TYPE_Research,
--		newitem = RESEARCH_LabDefense,
--		reqtype = TYPE_Research,
--		reqitem = RESEARCH_IncBuildingIntegrity,
--	},

	vetclinic = 
	{
		newtype = TYPE_Structure,
		newitem = VetClinic_EC,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_AdvancedStructure,
	},

	henchmanyoke_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_HenchmanYoke,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank3,
	},

	henchmanmotspeech_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_HenchmanMotivationalSpeech,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank2,
	},

	henchmanheal_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_HenchmanHeal,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank2,
	},

	strengthenelecgrid_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_StrengthenElectricalGrid,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank3,
	},

	incbuildingintegrity_research = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_IncBuildingIntegrity,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank3,
	},

	sbtower_upgrade = 
	{
		newtype = TYPE_Research,
		newitem = RESEARCH_TowerUpgrade,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_Rank3,
	},

	sonic_boom = 
	{
		newtype = TYPE_Command,
		newitem = CMD_SonicBoom,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_TowerUpgrade,
	},
	
	air_burst = 
	{
		newtype = TYPE_Command,
		newitem = CMD_AirBurst,
		reqtype = TYPE_Research,
		reqitem = RESEARCH_TowerUpgrade,
	},
}
