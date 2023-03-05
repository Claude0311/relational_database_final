INSERT INTO nature_table (nature_id, nature, nature_atk, nature_spatk) VALUES 
    (15, 'modest', 0.9, 1.1);

INSERT INTO pokedex VALUES
    (171, 'Lanturn', 'water', 'electric', 125, 58, 58, 76, 76, 67);

INSERT INTO movepool VALUES
    (56, 'Hydro Pump', 'water', 5, 0, 'special', 120, 80, NULL, NULL, NULL, 1, 1),
    (58, 'Ice Beam', 'ice', 10, 0, 'special', 90, 100, 10, 'freeze', 1, 1, 1),
    (86, 'Thunder Wave', 'electric', 20, 0, 'status', NULL, 90, 100, 'paralysis', 1, 1, 1),
    (435, 'Discharge', 'electric', 15, 0, 'special', 80, 120, 30, 'paralysis', 1, 1, 1),
    (92, 'Toxic', 'poison', 10, 0, 'status', NULL, 90, 100, 'badly poison', 1, 1, 1);

DELETE FROM type_chart;
INSERT INTO type_chart VALUES
    ('water', 'electric', 1.0),
    ('electric', 'water', 2.0),
    ('electric', 'electric', 0.5),
    ('water', 'water', 0.5),
    ('ice', 'water', 0.5),
    ('ice', 'electric', 1.0);

INSERT INTO know VALUES
    (171, 92),
    (171, 56),
    (171, 58),
    (171, 86),
    (171, 435);

INSERT INTO pokemon (pkdex, nature_id, mv_id_1, mv_id_2, mv_id_3) VALUES
    (171, 15, 56, 86, 92),
    (171, 15, 58, 435, 92);

INSERT INTO trainer VALUES
    (1, 'Jeff', 'jeff123'),
    (2, 'Joshua', 'josh321');

INSERT INTO owns VALUES 
    (1, 1),
    (2, 2);

INSERT INTO team (trainer_id, pkm_id_1) VALUES
    (1, 1),
    (2, 2);

CALL enter_fight(1,2);