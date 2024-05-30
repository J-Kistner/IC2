--Changelog for Tellurian 2.11 beta (relative to Tellurian 2.10.1):
    -- Range power equation modified (shape vals changed from [0, 10, 10, 363] to [0, 5, 30, 363])
    -- Effective mobility equation modified ([0, 45, 30, 60] to [0, 45, 35, 55]). This means amphib price is starting to tend towards marginal again, which is... not really good balance.
    -- Flyer mobility mult increased from 1.6 to 1.75.

dofilepath("data:junction.lua")
dofilepath("data:attr_functions.lua")
dofilepath("data:attr_parameters.lua")
dofilepath("data:attr_functions2.lua")
dofilepath("data:cost_functions.lua")
--deleteStart
function combine_creature()
    print("started combiner")
    --deleteEnd

    ---------------------
    ---------------------
    -- Constant Tables --
    ---------------------
    ---------------------

        -- Ranking Constants --
        --Table of maximum power thresholds, base coal costs and cost exponents for each level.
        --Table is defined here, but only used in the costs section towards the bottom of Attrcombiner.
        --{max power, base coal cost, cost_exponent}
        max_pow = 1;
        base_coal_cost = 2;
        cost_exponent = 3;  -- NOTE: The lower the cost exponent, the more expensive spam becomes and the cheaper power becomes.

        RankTable =
        {
            {60,    60,     1},     --L1
            {120,   100,    1},     --L2
            {230,   170,    0.8},    --L3
            {400,   240,    0.8},   --L4
            {1000,  410,    0.75}    --L5
        };

        --Just some candy; this table is only ever used during the final elec cost scaling to associate damagetypes
        --with strings for display in combotest.
        DTStringTable =
        {
            {1, "DT_Poison"},
            {2, "DT_Horns"},
            {4, "DT_Barrier_Destroy"},
            {8, "DT_Electric"},
            {16, "DT_Sonic"},
            {4096, "DT_Ranged_Poison"},
        };

        dt_number = 1;
        dt_string = 2;

    -----------------
    -----------------
    -- Tweakables ---
    -----------------
    -----------------

        -- This section contains some handy parameters for easy tweaking.

        -- Multipliers on ranged attack costs.
        --original 1.1
	ranged_coal_cost_mult       = 1.17;
	--edit flag orginal : 1.5
        direct_range_elec_mult      = 2.0;
        sonic_elec_mult             = 1.5;
        flying_artillery_elec_mult  = 1.5;
        range_pack_hunter_mult      = 1.25;
        artillery_targets_hit       = 1;

        -- The below multipliers apply a factor to various parameters if the unit is a flyer; they're only used for cost calculations, not power.
        damage_flyer_mult    = 1.15;
        ehp_flyer_mult      = 1.15;
        mobility_flyer_mult = 1.5;

        -- Define Limits for some variables
        max_armour 			 = 0.60;
        min_sight 			 = 25;
        max_sight 			 = 50;
        max_flyer_range_dist = 24;
        min_landspeed		 = 18;
        min_waterspeed		 = 18;
        min_airspeed		 = 16;
        min_build_time       = 16;
        flyer_min_build_time = 50;

        -- Variables that inform the shape of the mobility cost curve (ONLY cost, not mobility itself).
        mobility_divisor = 25;
        mobility_exp = 0.4;
        flyer_mobility_exp = 0.35;

        -- Sight cost.
        sight_cost_multiplier = 0.5;

        -- A rebate for defense; you only pay for this much of your defense.
        defense_cost_multiplier = 0.9;

        -- These variables are grabbed from tuning!
        herding_def_multiplier = PackBonus.basedefensemodifier; -- I know this says pack but it's herding

    -----------------
    -----------------
    -- Attributes ---
    -----------------
    -----------------

        --Mobility attributes:
        has_flying		= Attr( "is_flyer" );
        has_swim		= Attr( "is_swimmer" );
        has_land		= Attr( "is_land" );

        --Set Limits
        setattribute("armour", min(Attr("armour"), max_armour));
        setattribute("sight_radius1", min(max(Attr("sight_radius1"), min_sight), max_sight));

        if (has_land == 0 and has_swim == 0 and has_flying == 0) then
            has_land = 1
        end

        if has_land == 1 then
            setattribute("speed_max", max(Attr("speed_max"), min_landspeed));
        end

        if has_swim == 1 then
            setattribute("waterspeed_max", max(Attr("waterspeed_max"), min_waterspeed));
        end

        if has_flying == 1 then
            setattribute("airspeed_max", max(Attr("airspeed_max"), min_airspeed));
        end

        ehp_flyer_factor = ((has_flying==1) and ehp_flyer_mult or 1);
        damage_flyer_factor = ((has_flying==1) and damage_flyer_mult or 1);
        mobility_flyer_factor = ((has_flying==1) and mobility_flyer_mult or 1);

        --Create derived attributes:
        setattribute("ehp", Attr( "hitpoints" )/(1-Attr( "armour" ))); --effective HP, a measure of HP and defense. Used for power, doesn't account for flyer bonus.
        setattribute("cost_ehp", Attr( "ehp" ) * ehp_flyer_factor); --EHP with flyer bonus accounted for.
        setattribute("scaling_size", Attr("size"));  --For creatures over size 9, this is their size as displayed in army builder; their "size" attribute will be set to 10 or 9 in the Size Hack section.
        setattribute("range_damage", 0);   --the maximum damage dealt by all of the creature's ranged attacks.
        setattribute("range_distance", 0);  --the ranged attack distance of the unit.
        setattribute("range_damage_distance", 0); --an equivalent melee damage based on a creature's ranged attack attributes. Uses damage and distance
        setattribute("mixed_dps", 0);       --an equivalent melee damage based on all of a creature's attack attributes.
        setattribute("mobility", 0);        --an equivalent land speed based on all of a creature's speed attributes.
        setattribute("power_rank", 0);      --the rank of the creature based on power alone.
        setattribute("effective_melee", Attr("melee_damage") * damage_flyer_factor); --Melee damage, multiplied by a flyer-specific factor, used for cost calcs.

        -- Let's calculate the extra EHP we receive from herding here, and store it as an attribute. We'll build a domain from it later.
        setattribute("herding_ehp_bonus", 0);

        if (Attr("herding") == 1) then
            extraArmour = (Attr( "armour" )*(herding_def_multiplier - 1));
            armourOverCap = max(0, (Attr( "armour" ) + extraArmour) - max_armour);
            cappedExtraArmour = extraArmour - armourOverCap;

            setattribute("herding_ehp_bonus", ( (Attr( "hitpoints" ) * ehp_flyer_factor )/(1-(Attr( "armour" ) + cappedExtraArmour))) - Attr( "cost_ehp" ) );
        end

        cost_coal       = 0;
        cost_elec       = 0;

        -- Ranged attributes:
        -- These will be set to flag if the creature has any direct or any artillery range attack.
        has_range = nil;
        has_direct = nil;
        has_sonic = nil;
        setattribute("has_artillery", 0);

        BodyPartsThatCanHaveRange = { 2, 3, 4, 5, 8 };
        -- determine type of ranged attack and set range damage to be equal to the
        -- highest damage ranged attack, with range_distance being the minimum ranged distance.

        --pairsBelow
        for index, part in BodyPartsThatCanHaveRange do
            --endPairs
            part_damage 	= get_range_var( part, "damage" );
            part_range 		= get_range_var( part, "max" ); --Attr( "range" .. part .. "_max" );
            part_dtype 		= get_range_var( part, "dmgtype" ); --Attr( "range" .. part .. "_dmgtype" );

            if ( part_damage > 0 ) then
                has_range = 1;

                --Set flying range distance limit
                if (has_flying == 1 and (part_range > max_flyer_range_dist)) then
                    part_range = max_flyer_range_dist;
                    setattribute("range"..part.."_max", max_flyer_range_dist);
                end

                --Find part with shortest range distance and set it as range_distance.
                --Creatures with multiple range limbs travel to shortest distance before attacking, so use this for future calculations.
                if ( part_range < Attr("range_distance") ) or Attr("range_distance") == 0 then
                    setattribute("range_distance", part_range);
                end

                --If creature has multiple range attacks, use maximum damage one
                if ( part_damage > Attr("range_damage") ) or Attr("range_damage") == 0 then
                    setattribute("range_damage", part_damage);
                    if ( range_artillerytype( part ) ~= 0 ) then
                        setattribute("artillery_damage", Attr("range_damage") * artillery_targets_hit);
                    end

                end

                if ( range_artillerytype( part ) == 0 ) then
                    if ( part_dtype == 16 ) then --sonic attack identified
                        has_sonic = 1;
                    else --directranged, non-sonic
                        has_direct = 1;
                    end

                else --artillery
                    setattribute("has_artillery", 1);

                end
            end
        end
        
        if (Attr("underpopulation") == 1) then
            setattribute("overpopulation", 0);
        end
        
        -- Helpful variable here, used later.
        setattribute("non_flyer_direct_range", 0);
        setattribute("flyer_direct_range", 0);

        if (has_sonic == 1 or has_direct == 1) then
            if (has_flying == 0) then
                setattribute("non_flyer_direct_range", 1);
            else
                setattribute("flyer_direct_range", 1);
            end
        end

        -- Finally, unusable abilities are removed
        if (has_range == 1) then
            setattribute("charge_attack", 0);
            setattribute("leap_attack", 0);

            --Give frog leap attack back when combined with itself (for creature selection)
            if (Attr("lefthalf_name") == 24134 and Attr("righthalf_name") == 24135) then
                setattribute("leap_attack", 1);
            end
        end

        if (has_flying == 1) then
            setattribute("can_dig", 0);
            setattribute("leap_attack", 0);
            setattribute("charge_attack", 0);
            setattribute("can_SRF", 0);
        end

        if (has_swim == 1 and has_land == 0) then
            setattribute("can_dig", 0);
        end

        if (Attr("pack_hunter") == 1 and Attr("herding") == 1) then
            setattribute("herding", 0);
        end

        --Not unusable, but removing so that loner units won't be charged for herding or pack hunter
        if (Attr("loner") == 1) then
            setattribute("herding", 0);
            setattribute("pack_hunter", 0);
        end

    ------------------------
    ------------------------
    -- Domain Definitions --
    ------------------------
    ------------------------

        --Set points for shapevalue curves; these represent the (more or less) maximum values of attributes,
        --which are then used as the max points for the domains they represent. They're paired with this creature's
        --specific value for the given attribute, used for actual scaling.
        dom_max = 1;
        dom_val = 2;

        power_domain            = {1000,  "Power"};
        true_size_domain        = {10,    "size"};
        scaling_size_domain     = {13,    "scaling_size"}; --For creatures over size 9, this their size as displayed in army builder.
        ehp_domain              = {3000,  "ehp"};
        cost_ehp_domain         = {3000,  "cost_ehp"};
        melee_dps_domain        = {100,   "melee_damage"}; --Pure melee damage (for power calcs)
        eff_melee_dps_domain    = {100,   "effective_melee"}; --Pure melee damage with flyer adjustment (for cost calcs)
        range_dps_domain        = {50,    "range_damage"}; --Pure range damage, no distance
        artillery_dps_domain    = {50,    "artillery_damage"}; --Artillery damage with adjustment for area of effect
        distance_domain         = {100,   "range_distance"};
        dist_dam_domain         = {100,   "range_damage_distance"}; --Ranged DPS factor incorporating distance
        mixed_dps_domain        = {100,   "mixed_dps"};  --Combined melee and damage_distance from ranged (for power calcs)
        eff_mixed_dps_domain    = {100,   "effective_mixed_dps"};  --Mixed DPS with melee flyer adjustment (for cost calcs)
        defense_domain          = {60,    "armour"};
        rank_domain             = {5,     "creature_rank"}; --NOTE: rank value changes based on ability requirements; rank_doman[2] is thus updated later.
        landspeed_domain        = {45,    "speed_max"};
        waterspeed_domain       = {47,    "waterspeed_max"};
        airspeed_domain         = {40,    "airspeed_max"};
        mobility_domain         = {60,    "mobility"};
        sight_domain            = {50,    "sight_radius1"};
        herd_boost_domain       = {700,  "herding_ehp_bonus"}; -- Extra EHP gained from herding (about 700 for musk ox blue whale!)
        null_domain             = {1,     "null"};

        --Use the null domain when you don't want to scale on either (or both) of the x and y axes.
        --To get a constant unscaled cost, set all xy numbers to 0 and then set x0y0 to equal your desired cost.

        --A NOTE ON BALANCING WITH ABILITY REF POINTS:
        --Select your domains based on what two factors you want to influence the cost of the ability.
        --For example, if you want to balance an ability based on EHP and damage, select those as your domains.
        --This will have the effect of letting you balance an ability to benefit either glassy or meaty units.
        --ADVANCED NOTE: SuiCo for "average" [Norbert] units is around 27, though it changes with level.
        --SUPERADVANCED NOTE: It's possible to rewrite this system to use gradients and shapevalue; this would allow us
        --to completely remove the domains, but it's a little less clear to understand.

    ------------------------
    ------------------------
    -- Effective Mobility --
    ------------------------
    ------------------------

        --Now we calculate effective mobility. Note: only having landspeed is the default case (speed = speed_max).
        if (has_flying == 1) then
            setattribute("mobility", Attr( "airspeed_max" )* mobility_flyer_factor);
        else
            setattribute("mobility",ShapeValueCurve(landspeed_domain, waterspeed_domain, 0, 45, 35, 55));
        end

    --------------------------
    --------------------------
    ------ Range Power -------
    --------------------------
    --------------------------

        -- Now we sort out power and costs on ranged attacks. The following code also
        -- determines how to charge multiple ranged attacks.
        -- NOTE: It is possible, using this method, that combining ranged attacks could
        -- result in unintended cost discounts for very exotic art/range combos.
        if ( has_range == 1 ) then
            -- Ask if one of the range attacks is sonic.
            if ( has_sonic == 1 ) then
                    setattribute("range_damage_distance", ShapeValueCurve(range_dps_domain, distance_domain, 0, 5, 35, 380));

            elseif ( has_direct == 1 ) then  -- Ask if one of the range attacks is not artillery.
                    --setattribute("range_damage_distance", ShapeValueCurve(range_dps_domain, distance_domain, 0, 10, 10, 363));
                    -- below is ok, but short range is still a bit too pricey:
                    --setattribute("range_damage_distance", ShapeValueCurve(range_dps_domain, distance_domain, 0, 5, 30, 363));
                    setattribute("range_damage_distance", ShapeValueCurve(range_dps_domain, distance_domain, 0, 0, 30, 363));

            else -- Then we've got only an artillery attack.
                --Note that artillery dist_dam is a function of distance and damage, and then cost is a function of
                --dist_dam and distance, essentially allowing us to charge exponentially for distance.
                setattribute( "range_damage_distance", ShapeValueCurve(artillery_dps_domain, distance_domain, 0, 0, 8, 250));
            end

            setattribute("summed_damage", Attr("range_damage_distance") + Attr("melee_damage"))
        end

        if (has_range == 1) then
            if has_flying == 1 then --Flyer?
                if Attr("has_artillery") == 1 then
                    setattribute("mixed_dps", ShapeValueCurve(melee_dps_domain, dist_dam_domain, 0, 30, 110, 120));
                    setattribute("effective_mixed_dps", ShapeValueCurve(eff_melee_dps_domain, dist_dam_domain, 0, 30, 110, 120));
                else
                    -- For flying direct range, ranged distance is basically useless (theoretically), so just set RDD to damage multiplied by the flyer_damage_mult.
                    setattribute( "range_damage_distance", Attr("range_damage") * damage_flyer_factor);
                    setattribute("mixed_dps", ShapeValueCurve(melee_dps_domain, dist_dam_domain, 0, 20, 90, 80));
                    setattribute("effective_mixed_dps", ShapeValueCurve(eff_melee_dps_domain, dist_dam_domain, 0, 20, 90, 80));
                end
            else --Otherwise, not a flyer.
                --Primtive fix for high-melee art; mixed DPS is just set manually to never go below melee DPS.                
                mixed_dps = ShapeValueCurve(melee_dps_domain, dist_dam_domain, 0, 50, 90, 100);
                setattribute("mixed_dps", max(Attr( "melee_damage" ), mixed_dps));
                setattribute("effective_mixed_dps", Attr("mixed_dps"));
            end
        else
            setattribute("mixed_dps", Attr( "melee_damage" ));
            setattribute("effective_mixed_dps", Attr("effective_melee"));
        end

    -----------------
    -----------------
    -----ranking-----
    -----------------
    -----------------

        setattribute( "Power", Power(Attr("ehp"), Attr("mixed_dps")) );

        rank_cmp = {
            RankTable[1][max_pow],
            RankTable[2][max_pow],
            RankTable[3][max_pow],
            RankTable[4][max_pow],
            --Anything over level 4's max_pow will be level 5.
        };

        setattribute("power_rank", Rank( Attr("Power"), rank_cmp ));



    -----------------
    -----------------
    ----Size Hack----
    -----------------
    -----------------

        if Attr( "size" ) == 10 then
            setattribute("size", 9);
        elseif Attr( "size" ) > 10 then
            setattribute("size", 10);
        end

    -----------------
    -----------------
    --ability costs--
    -----------------
    -----------------

        -- Ability type constants.
        ABT_Ability = 1;
        ABT_Melee = 2;
        ABT_Range = 3;

        -- Functions that are called with the ability id parameter and return a 1 if the ability is present.
        -- These correspond to the ability type constants above.
        ABT_CheckFunctions =
        {
            Attr,
            hasmeleedmgtype,
            hasrangedmgtype,
        };

        --The following abilities and damagetypes are missing from the table as they've been made redundant:
        --{ ABT_Ability, 	"poison_bite",          3, null_domain,     null_domain,            0,      0,      0,      0   },
        --{ ABT_Ability, 	"poison_sting",         3, null_domain,     null_domain,            0,      0,      0,      0   },
        --{ ABT_Ability, 	"poison_pincers",       3, null_domain,     null_domain,            0,      0,      0,      0   },

        --{ ABT_Range, 	DT_VenomSpray, 			3, null_domain,     null_domain,            0,   	0,	    0,      0   },	--DEFUNCT, now only poison is used.
        --Also note that a special 10th column is added to the table if an ability is found; this will carry the ability's calculated cost for later.
        AbilityRefPoints =
        {
        --{ ability_type,    ability_id, minimum_level, x_domain,            y_domain,      x0y0_cost, x1y0_cost, x0y1_cost, x1y1_cost}
            { ABT_Ability, 	"flash", 			      1, rank_domain, 	      null_domain,           15,     55, 	15,     55  },
            { ABT_Ability, 	"headflashdisplay", 	  1, rank_domain, 	      null_domain,           15,     55, 	15,     55  },
            { ABT_Ability, 	"stink_attack", 		  1, rank_domain, 	      null_domain,           0,      50, 	0,      50  },
            { ABT_Ability, 	"assassinate", 			  1, rank_domain, 	      null_domain,          -10,     90,    -10,     90  },
            { ABT_Ability, 	"can_SRF", 			      2, rank_domain, 	      null_domain,           20,     45, 	20,     45  },
            { ABT_Ability, 	"AutoDefense", 	          1, rank_domain,         null_domain, 	         0,      20,     0,     20  },
            { ABT_Ability, 	"plague_attack", 	      1, rank_domain,         null_domain, 	         5,      80,     5,      80  },
            { ABT_Ability,  "sonar_pulse",            1, rank_domain,         null_domain,           10,     35,     10,     35  },
            { ABT_Ability, 	"quill_burst",            2, rank_domain,         null_domain,           10,     35,     10,     35  },
            { ABT_Ability, 	"electric_burst",     	  1, rank_domain, 	      null_domain, 	         20,     170,    20,     170 },
            { ABT_Ability, 	"web_throw",     	      3, rank_domain, 	      null_domain, 	         20,     90,     20,     90  },
            { ABT_Ability, 	"poison_touch",     	  3, rank_domain, 	      null_domain, 	        -20,     80,    -20,     80  },
            { ABT_Ability, 	"poplow",                 1, null_domain,         null_domain,           0,      0,      0,      0   },	--special
            { ABT_Ability, 	"poplowtorso",            1, null_domain,         null_domain,           0,      0,      0,      0   },	--special
            { ABT_Ability, 	"is_swimmer",             1, null_domain,         null_domain,           0,      0,      0,      0   },	--special
            { ABT_Ability,  "keen_sense",             1, null_domain,         null_domain,           10,     0,      0,      0   },
            { ABT_Ability,  "infestation",            2, mobility_domain,     cost_ehp_domain,       10,     25,     20,     27.5  },
            { ABT_Ability,  "end_bonus",              1, null_domain,         null_domain,           5,      0,      0,      0   },
            { ABT_Ability, 	"loner",     			  2, power_domain, 	      null_domain, 	         100,    600,    100,    600 },
            { ABT_Ability, 	"overpopulation",         1, power_domain,        null_domain,           0,      200,    0,      200 },
            { ABT_Ability,  "soiled_land",            3, mobility_domain,     rank_domain,           30,     90,     50,     110 },
            { ABT_Ability, 	"is_immune", 		      1, power_domain, 	      defense_domain, 	     10,     60,     30,     90  },
            { ABT_Ability, 	"deflection_armour",      2, cost_ehp_domain,     rank_domain,           10,     260,    20,     400 },
            { ABT_Ability, 	"herding", 			      1, herd_boost_domain,   eff_mixed_dps_domain,  0,      150,    25,     350 },
            { ABT_Ability, 	"pack_hunter", 		      1, cost_ehp_domain,     eff_mixed_dps_domain,  0,      190, 	160, 	500 },
            { ABT_Ability, 	"is_stealthy", 		      1, cost_ehp_domain,     eff_mixed_dps_domain,  0,      90,     200, 	300 },
            { ABT_Ability, 	"can_dig", 			      1, cost_ehp_domain,     eff_mixed_dps_domain,  0,      60, 	150, 	210 },
            { ABT_Ability, 	"regeneration", 	      1, cost_ehp_domain,     eff_mixed_dps_domain,  0,      160, 	140,    290 },
            { ABT_Ability, 	"frenzy_attack", 	      1, cost_ehp_domain,     eff_mixed_dps_domain,  0,      80, 	130, 	350 },
            { ABT_Ability, 	"is_flyer",     		  1, null_domain, 	      null_domain, 	         0,      0,      0,      0   },
            { ABT_Ability, 	"ranged_piercing", 	      1, cost_ehp_domain,     range_dps_domain,      0,      50, 	 80, 	200 },
            { ABT_Ability, 	"leap_attack", 	          2, cost_ehp_domain,     eff_melee_dps_domain,  5,      25,     35,     60  },
            { ABT_Ability, 	"charge_attack", 	      2, cost_ehp_domain,     eff_melee_dps_domain,  20,     45,     65,     80  },
            { ABT_Ability,  "flyer_direct_range",     1, cost_ehp_domain,     range_dps_domain,      0,      95,     80,     250 },
            { ABT_Ability,  "non_flyer_direct_range", 1, null_domain,         null_domain,           0,      0,      0,      0   },  --special case, but it really shouldn't be... TODO: fix this
            { ABT_Ability,  "has_artillery",          1, dist_dam_domain,     distance_domain,       0,      20,     75,     225 },
            { ABT_Ability,  "overpopulation",         1, rank_domain,         null_domain,           20,     100,    1,      100 },

            { ABT_Range, 	DT_Electric, 		      2, null_domain,         null_domain,           0,      0, 	 0,	     0   },	--special
            { ABT_Range, 	DT_Sonic, 			      2, null_domain,         null_domain,           0,   	 0,	     0,      0   },	--special
            { ABT_Range, 	DT_Poison,	              3, rank_domain,         null_domain,          -20,     40,    -20,     40  },	--Cost for chemical artillery (which has the melee poison damagetype).
 
            { ABT_Melee,    DT_Poison,                3, rank_domain,         null_domain,          -20,     80,    -20,     80  },
            { ABT_Melee, 	DT_HornNegateFull, 	      2, rank_domain,         null_domain,           10,     50,     10, 	 50  },
            { ABT_Melee, 	DT_BarrierDestroy,        1, ehp_domain,          melee_dps_domain,      0,      5,      60,     100 },
            { ABT_Melee, 	DT_HornNegateArmour,      1, cost_ehp_domain,     eff_melee_dps_domain, -10,     100, 	180, 	 530 }
        };

        --The variables below describe what each column of the AbilityRefPoints table represents.
        --"rc" is "Reference Column".
        rc_ability_type = 1;
        rc_id = 2;
        rc_min_rank = 3;
        rc_x_dom = 4;
        rc_y_dom = 5;
        rc_x0y0_cost = 6;
        rc_x1y0_cost = 7;
        rc_x0y1_cost = 8;
        rc_x1y1_cost = 9;
        ability_calculated_cost = 10;
        
        

        --First find min rank for all abilities.
        ability_rank = Attr("power_rank");

        --pairsStart
        for n, ab in AbilityRefPoints do
            --pairsEnd
            -- If we have this ability...
            if ABT_CheckFunctions[ab[rc_ability_type]]( ab[rc_id] ) == 1 then

                -- check for min rank.
                ability_rank = max(ability_rank, ab[rc_min_rank]);
            end
        end

        setattribute( "creature_rank",  max( Attr("power_rank"), ability_rank ) );

        --Now we add ability costs.
        charged_for_poison = 0;
        --pairsStart
        for n, ab in AbilityRefPoints do
            --pairsEnd

            ab[ability_calculated_cost] = 0;

            --If we have this ability...
            if ABT_CheckFunctions[ab[rc_ability_type]]( ab[rc_id] ) == 1 then

                ability_cost = ShapeValueCurve(ab[rc_x_dom], ab[rc_y_dom],
                        ab[rc_x0y0_cost], ab[rc_x1y0_cost], ab[rc_x0y1_cost], ab[rc_x1y1_cost]);

                -- Let's add a mobility cost to barrier destroy
                if (ab[rc_id] == DT_BarrierDestroy) then
                    mobility_fraction_on_domain = Attr("mobility") / mobility_domain[dom_max]
                    ability_cost = ability_cost * ((1.0 + mobility_fraction_on_domain) * 3.4)
                    end


                --If we have either melee or ranged poison DT, don't charge for poison touch.
                if (ab[rc_id] == "poison_touch" or ab[rc_id] == DT_Poison) then
                    if charged_for_poison == 0 then
                        charged_for_poison = 1;
                        ab[ability_calculated_cost] = ability_cost;
                    end

                -- Give pack hunter ranged units a tax (range units get more benefit from pack due to their ability to stack)
                elseif (ab[rc_id] == "pack_hunter" and has_range == 1) then
                    ab[ability_calculated_cost] = ability_cost * range_pack_hunter_mult;

				-- Zero out herding cost if it has no benefit; this should fall naturally out of the equations 
				-- (domains should have 0 at 0 herd-bonus) but those costs don't quite shake out nicely.
				elseif (ab[rc_id] == "herding" and Attr("herding_ehp_bonus") < 1.0) then
                    ab[ability_calculated_cost] = 0;

                --Poplow isn't charged on a curve.
                elseif (ab[rc_id] == "poplow" or ab[rc_id] == "poplowtorso") and ((Attr( "scaling_size" ) - Attr("creature_rank"))/2) > 1.0 then
                    poplow_benefit = floor(min(Attr("creature_rank") + 1, (Attr( "scaling_size" ) - Attr("creature_rank"))) / 2);
                    ab[ability_calculated_cost] = poplow_benefit * 10;

                elseif (ab[rc_id] == "has_artillery") and (has_flying == 1) then
                    ab[ability_calculated_cost] = ability_cost * flying_artillery_elec_mult;

                elseif (ab[rc_id] == "non_flyer_direct_range") then -- This should definitely just be on a curve!
                    if (has_sonic == 1) then
                        ab[ability_calculated_cost] = Attr("range_damage_distance") * sonic_elec_mult;
                    else
                        ab[ability_calculated_cost] = Attr("range_damage_distance") * direct_range_elec_mult;
                    end

                --All other abilities:
                else
                    ab[ability_calculated_cost] = ability_cost;
                end
            end
        end

    -----------------
    -----------------
    ----cost mods----
    -----------------
    -----------------
        
        --cost_power equation (power with a 10% rebate for defense, used for calculating costs).
        --Note that below we employ the ehp_flyer_factor directly onto hitpoints; multiplying hp by a factor and then calculating ehp
        --has the exact same result as multiplying ehp by that same factor.
        defense_rebate_ehp = ( Attr( "hitpoints" ) * ehp_flyer_factor ) / ( 1-(Attr( "armour" ) * defense_cost_multiplier) );
        --edit flag
	cRank = Attr("creature_rank");
    cMelee = Attr("melee_damage");
    cRanged = Attr("range_damage");
    cHealth = defense_rebate_ehp;
    cDps = Attr("effective_mixed_dps")
	cost_power = Power(defense_rebate_ehp,Attr("effective_mixed_dps"),Attr("creature_rank"));
    --cost_power = Power((cHealth ^ 2 / extra_rank(cRank) * (0.61+cMelee/62) * ((0.10 + (0.04 - max(0,(0.02 * max(cRank-2,1))))) / ((cMelee) + range_comp(cMelee,cRanged,cRank) + meat_comp(cMelee,cRanged,cRank))/ level_tune(cRank)) * glass_if((cMelee+cRanged), cRank))/(ehp_flyer_factor * 2 ), 1.5*cDps*mid_melee(cMelee,cRanged,cRank)); 
        -- removed lines from equations
        -- orginal glass if: (1+((Attr("melee_damage")*(Attr("melee_damage")))/Attr("creature_rank")/4) * (((((Attr("melee_damage") + Attr("range_damage")) * 10) > Attr("hitpoints")) and (Attr("melee_damage") > Attr("range_damage"))) and 1 or 0))))
        --range comp: (Attr("melee_damage") * 1 * (((Attr("range_damage") - Attr("melee_damage")) > 2) and 1 or 0)
        --meat comp: + Attr("melee_damage") * 1.8 * (((Attr("effective_mixed_dps") < 7) and (Attr("creature_rank") > 2)) and 1 or 0 )+ 1.8 * Attr("melee_damage") * (((Attr("effective_mixed_dps") < 3)) and (Attr("creature_rank") < 3) and 1 or 0)
        --level comp: / (((Attr("creature_rank") > 3) and 1 or 0) * (Attr("creature_rank")/5 ) + 1)----------------------------
        --mobility cost multiplier--
        ----------------------------

        mobility_cost = ((Attr("mobility")/mobility_divisor)^( (has_flying==1) and flyer_mobility_exp or mobility_exp));

        --------------
        --sight cost--
        --------------

        sightCost = (Attr( "sight_radius1" )-min_sight)*sight_cost_multiplier;

        -- FINAL COST CALCULATION AND SCALING.
        --Intra-level modulator changes the costs of spam units relative to power units.
        intra_level_modulator = (cost_power*1.3/RankTable[Attr("creature_rank")][max_pow])^(RankTable[Attr("creature_rank")][cost_exponent]);
        setattribute("final_cost_scaler", intra_level_modulator);

        --If the unit has direct range or sonic and DOES NOT fly, add a multiplier to coal cost.
        cost_coal = (sightCost + RankTable[Attr("creature_rank")][base_coal_cost] * mobility_cost * 1.1 * ((Attr("non_flyer_direct_range") == 1) and ranged_coal_cost_mult or 1)) * Attr("final_cost_scaler");

        total_abilities_cost = 0;

        --pairsStart
        -- This is where we scale all our previously-calculated ability costs.
        for n, ab in AbilityRefPoints do
        --pairsEnd
            if ab[ability_calculated_cost] > 0.0 then

                ability_name = ab[rc_id];

                --First, if we're dealing with a dt, we need to grab the string associated with it.
                --The first check makes sure ability_name is not a string.
                if ab[rc_ability_type] == ABT_Melee or ab[rc_ability_type] == ABT_Range then
                    for i, string_pair in DTStringTable do
                        if string_pair[dt_number] == ability_name then
                            ability_name = string_pair[dt_string];
                        end
                    end
                end

                --Let's not scale assassinate; logically I don't think it should be any cheaper on spam than it is on power.
                if ability_name == "assassinate" then
                    total_abilities_cost = total_abilities_cost + ab[ability_calculated_cost];
                else
                    scaled_ability_cost = ab[ability_calculated_cost] * Attr("final_cost_scaler");
                    setattribute("===--------------->>"..ability_name.."_cost", scaled_ability_cost);

                    total_abilities_cost = total_abilities_cost + scaled_ability_cost;
                end
            end
        end

        cost_elec = total_abilities_cost;
    
    -----------------
    -----------------
    -----outputs-----
    -----------------
    -----------------

        --Popspace calc. NOTE: Pop space is capped at creature level + 1.
        if (Attr("poplow") == 1) or (Attr("poplowtorso") == 1) then
            Pop = min(ceil(max(1, Attr( "scaling_size" ) - Attr("creature_rank")) / 2), Attr("creature_rank") + 1);
        else
            Pop = min(max(1, Attr( "scaling_size" ) - Attr("creature_rank")), Attr("creature_rank") + 1);
        end

        --Buildtime calc
        --Overpop buildtime multiplier
        if (Attr("underpopulation") == 1) then
            setattribute("overpopulation", 0);
        
            build_time_multiplier = 2.5;
            setattribute("melee_damage", Attr("melee_damage") + UnderPop[cRank]);
            setattribute("armor", Attr("armor") + UnderPop[cRank]);
            setattribute("sight_radius1", Attr("sight_radius1") + UnderPop[cRank])
            if (Attr("speed_max") > 0) then
                setattribute("speed_max", Attr("speed_max") + UnderPop[cRank]);
            end
            if (Attr("waterspeed_max") > 0) then
                setattribute("waterspeed_max", Attr("waterspeed_max") + UnderPop[cRank]);
            end
            if (Attr("airspeed_max") > 0) then
                setattribute("airspeed_max", Attr("airspeed_max") + UnderPop[cRank]);
            end
            
        else
            
            if (Attr("overpopulation") == 1) then
                build_time_multiplier = 0.5;
            else
                build_time_multiplier = 1.0;
            end
        
        end
        --Overpop buildtime multiplier
        

        -- Build time equation
        build_time = (30 * Attr("creature_rank"))*((Attr("Power")*1.2/RankTable[Attr("creature_rank")][max_pow])^1.2)*build_time_multiplier;

        overpop_adjusted_min_build = ((has_flying==1) and flyer_min_build_time or min_build_time);
        setattribute("creature_rank", ( ((has_flying == 1) and (cRank == 1)) and 2 or cRank) );
        --set minimum build time
        if Attr("overpopulation") == 1 then
            overpop_adjusted_min_build = overpop_adjusted_min_build / 2;
        end

        build_time = max(build_time, overpop_adjusted_min_build);
        setattribute("constructionticks", build_time);
        
        --Final Output
        setattribute( "cost", cost_coal );
        setattribute( "costRenew", cost_elec );
        setattribute( "popsize", Pop );

    --deleteStart

    -----------------
    -----------------
    -------ui--------
    -----------------
    -----------------

        --deleteStart

        -- Attribute data column ids.
        AT_Name = 1;
        AT_ZeroOK = 2;
        AT_Min = 3;
        AT_Max = 4;
        AT_RankList = 5;
        AT_UIName = 6;
        AT_UIScale = 7;

        -- Game attribute bound and rank data.
        AttributeData =
        {
            -- { attribute name, zero ok, min, max, rank list, ui attribute name, game->ui scale factor }

            { "hitpoints",  nil, 1, nil, {0.0, 224.0, 349.0, 574.0}, "health", 1 },
            { "armour", 1, 0, nil, {0.0, 0.15, 0.30, 0.45}, "armour", 100 },
            { "speed_max", 1, min_landspeed, nil, {15.0, 21.0, 26.0, 31.0}, "landspeed", 1 },
            { "waterspeed_max", 1, min_waterspeed, nil, {12.0, 20.0, 25.0, 30.0}, "waterspeed", 1 },
            { "airspeed_max", 1, min_airspeed, nil, {16.0, 20.0, 24.0, 28.0}, "airspeed", 1 },
            { "sight_radius1", nil, nil, nil, {20.0, 30.0, 35.0, 45.0}, "sightradius", 1 },
            { "scaling_size", nil, 1, nil, {0, 3, 6, 9}, "size", 1},

            { "melee_damage", 1, 0, nil, {1.0, 10.0, 17.0, 26.0}, "damage",  1 },
            { "range2_max", 1, 0, nil, {1.0, 8.0, 14.0, 21.0}, "range2_max", 1 },
            { "range4_max", 1, 0, nil, {1.0, 8.0, 14.0, 21.0}, "range4_max", 1 },
            { "range5_max", 1, 0, nil, {1.0, 8.0, 14.0, 21.0}, "range5_max", 1 },
            { "range8_max", 1, 0, nil, {1.0, 8.0, 14.0, 21.0}, "range8_max", 1 },
            { "range3_max", 1, 0, nil, {1.0, 8.0, 14.0, 21.0}, "range3_max", 1 },
        };

        -- Accesses the "show_power" or "show_build_time" variable from attr_parameters.
        if (AttrParameters.show_power == 1) then
            AttributeData[6] = { "Power", nil, nil, nil, {rank2pow, rank3pow, rank4pow, rank5pow}, "sightradius", 1 }
        elseif (AttrParameters.show_build_time == 1) then
            AttributeData[6] = { "constructionticks", nil, nil, nil, {1, 40, 80, 120}, "sightradius", 1 }
        end

        -- Accesses "show_ehp" from attr_parameters.
        if (AttrParameters.show_ehp == 1) then
            AttributeData[1] = { "ehp", nil, 1, nil, {1, 200, 400, 600}, "health", 1}
        end

        -- Accesses "show_pop_space" from attr_parameters.
        if (AttrParameters.show_pop_space == 1) then
            AttributeData[7] = { "popsize", nil, 1, nil, {0, 2, 4, 6}, "size", 1}
        end

        -- Apply UI boundaries and UI rank attributes.

        for k, at in AttributeData do
            local attribute = at[AT_Name];
            local val = 0;
            local rating = 1;

            if checkgameattribute( attribute ) == 1 then

                val = Attr( attribute );

                -- Ranking.
                if at[AT_RankList] then
                    rating = Rank( val, at[AT_RankList]);
                end
            end

            if at[AT_UIName] then
                -- Add the rating to the creature's variable list -- rating is in the range [0-4].
                
                setattribute( at[AT_UIName].. "_rating", rating - 1 );
                -- Add the display version to the creature's variable list.
                setattribute( at[AT_UIName] .. "_val", val * at[AT_UIScale] );
            end

        end

        --Sets UI for damage icon and values of ranged attacks.
        --pairsBelow
        for index, part in BodyPartsThatCanHaveRange do
            --endPairs
            if checkgameattribute( "range"..part.."_damage" ) == 1 then
                val = Attr( "range"..part.."_damage" ) + ((Attr("underpopulation") == 1) and UnderPop[cRank] or 0);
                rating = Rank( val, {-1.0,12.0,20.0,26.0} ,Attr("is_flyer"));

                --It seems like for UI purposes, a creature is only considered "ranged" if it has ranged attributes
                --on part 2 or part 4. So for our stocks with non-2-or-4 range parts, we have to first create fake
                --ranged attributes on part 2; then we can create our attributes for the part we actually want,
                --and it all seems to work fine.
                if (part ~= 4 and part ~= 2) then
                    setattribute( "range2_damage_rating", rating - 1 );
                    setattribute( "range2_damage_val", val );
                end

                setattribute( "range"..part.."_damage_rating", rating - 1 );
                setattribute( "range"..part.."_damage_val", val );
            end
        end

        --deleteEnd
end
    --deleteEnd