DELETE FROM team;
DELETE FROM owns;
DELETE FROM trainer;
DELETE FROM pokemon;

SELECT * FROM pokedex NATURAL JOIN know NATURAL JOIN movepool
    WHERE pkdex = 91;

INSERT INTO pokemon (pkm_id, pkdex, mv_id_1, mv_id_2, mv_id_3, mv_id_4) VALUES
    (1, 171, 58, 59, 61, 85),
    (2, 171, 86, 87, 92, 97),
    (4, 171, 103, 104, 133, 145),
    (5, 91, 41, 42, 43, 59);

INSERT INTO trainer VALUES
    (1, 'Jeff', 'jeff123'),
    (2, 'Joshua', 'josh321');

INSERT INTO owns VALUES 
    (1, 1),
    (2, 2),
    (1, 5),
    (2, 4);


INSERT INTO team (trainer_id, pkm_id_1, pkm_id_2) VALUES
    (1, 1, 5),
    (2, 2, 4);
