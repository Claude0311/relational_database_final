LOAD DATA LOCAL INFILE 'pokedex_cleanup.csv' INTO TABLE pokedex
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'movepool_cleanup.csv' INTO TABLE movepool
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'natures.csv' INTO TABLE nature_table
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'type_chart.csv' INTO TABLE type_chart
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'know.csv' INTO TABLE know
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;


DELETE FROM team;
DELETE FROM owns;
DELETE FROM trainer;
DELETE FROM pokemon;

ALTER TABLE trainer AUTO_INCREMENT = 1;

INSERT INTO pokemon (pkm_id, pkdex, mv_id_1, mv_id_2, mv_id_3, mv_id_4) VALUES
    (1,  18, 17, 98, 332, 28),      -- Blue's Pidgeot
    (2,  65, 94, 247, NULL, NULL), -- Blue's Alakazam
    (3, 112, 43, 39, 31, NULL),     -- Blue's Rhydon
    (4, 103, 95, 140, NULL, NULL),  -- Blue's Exeggutor
    (5,  59, 34, 52, NULL, NULL),   -- Blue's Arcanine
    (6,   9, 56, 59, 110, NULL),    -- Blue's Blastoise
    (7, 442, 94, 247, NULL, NULL),  -- Cynthia's Spiritomb
    (8, 423, 330, 188, NULL, NULL), -- Cynthia's Gastrodon
    (9, 407, 188, 412, 247, NULL),  -- Cynthia's Roserade
    (10,350, 58, 406, 56, 59),      -- Cynthia's Milotic
    (11,448, 396, 406, 94, NULL),   -- Cynthia's Lucario
    (12,445, 280, 53, 242, NULL);   -- Cynthia's Garchomp

CALL sp_add_user('Blue', 'blue123');
CALL sp_add_user('Cynthia', 'cyn321');

INSERT INTO owns VALUES 
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (1, 5),
    (1, 6),
    (2, 7),
    (2, 8),
    (2, 9),
    (2, 10),
    (2, 11),
    (2, 12);

INSERT INTO team VALUES
    (1, 1, 2, 3, 4, 5, 6),
    (2, 7, 8, 9, 10, 11, 12);
