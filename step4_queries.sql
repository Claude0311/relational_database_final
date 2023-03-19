-- These are the queries we used in the python scripts

-- sometimes error can happen when register and a trainer won't have a team
-- we use team LEFT JOIN trainer to make sure only trainer with a team can join the battle
SELECT trainer_id, trainer_name
    FROM team LEFT JOIN trainer USING(trainer_id)
    WHERE trainer_name='cynthia';

-- show all moves that a pokemon can learn
SELECT mv_id, move_name 
FROM pokedex 
NATURAL JOIN know 
NATURAL JOIN movepool 
WHERE pkdex = 1;

