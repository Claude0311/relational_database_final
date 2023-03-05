CALL enter_fight(1,2);
CALL one_turn(1, 2, 56, 58, NULL, NULL, @winner);
CALL one_turn(1, 2, 86, 435, NULL, NULL, @winner);

SELECT * FROM fight_log;
SELECT * FROM fighting_status;