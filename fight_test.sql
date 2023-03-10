SET @p1 = 1;
SET @p2 = 2;

CALL enter_fight(1,2);

CALL one_turn(@p1, @p2, 92, 86, NULL, NULL, @winner, @f1, @f2);
CALL one_turn(@p1, @p2, 58, 435, NULL, NULL, @winner, @f1, @f2);

SELECT * FROM fight_log;
SELECT * FROM fighting_status;