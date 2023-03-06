DROP PROCEDURE IF EXISTS enter_fight;
DROP PROCEDURE IF EXISTS one_turn;
DROP PROCEDURE IF EXISTS check_status_case1;
DROP PROCEDURE IF EXISTS check_status_case2;
DROP FUNCTION  IF EXISTS allfainted;
DROP PROCEDURE IF EXISTS handle_switch;
DROP PROCEDURE IF EXISTS handle_surrender;


DELIMITER $$

CREATE PROCEDURE handle_surrender(
    IN player_1_surrender TINYINT,
    IN player_2_surrender TINYINT,
    IN player_1_name VARCHAR(20),
    IN player_2_name VARCHAR(20),
    OUT winner TINYINT
)
BEGIN
    -- Both player surrender
    IF player_1_surrender=1 AND player_2_surrender=1 THEN
        CALL log_to_fight('Both player surrender');
        SET winner = 0;
    ELSE
        -- one of the player surrender
        IF player_1_surrender=1 THEN
            CALL log_to_fight(CONCAT(player_1_name, ' surrenders, ', player_2_name,' wins!'));
            SET winner = 2;
        ELSEIF player_2_surrender=1 THEN
            CALL log_to_fight(CONCAT(player_2_name, ' surrenders, ', player_1_name,' wins!'));
            SET winner = 1;
        ELSE
            SET winner = NULL;
        END IF;
    END IF;
END $$

CREATE PROCEDURE handle_switch(
    INOUT cur_pkm_id INTEGER,
    IN switch_pkm_id INTEGER,
    IN player_name VARCHAR(20),
    OUT cur_pkm_name VARCHAR(20)
)
BEGIN
    -- switch
    IF NOT ISNULL(switch_pkm_id) THEN
        -- reset pkm's atk
        UPDATE fighting_status 
            SET atk=0, def=0, spatk=0, spdef=0, spd=0, acc=0, evasion=0, choosen=0
            WHERE pkm_id=cur_pkm_id;
        -- switch pkm
        SELECT pkm_name INTO cur_pkm_name 
            FROM pokemon NATURAL JOIN pokedex
            WHERE pkm_id=switch_pkm_id;
        UPDATE fighting_status 
            SET choosen=1
            WHERE pkm_id=switch_pkm_id;
        SET cur_pkm_id=switch_pkm_id;
        CALL log_to_fight(CONCAT(player_name, ' switches to ', cur_pkm_name));
    -- don't switch
    ELSE
        SELECT pkm_name INTO cur_pkm_name 
            FROM pokemon NATURAL JOIN pokedex
            WHERE pkm_id=cur_pkm_id;
    END IF; 
    SET cur_pkm_name=CONCAT(player_name, '\'s ', cur_pkm_name);
END $$

CREATE FUNCTION allfainted(
    fainted_pkm_id INTEGER
) RETURNS TINYINT
BEGIN
    DECLARE allfainted TINYINT DEFAULT 0;
    DECLARE owner_id INTEGER;

    SELECT trainer_id INTO owner_id
        FROM fighting_status 
        WHERE pkm_id=fainted_pkm_id;

    SELECT COUNT(pkm_id)=0 INTO allfainted
        FROM fighting_status
        WHERE trainer_id=owner_id AND hp>0;
    RETURN allfainted;
END $$


CREATE PROCEDURE check_status_case1(
    IN cur_pkm_id INTEGER,
    IN pkm_name VARCHAR(20),
    IN switch_pkm_id INTEGER,
    OUT pkm_status VARCHAR(20),
    OUT pkm_status_count INTEGER
)
BEGIN
    SELECT status, status_count 
    INTO pkm_status, pkm_status_count
    FROM fighting_status
    WHERE pkm_id=cur_pkm_id;
    -- reset sleep/poison status if switch
    IF NOT ISNULL(switch_pkm_id) AND pkm_status IN ('sleep', 'badly poison') THEN
        IF status='sleep' THEN 
            UPDATE fighting_status 
                SET status_count=2 + FLOOR(RAND()*4)
                WHERE pkm_id=switch_pkm_id;
        ELSE -- badly poison
            UPDATE fighting_status 
                SET status_count=1
                WHERE pkm_id=switch_pkm_id;
        END IF;
    -- check wake up
    ELSEIF pkm_status='sleep' AND pkm_status_count=0 THEN
        UPDATE fighting_status 
            SET status=NULL, status_count=NULL
            WHERE pkm_id=cur_pkm_id;
        SET pkm_status=NULL;
        SET pkm_status_count=NULL;
        CALL log_to_fight(CONCAT(pkm_name,' wakes up!'));
    -- check 20% chance unfreeze
    ELSEIF pkm_status='freeze' AND RAND()<0.2 THEN
        UPDATE fighting_status 
            SET status=NULL, status_count=NULL
            WHERE pkm_id=cur_pkm_id;
        SET pkm_status=NULL;
        SET pkm_status_count=NULL;
        CALL log_to_fight(CONCAT(pkm_name,' unfreeze!'));
    END IF;
END $$

CREATE PROCEDURE check_status_case2(
    IN cur_pkm_id INTEGER,
    IN pkm_name VARCHAR(50),
    OUT fainted TINYINT
)
BEGIN
    DECLARE pkm_status VARCHAR(20);
    DECLARE pkm_status_count INTEGER;

    SELECT status, status_count 
        INTO pkm_status, pkm_status_count
        FROM fighting_status 
        WHERE pkm_id=cur_pkm_id;

    IF pkm_status='burn' THEN
        UPDATE fighting_status 
            SET hp = GREATEST(hp - GREATEST(FLOOR(max_hp/16), 1), 0)
            WHERE pkm_id=cur_pkm_id;
        CALL log_to_fight(CONCAT(pkm_name, ' is hurt by its burn!'));
    ELSEIF pkm_status='sleep' THEN
        UPDATE fighting_status 
            SET status_count = status_count - 1
            WHERE pkm_id=cur_pkm_id;
    ELSEIF pkm_status='poison' THEN
        UPDATE fighting_status 
            SET hp = GREATEST(hp - GREATEST(FLOOR(max_hp/8), 1), 0)
            WHERE pkm_id=cur_pkm_id;
        CALL log_to_fight(CONCAT(pkm_name, ' is hurt by poison!'));
    ELSEIF pkm_status='badly poison' THEN
        UPDATE fighting_status 
            SET hp = GREATEST(hp - GREATEST(FLOOR(max_hp*status_count/16), 1), 0),
                status_count = LEAST(status_count+1, 15)
            WHERE pkm_id=cur_pkm_id;
        CALL log_to_fight(CONCAT(pkm_name, ' is hurt by poison!'));
    END IF;
    SELECT hp=0 INTO fainted
        FROM fighting_status
        WHERE pkm_id=cur_pkm_id;
    IF fainted THEN 
        CALL log_to_fight(CONCAT(pkm_name, ' fainted!'));
    END IF;
END $$

CREATE PROCEDURE one_turn(
    INOUT pkm_id_1 INTEGER,
    INOUT pkm_id_2 INTEGER,
    IN move_id_1 INTEGER,
    IN move_id_2 INTEGER,
    IN switch_pkm_id_1 INTEGER,
    IN switch_pkm_id_2 INTEGER,
    -- NULL: game not over yet
    -- 0: tie
    -- 1: player 1 win
    -- 2: player 2 win
    OUT winner TINYINT
) NOT DETERMINISTIC
-- check surrender (mv_id and switch are NULL)
-- switch pkm
-- sleep/freeze (wake up / unfroze)
-- compare speed
-- use move 1
--      check paralize / sleep / freeze 
--      deal damage / additional effect
-- check fainted
-- use move 2
--      same as move 1
-- check fainted
-- burn / poison
-- declare variables
ot: BEGIN
    DECLARE player_1_surrender TINYINT DEFAULT 0;
    DECLARE player_2_surrender TINYINT DEFAULT 0;
    DECLARE player_1_name VARCHAR(20);
    DECLARE player_2_name VARCHAR(20);
    DECLARE pkm_1_name VARCHAR(50);
    DECLARE pkm_2_name VARCHAR(50);
    DECLARE pkm_1_status VARCHAR(20);
    DECLARE pkm_2_status VARCHAR(20);
    DECLARE pkm_1_status_count INTEGER;
    DECLARE pkm_2_status_count INTEGER;
    DECLARE pkm_1_goes_first TINYINT DEFAULT 1;
    DECLARE pkm_1_fainted TINYINT DEFAULT 0;
    DECLARE pkm_2_fainted TINYINT DEFAULT 0;
    
    UPDATE fight_log SET isnew=0;
    SET winner = NULL;

    -- check surrender (mv_id and switch are NULL)
    if ISNULL(move_id_1) AND ISNULL(switch_pkm_id_1) THEN SET player_1_surrender=1; END IF;
    if ISNULL(move_id_2) AND ISNULL(switch_pkm_id_2) THEN SET player_2_surrender=1; END IF;
    SELECT trainer_name INTO player_1_name
    FROM owns NATURAL JOIN trainer
    WHERE pkm_id=pkm_id_1;
    SELECT trainer_name INTO player_2_name
    FROM owns NATURAL JOIN trainer
    WHERE pkm_id=pkm_id_2;
    CALL handle_surrender(player_1_surrender, player_2_surrender, player_1_name, player_2_name, winner);
    IF NOT ISNULL(winner) THEN LEAVE ot; END IF;

    -- switch pkm
    CALL handle_switch(pkm_id_1, switch_pkm_id_1, player_1_name, pkm_1_name);
    CALL handle_switch(pkm_id_2, switch_pkm_id_2, player_2_name, pkm_2_name);

    -- sleep/freeze (wake up / unfroze)
    CALL check_status_case1(pkm_id_1, pkm_1_name, switch_pkm_id_1, pkm_1_status, pkm_1_status_count);
    CALL check_status_case1(pkm_id_2, pkm_2_name, switch_pkm_id_2, pkm_2_status, pkm_2_status_count);

    -- compare speed
    -- SET pkm_1_goes_first = 0 / 1

    -- first pkm use move
    -- check paralysis
    IF pkm_1_goes_first=1 THEN
        IF NOT ISNULL(switch_pkm_id_1) THEN
            SELECT * FROM fighting_status WHERE 1=0; -- do nothing
        ELSEIF pkm_1_status='paralysis' AND RAND()<0.25 THEN
            CALL log_to_fight(CONCAT(pkm_1_name, 'is paralyzed. It can\'t move!'));
        ELSEIF pkm_1_status='freeze' THEN
            CALL log_to_fight(CONCAT(pkm_1_name, 'is frozen. It can\'t move!'));
        ELSE
            CALL use_move(pkm_id_1, pkm_id_2, move_id_1, pkm_1_name, pkm_2_name, pkm_2_fainted);
        END IF;
        IF pkm_2_fainted=1 AND allfainted(pkm_id_2)  THEN
            CALL log_to_fight(CONCAT(player_1_name,' wins!'));
            SET winner=1;
            LEAVE ot;
        ELSEIF pkm_2_fainted=0 AND ISNULL(switch_pkm_id_2) THEN
            SELECT status INTO pkm_2_status
                FROM fighting_status
                WHERE pkm_id=pkm_id_2;
            IF pkm_2_status='paralysis' AND RAND()<0.25 THEN
                CALL log_to_fight(CONCAT(pkm_2_name, 'is paralyzed. It can\'t move!'));
            ELSEIF pkm_2_status='freeze' THEN
                CALL log_to_fight(CONCAT(pkm_2_name, 'is frozen. It can\'t move!'));
            ELSE
                CALL use_move(pkm_id_2, pkm_id_1, move_id_2, pkm_2_name, pkm_1_name, pkm_1_fainted);
            END IF;
            IF pkm_1_fainted=1 AND allfainted(pkm_id_1) THEN
                CALL log_to_fight(CONCAT(player_2_name,' wins!'));
                SET winner=2;
                LEAVE ot;
            END IF;
        END IF;
    ELSE
        IF NOT ISNULL(switch_pkm_id_2) THEN 
            SELECT * FROM fighting_status WHERE 1=0; -- do nothing
        ELSEIF pkm_2_status='paralysis' AND RAND()<0.25 THEN
            CALL log_to_fight(CONCAT(pkm_2_name, 'is paralyzed. It can\'t move!'));
        ELSEIF pkm_2_status='freeze' THEN
            CALL log_to_fight(CONCAT(pkm_2_name, 'is frozen. It can\'t move!'));
        ELSE
            CALL use_move(pkm_id_2, pkm_id_1, move_id_2, pkm_2_name, pkm_1_name, pkm_1_fainted);
        END IF;
        IF pkm_1_fainted=1 AND allfainted(pkm_id_1)  THEN
            CALL log_to_fight(CONCAT(player_2_name,' wins!'));
            SET winner=2;
            LEAVE ot;
        ELSEIF pkm_1_fainted=0 AND ISNULL(switch_pkm_id_1) THEN
            SELECT status INTO pkm_1_status
                FROM fighting_status
                WHERE pkm_id=pkm_id_1;
            IF pkm_1_status='paralysis' AND RAND()<0.25 THEN
                CALL log_to_fight(CONCAT(pkm_1_name, 'is paralyzed. It can\'t move!'));
            ELSEIF pkm_1_status='freeze' THEN
                CALL log_to_fight(CONCAT(pkm_1_name, 'is frozen. It can\'t move!'));
            ELSE
                CALL use_move(pkm_id_1, pkm_id_2, move_id_1, pkm_1_name, pkm_2_name, pkm_2_fainted);
            END IF;
            IF pkm_2_fainted=1 AND allfainted(pkm_id_2) THEN
                CALL log_to_fight(CONCAT(player_1_name,' wins!'));
                SET winner=1;
                LEAVE ot;
            END IF;
        END IF;
    END IF;

    -- burn / poison, random order
    IF RAND()<0.5 THEN
        IF pkm_1_fainted=0 THEN CALL check_status_case2(pkm_id_1, pkm_1_name, pkm_1_fainted); END IF;
        IF pkm_1_fainted=1 AND allfainted(pkm_id_1) THEN
            CALL log_to_fight(CONCAT(player_2_name,' wins!'));
            SET winner=2;
            LEAVE ot;
        END IF;
        IF pkm_2_fainted=0 THEN CALL check_status_case2(pkm_id_2, pkm_2_name, pkm_2_fainted); END IF;
        IF pkm_2_fainted=1 AND allfainted(pkm_id_2) THEN
            CALL log_to_fight(CONCAT(player_1_name,' wins!'));
            SET winner=2;
            LEAVE ot;
        END IF;
    ELSE
        IF pkm_2_fainted=0 THEN CALL check_status_case2(pkm_id_2, pkm_2_name, pkm_2_fainted); END IF;
        IF pkm_2_fainted=1 AND allfainted(pkm_id_2) THEN
            CALL log_to_fight(CONCAT(player_1_name,' wins!'));
            SET winner=2;
            LEAVE ot;
        END IF;
        IF pkm_1_fainted=0 THEN CALL check_status_case2(pkm_id_1, pkm_1_name, pkm_1_fainted); END IF;
        IF pkm_1_fainted=1 AND allfainted(pkm_id_1) THEN
            CALL log_to_fight(CONCAT(player_2_name,' wins!'));
            SET winner=2;
            LEAVE ot;
        END IF;
    END IF;
END $$

-- procedure that executed when two trainer enter fight
CREATE PROCEDURE enter_fight (
    trainer_id_1 INTEGER,
    trainer_id_2 INTEGER
)
BEGIN
    DECLARE tmp_pkm_id_1 INTEGER;
    DECLARE tmp_pkm_id_2 INTEGER;
    DECLARE tmp_pkm_id_3 INTEGER;
    DECLARE tmp_pkm_id_4 INTEGER;
    DECLARE tmp_pkm_id_5 INTEGER;
    DECLARE tmp_pkm_id_6 INTEGER;
    DECLARE tmp_trainer_id INTEGER;
    DECLARE tmp_trainer_name VARCHAR(20);
    DECLARE first_pkm_name VARCHAR(20);
    DECLARE train_count INTEGER DEFAULT 0;

    DELETE FROM fighting_status;
    DELETE FROM fight_log;

    WHILE train_count < 2 DO
        SET train_count = train_count + 1;
        IF train_count=1 THEN
            SET tmp_trainer_id = trainer_id_1;
        ELSE
            SET tmp_trainer_id = trainer_id_2;
        END IF;

        SELECT 
            pkm_id_1,
            pkm_id_2,
            pkm_id_3,
            pkm_id_4,
            pkm_id_5,
            pkm_id_6
        INTO 
            tmp_pkm_id_1,
            tmp_pkm_id_2,
            tmp_pkm_id_3,
            tmp_pkm_id_4,
            tmp_pkm_id_5,
            tmp_pkm_id_6
        FROM team
        WHERE trainer_id=tmp_trainer_id;

        INSERT IGNORE INTO fighting_status (trainer_id, pkm_id, choosen) VALUES
            (tmp_trainer_id, tmp_pkm_id_1, 1),
            (tmp_trainer_id, tmp_pkm_id_2, 0),
            (tmp_trainer_id, tmp_pkm_id_3, 0),
            (tmp_trainer_id, tmp_pkm_id_4, 0),
            (tmp_trainer_id, tmp_pkm_id_5, 0),
            (tmp_trainer_id, tmp_pkm_id_6, 0);

        SELECT trainer_name INTO tmp_trainer_name
            FROM trainer
            WHERE trainer_id=tmp_trainer_id;

        SELECT pkm_name INTO first_pkm_name
            FROM pokemon NATURAL JOIN pokedex
            WHERE pkm_id=tmp_pkm_id_1;
        
        CALL log_to_fight(CONCAT(tmp_trainer_name, ' enter battle!'));
        CALL log_to_fight(CONCAT(tmp_trainer_name, ' send out ', first_pkm_name));
        
    END WHILE;
END $$

DELIMITER ;