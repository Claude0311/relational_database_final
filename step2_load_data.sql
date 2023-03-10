DELETE FROM team;
DELETE FROM owns;
DELETE FROM trainer;
DELETE FROM pokemon;
DELETE FROM know;

INSERT INTO know VALUES
    (171, 92),
    (171, 56),
    (171, 58),
    (171, 86),
    (171, 204),
    (171, 268),
    (171, 297),
    (171, 299),
    (171, 315),
    (171, 330),
    (171, 142),
    (171, 345);

INSERT INTO pokemon (pkm_id, pkdex, mv_id_1, mv_id_2, mv_id_3, mv_id_4) VALUES
    (1, 171, 56, 86, 297, 268),
    (2, 171, 142, 345, 330, 315),
    (3, 171, 299, 297, 268, 204),
    (4, 171, 92, 56, 58, 86);

INSERT INTO trainer VALUES
    (1, 'Jeff', 'jeff123'),
    (2, 'Joshua', 'josh321');

INSERT INTO owns VALUES 
    (1, 1),
    (2, 2),
    (1, 3),
    (2, 4);


INSERT INTO team (trainer_id, pkm_id_1, pkm_id_2) VALUES
    (1, 1, 3),
    (2, 2, 4);
