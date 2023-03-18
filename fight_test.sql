SET @p1 = 1;
SET @p2 = 2;

CALL enter_fight(1,2);

CALL one_turn(@p1, @p2, 92, 86, NULL, NULL, @winner, @f1, @f2);
CALL one_turn(@p1, @p2, 58, 435, NULL, NULL, @winner, @f1, @f2);

SELECT * FROM fight_log;
SELECT * FROM fighting_status;

SELECT pkm_name FROM pokedex
    WHERE ele_type_1='water' or ele_type_2='water';

CREATE INDEX ele_index ON pokedex(ele_type_1, ele_type_2);

SELECT pkm_name FROM pokedex
    WHERE ele_type_1='water' or ele_type_2='water';

DROP INDEX ele_index ON pokedex;
