DROP procedure IF EXISTS use_move;
DROP procedure IF EXISTS deal_effect;
DROP FUNCTION IF EXISTS describe_effect;

DELIMITER $$
-- help logger
CREATE FUNCTION describe_effect (
    move_effect VARCHAR(20)
) RETURNS VARCHAR(40)
BEGIN
    DECLARE description VARCHAR(20);
    DECLARE stat VARCHAR(20);
    DECLARE inc TINYINT;
    DECLARE inc_description VARCHAR(20);

    IF move_effect = 'burn' THEN SET description=' is burnt';
    ELSEIF move_effect = 'freeze' THEN SET description=' is frozen';
    ELSEIF move_effect = 'paralysis' THEN SET description=' is paralyzed';
    ELSEIF move_effect = 'poison' THEN SET description=' is poisoned';
    ELSEIF move_effect = 'badly poison' THEN SET description=' is badly poisoned';
    ELSEIF move_effect = 'sleep' THEN SET description=' falls asleep';
    ELSE
        SET stat = substring_index(move_effect,' ',1);
        IF stat='atk' THEN SET stat='attack';
        ELSEIF stat='def' THEN SET stat='defense';
        ELSEIF stat='spatk' THEN SET stat='special attack';
        ELSEIF stat='spdef' THEN SET stat='special defense';
        ELSEIF stat='spd' THEN SET stat='speed';
        ELSEIF stat='acc' THEN SET stat='accuracy';
        ELSEIF stat='evasion' THEN SET stat='evasion';
        END IF;

        SET inc  = cast(substring_index(move_effect,' ',-1) AS SIGNED);
        IF inc>1 THEN SET inc_description='sharply raises';
        ELSEIF inc=1 THEN SET inc_description='raises';
        ELSEIF inc=-1 THEN SET inc_description='drops';
        ELSEIF inc<-1 THEN SET inc_description='sharply drops';
        END IF;

        SET description = CONCAT('\'s ', stat, ' ', inc_description);
    END IF;
    RETURN description;
END $$

-- deal additional effect
CREATE procedure deal_effect (
    move_effect VARCHAR(20),
    target_id INTEGER,
    target_name VARCHAR(50)
)
BEGIN
    DECLARE target_cur_status VARCHAR(20);
    DECLARE inc TINYINT;
    DECLARE handle_badpoison TINYINT;

    SELECT status INTO target_cur_status
        FROM fighting_status
        WHERE pkm_id=target_id;

    SET handle_badpoison = (target_cur_status='poison' AND move_effect in ('poison', 'badly poison')) OR move_effect = 'badly poisoned';

    IF (ISNULL(target_cur_status) AND move_effect in ('burn', 'freeze', 'paralysis', 'poison', 'sleep')) OR handle_badpoison THEN
        IF handle_badpoison THEN
            SET move_effect = 'badly poison';
            UPDATE fighting_status SET
                status = 'badly poison',
                status_count = 1
                WHERE pkm_id=target_id;

        ELSEIF move_effect = 'sleep' THEN
            -- sleep 2~5 turn
            UPDATE fighting_status SET
                status = move_effect,
                status_count = 2 + FLOOR(RAND()*4)
                WHERE pkm_id=target_id;

        ELSE
            UPDATE fighting_status SET
                status = move_effect
                WHERE pkm_id=target_id;
        END IF;

        INSERT INTO fight_log VALUES
            (CONCAT(target_name, describe_effect(move_effect)));
    END IF;
    
    IF move_effect LIKE '% %' THEN
        SET inc = cast(substring_index(move_effect,' ',-1) AS SIGNED );
        UPDATE fighting_status SET
            atk     = IF( move_effect LIKE 'atk%',      LEAST( GREATEST(-6, atk + inc), 6 ),      atk),
            def     = IF( move_effect LIKE 'def%',      LEAST( GREATEST(-6, def + inc), 6 ),      def),
            spatk   = IF( move_effect LIKE 'spatk%',    LEAST( GREATEST(-6, spatk + inc), 6 ),    spatk),
            spdef   = IF( move_effect LIKE 'spdef%',    LEAST( GREATEST(-6, spdef + inc), 6 ),    spdef),
            spd     = IF( move_effect LIKE 'spd%',      LEAST( GREATEST(-6, spd + inc), 6 ),      spd),
            acc     = IF( move_effect LIKE 'acc%',      LEAST( GREATEST(-6, acc + inc), 6 ),      acc),
            evasion = IF( move_effect LIKE 'evasion%',  LEAST( GREATEST(-6, evasion + inc), 6 ),  evasion)
            WHERE pkm_id=target_id;
        INSERT INTO fight_log VALUES
            (CONCAT(target_name, describe_effect(move_effect)));
    END IF;
END $$

CREATE procedure use_move (
    IN atk_id INTEGER,
    IN def_id INTEGER,
    IN move_id INTEGER,
    IN atker_name VARCHAR(50),
    IN defer_name VARCHAR(50),
    OUT fainted TINYINT
) NOT DETERMINISTIC
um: BEGIN
    DECLARE cur_category VARCHAR(8);
    DECLARE damage INTEGER;
    DECLARE effectiveness FLOAT;
    DECLARE cur_mv_name VARCHAR(20);
    DECLARE move_target TINYINT;
    DECLARE move_effect VARCHAR(20);
    DECLARE effect_prob TINYINT;
    DECLARE target_id INTEGER;
    DECLARE target_name VARCHAR(50);

    SET fainted=0;

    SELECT category, move_name, effect_target, effect, prob
    INTO cur_category, cur_mv_name, move_target, move_effect, effect_prob
        FROM movepool
        WHERE mv_id=move_id;

    INSERT INTO fight_log VALUES
        (CONCAT(atker_name, ' use ', cur_mv_name));

    -- Check miss
    
    IF cur_category!='status' THEN
        -- effectiveness check
        SET effectiveness = move_effectiveness(NULL, def_id, move_id);
        IF effectiveness = 0.0 THEN
            INSERT INTO fight_log VALUES ('But, it failed!');
        ELSEIF effectiveness < 1.0 THEN
            INSERT INTO fight_log VALUES ('It\'s not very effective...');
        ELSEIF effectiveness > 1.0 THEN
            INSERT INTO fight_log VALUES ('It\'s super effective!');
        END IF;

        -- deal damage
        SET damage = calculate_damage(atk_id, def_id, move_id);
        UPDATE fighting_status SET
            hp = GREATEST(hp - damage, 0)
            WHERE pkm_id=def_id;

        -- check fainted
        SELECT hp=0 INTO fainted
            FROM fighting_status
            WHERE pkm_id=def_id;
        IF fainted=1 THEN
            INSERT INTO fight_log VALUES
                (CONCAT(defer_name, ' fainted!'));
        END IF;
    END IF;

    IF NOT(fainted=1 AND move_target=1) AND RAND()*100<=effect_prob THEN
        -- additional effect triggered
        -- set addition effect's target
        SET target_id = IF(move_target=1, def_id, atk_id);
        SET target_name = IF(move_target=1, defer_name, atker_name);

        CALL deal_effect(move_effect, target_id, target_name);

    END IF;

END $$

DELIMITER ;

/* CALL enter_fight(1,2);
CALL use_move(1, 2, 56, @f);
CALL use_move(2, 1, 58, @f);
CALL use_move(1, 2, 86, @f);
CALL use_move(2, 1, 435, @f);
SELECT * FROM fight_log;
SELECT * FROM fighting_status; */