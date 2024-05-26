-- Use the below parameters to show various hidden attributes of your creatures in the army builder!
-- You don't need to restart IC to see the changes; if you're in army builder and you want to see your creature's power, you can simply minimize,
-- change the 0 for show_power below to 1, and then when you head back into IC and change a body part on your critter, you'll see power instead of sight radius.
-- NOTE: MAKE SURE you reset all of these to zero (or use the AttrParameters Override addon) before you try to play online, otherwise you may have compatability issues!
-- NOTE 2: Make sure you're using the -moddev launch parameter when you edit this file; otherwise your edits will be reversed when you launch the game.

AttrParameters = {
    show_power      = 1,    -- Replaces Sight Radius with Power (OVERRIDES show_build_time)
    show_build_time = 0,    -- Replaces Sight Radius with Build Time
    show_ehp        = 0,    -- Replaces Health with EHP
    show_pop_space  = 0,    -- Replaces Size with Pop Space
    six_rods        = 0     -- Experimental measure to allow 6 rods that each generate 1.5 elec/s
}