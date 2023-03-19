-- These are the queries we used in the python scripts

-- sometimes error can happen when register and a trainer won't have a team
-- we use team LEFT JOIN trainer to make sure only trainer with a team can join the battle
SELECT trainer_id, trainer_name
    FROM team LEFT JOIN trainer USING(trainer_id)
    WHERE trainer_name='cynthia';

-- The following sql are for RA
-- show all moves that a pokemon can learn
CREATE TEMPORARY TABLE mp1 AS
    SELECT pkdex, mv_id, move_name, movepower 
    FROM pokedex 
    NATURAL JOIN know 
    NATURAL JOIN movepool;

CREATE TEMPORARY TABLE mp2 AS
    SELECT pkdex, mv_id, move_name, movepower
    FROM pokedex 
    NATURAL JOIN know 
    NATURAL JOIN movepool;

-- show the max power move a pokemon can learn
SELECT mp1.pkdex, mp1.mv_id, mp1.move_name, mp1.movepower
    FROM mp1, (
        SELECT pkdex, max(movepower) as movepower
        FROM mp2
        GROUP BY pkdex
    ) test
    WHERE mp1.movepower=test.movepower AND mp1.pkdex=test.pkdex
    ORDER BY mp1.pkdex;
