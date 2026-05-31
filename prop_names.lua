--======================================================================
--  prop_names.lua  (shared)
--  A list of prop model NAMES. At runtime we hash each one and build a
--  reverse lookup (hash -> name) so the menu/labels can show a readable
--  name like "prop_bbq_5" instead of a raw hash like "-1380144099".
--
--  GTA has thousands of props and we can't reverse a hash back to text at
--  runtime, so anything not in this list simply shows as its hash number
--  (still fully functional). To add names: just append them to the list.
--  A complete dump can be pasted in here from any prop-name list.
--======================================================================

PropNames = {
    -- BBQ / cooking / park clutter (your floating grill lives here)
    'prop_bbq_1', 'prop_bbq_2', 'prop_bbq_3', 'prop_bbq_4', 'prop_bbq_5',
    'prop_bbq_6', 'prop_bbq_7', 'prop_bbq_8', 'prop_bbq_9', 'prop_bbq_10',
    'prop_food_bs_burg2', 'prop_cooker_03', 'prop_cooker_05',

    -- Benches / chairs / tables
    'prop_bench_01a', 'prop_bench_01b', 'prop_bench_01c', 'prop_bench_02',
    'prop_bench_03', 'prop_bench_04', 'prop_bench_05', 'prop_bench_06',
    'prop_bench_07', 'prop_bench_08', 'prop_bench_09', 'prop_bench_10',
    'prop_bench_11', 'prop_chair_01a', 'prop_chair_01b', 'prop_chair_02',
    'prop_chair_03', 'prop_chair_04a', 'prop_chair_04b', 'prop_chair_05',
    'prop_table_01', 'prop_table_02', 'prop_table_03', 'prop_table_03b',
    'prop_table_04', 'prop_table_04_chr', 'prop_table_05', 'prop_table_06',
    'prop_table_07', 'prop_table_08', 'prop_table_08_chr', 'prop_table_09',
    'prop_table_10', 'prop_table_para', 'prop_picnic_bench_01',

    -- Bins / barrels / boxes
    'prop_bin_01a', 'prop_bin_02a', 'prop_bin_03a', 'prop_bin_04a',
    'prop_bin_05a', 'prop_bin_06a', 'prop_bin_07a', 'prop_bin_07b',
    'prop_bin_07c', 'prop_bin_07d', 'prop_bin_08a', 'prop_bin_08open',
    'prop_bin_09a', 'prop_bin_10a', 'prop_bin_10b', 'prop_bin_11a',
    'prop_bin_11b', 'prop_bin_12a', 'prop_bin_13a', 'prop_bin_14a',
    'prop_barrel_01a', 'prop_barrel_02a', 'prop_barrel_03a',
    'prop_barrel_pile_01', 'prop_barrel_pile_02', 'prop_barrel_pile_03',
    'prop_boxpile_01a', 'prop_boxpile_02a', 'prop_boxpile_03a',
    'prop_boxpile_04a', 'prop_boxpile_05a', 'prop_boxpile_06a',
    'prop_box_wood01a', 'prop_box_wood02a', 'prop_box_wood03a',
    'prop_box_wood04a', 'prop_box_wood05a', 'prop_box_wood06a',

    -- Cones / barriers / construction
    'prop_mp_cone_01', 'prop_mp_cone_02', 'prop_mp_cone_03',
    'prop_roadcone01a', 'prop_roadcone01b', 'prop_roadcone01c',
    'prop_roadcone01d', 'prop_roadcone02a', 'prop_roadcone02b',
    'prop_barrier_work01a', 'prop_barrier_work02a', 'prop_barrier_work04a',
    'prop_barrier_work05', 'prop_barrier_conc_01a', 'prop_barrier_wat_01a',
    'prop_fnclink_02a', 'prop_fnclink_02b', 'prop_fnclink_03a',
    'prop_fnclink_03b', 'prop_fnc_fbi3',

    -- Sports / court (custom basketball court props)
    'prop_basketball_net', 'prop_basketball', 'prop_bball_hoop',
    'prop_skate_flatramp', 'prop_skate_bowl', 'prop_beach_volball01',

    -- Lights / signs / misc street
    'prop_streetlight_01', 'prop_streetlight_02', 'prop_streetlight_03',
    'prop_streetlight_04', 'prop_streetlight_05', 'prop_streetlight_07a',
    'prop_traffic_01a', 'prop_traffic_01b', 'prop_traffic_01d',
    'prop_traffic_02a', 'prop_traffic_03a', 'prop_traffic_03b',
    'prop_sign_road_01a', 'prop_sign_road_02a', 'prop_sign_road_03b',
    'prop_postbox_1a', 'prop_phonebox_01a', 'prop_phonebox_02',
    'prop_fire_hydrant_1', 'prop_fire_hydrant_2', 'prop_fire_hydrant_3',
    'prop_parking_meter', 'prop_parking_pay', 'prop_atm_01', 'prop_atm_02',
    'prop_atm_03', 'prop_vend_soda_01', 'prop_vend_soda_02',
    'prop_vend_water_01', 'prop_vend_snak_01', 'prop_vend_coffe_01',

    -- Plants / nature
    'prop_bush_lrg_04b', 'prop_bush_med_05', 'prop_plant_01a',
    'prop_plant_int_01a', 'prop_plant_int_02a', 'prop_pot_plant_01a',
    'prop_pot_plant_02a', 'prop_pot_plant_03a', 'prop_pot_plant_04a',
    'prop_pot_plant_05a', 'prop_palm_med_01a', 'prop_palm_sm_01a',
    'prop_tree_birch_01', 'prop_tree_birch_02', 'prop_tree_oak_01',

    -- ADD YOUR OWN below this line:
}
