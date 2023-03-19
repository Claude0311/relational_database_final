DROP FUNCTION IF EXISTS calculate_damage;
DROP FUNCTION IF EXISTS move_effectiveness;
DROP FUNCTION IF EXISTS stat_change;
DROP FUNCTION IF EXISTS is_hit;
DROP FUNCTION IF EXISTS compare_speed;

DELIMITER !
-- given stat from fight_status, calculate factor
CREATE FUNCTION stat_change (
    delta TINYINT
) RETURNS FLOAT
BEGIN
    IF delta > 0 THEN RETURN (2+delta)/2;
    ELSEIF delta < 0 THEN RETURN 2/(2-delta);
    ELSE RETURN 1.0;
    END IF;
END !

-- Given pkms and move, calculate effectiveness factor
CREATE FUNCTION move_effectiveness (
    atk_id INTEGER,
    def_id INTEGER,
    move_id INTEGER
) RETURNS FLOAT
BEGIN
    DECLARE factor FLOAT default 1.0;
    DECLARE mv_ele_type VARCHAR(8);

    DECLARE atk_ele_type_1 VARCHAR(8);
    DECLARE atk_ele_type_2 VARCHAR(8);

    DECLARE def_ele_type_1 VARCHAR(8);
    DECLARE def_ele_type_2 VARCHAR(8);

    

    SELECT ele_type INTO mv_ele_type
        FROM movepool WHERE mv_id=move_id;

    SELECT ele_type_1, ele_type_2 INTO def_ele_type_1, def_ele_type_2
        FROM pokemon NATURAL JOIN pokedex WHERE pkm_id=def_id;

    IF NOT ISNULL(atk_id) THEN
        SELECT ele_type_1, ele_type_2 INTO atk_ele_type_1, atk_ele_type_2
            FROM pokemon NATURAL JOIN pokedex WHERE pkm_id=atk_id;
        IF atk_ele_type_1=mv_ele_type OR atk_ele_type_2=mv_ele_type THEN
            SET factor = 1.5;
        END IF;
    END IF;

    SELECT effective * factor INTO factor
        FROM type_chart 
        WHERE atker=mv_ele_type AND defer=def_ele_type_1;

    IF NOT ISNULL(def_ele_type_2) THEN
        SELECT effective * factor INTO factor
            FROM type_chart 
            WHERE atker=mv_ele_type AND defer=def_ele_type_2;
    END IF;

    RETURN factor;
END !

-- Given pokemons and move, calculate damage
CREATE FUNCTION calculate_damage (
    atk_id INTEGER,
    def_id INTEGER,
    move_id INTEGER
) RETURNS INTEGER NOT DETERMINISTIC
BEGIN
    DECLARE damage FLOAT;
    
    DECLARE factor FLOAT DEFAULT 1.0;
    DECLARE cur_status VARCHAR(20);
    
    DECLARE cur_atk FLOAT;
    DECLARE cur_def FLOAT;
    DECLARE cur_lv TINYINT;
    DECLARE cur_movepower TINYINT UNSIGNED;
    DECLARE cur_category VARCHAR(8);

    SELECT category, movepower INTO cur_category, cur_movepower
        FROM movepool
        WHERE mv_id=move_id;

    IF cur_category='physical' THEN
        -- use atk and def for physical move
        SELECT atk, lv INTO cur_atk, cur_lv
            FROM pokemon_view
            WHERE pkm_id=atk_id;

        SELECT status, stat_change(atk)*cur_atk INTO cur_status, cur_atk
            FROM fighting_status
            WHERE pkm_id=atk_id;

        SELECT def INTO cur_def
            FROM pokemon_view
            WHERE pkm_id=def_id;

        SELECT stat_change(def)*cur_def INTO cur_def
            FROM fighting_status
            WHERE pkm_id=def_id;

        IF cur_status='BURN' THEN
            SET factor = 0.5;
        END IF;

    ELSEIF cur_category='special' THEN
        -- use spatk and spdef for special move
        SELECT spatk, lv INTO cur_atk, cur_lv
            FROM pokemon_view
            WHERE pkm_id=atk_id;

        SELECT stat_change(spatk)*cur_atk INTO cur_atk
            FROM fighting_status
            WHERE pkm_id=atk_id;

        SELECT spdef INTO cur_def
            FROM pokemon_view
            WHERE pkm_id=def_id;

        SELECT stat_change(spdef)*cur_def INTO cur_def
            FROM fighting_status
            WHERE pkm_id=def_id;
    END IF;

    -- considering same type, effectiveness, burn and randomness
    SET factor = factor * move_effectiveness(atk_id, def_id, move_id);
    IF factor=0 THEN RETURN 0; END IF;
    SET factor = factor * ( 1 - 0.15 * RAND() );

    -- considering lv, atk, def
    SET damage = ( ( 2*cur_lv+10 )/250 * cur_atk/cur_def * cur_movepower + 2 ) * factor;
    SET damage = FLOOR(damage);
    IF damage<1 THEN SET damage = 1; END IF;
    RETURN damage;
END !

-- Given pokemons and move, determines if move hits
CREATE FUNCTION is_hit (
    atk_id INTEGER,
    def_id INTEGER,
    move_id INTEGER
) RETURNS TINYINT NOT DETERMINISTIC
BEGIN
    DECLARE factor FLOAT default 1;
    DECLARE atk_acc FLOAT default 0;
    DECLARE def_eva FLOAT default 0;
    DECLARE mov_acc FLOAT default 0;
    DECLARE A FLOAT default 0;
    DECLARE B FLOAT default 0;

    -- Load accuracy for move
    SELECT accuracy INTO mov_acc
            FROM movepool
            WHERE mv_id=move_id;

    if ISNULL(mov_acc) THEN RETURN 1; END IF;

    -- Load accuracy for attacking pokemon
    SELECT acc INTO atk_acc
            FROM fighting_status
            WHERE pkm_id=atk_id;
    
    -- Load evasion for defending pokemon
    SELECT evasion INTO def_eva
            FROM fighting_status
            WHERE pkm_id=def_id;
    
    SET factor = atk_acc - def_eva;

    IF factor > 6 THEN
        SET factor = 6;
    ELSEIF factor < -6 THEN
        SET factor =-6;
    END IF;

    IF factor >= 0 THEN
        SET factor = (3+factor)/3;
    ELSE
        SET factor = 3/(3+factor);
    END IF;

    SET A = FLOOR(255*mov_acc)*factor/255;
    -- Generate random value to determine if hits
    SET B = FLOOR(RAND()*100);

    IF B<A THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END !

-- Finds which pokemon attacks first taking into account paralysis
CREATE FUNCTION compare_speed (
    pkm_id_0 INTEGER,
    pkm_id_1 INTEGER,
    move_id_0 INTEGER,
    move_id_1 INTEGER
) RETURNS TINYINT NOT DETERMINISTIC
BEGIN
    DECLARE move_0_priority INTEGER default 0;
    DECLARE move_1_priority INTEGER default 0;
    DECLARE pkm_0_spd INTEGER default 0;
    DECLARE pkm_1_spd INTEGER default 0;
    DECLARE pkm_0_status VARCHAR(20) DEFAULT NULL;
    DECLARE pkm_1_status VARCHAR(20) DEFAULT NULL;

    -- Load priority for pkm 0's move
    SELECT priority INTO move_0_priority
            FROM movepool
            WHERE mv_id=move_id_0;
    -- Load priority for pkm 1's move
    SELECT priority INTO move_1_priority
            FROM movepool
            WHERE mv_id=move_id_1;
    -- Load speed for pkm 0
    SELECT spd INTO pkm_0_spd
            FROM pokemon_view
            WHERE pkm_id=pkm_id_0;
    -- Load speed for pkm 1
    SELECT spd INTO pkm_1_spd
            FROM pokemon_view
            WHERE pkm_id=pkm_id_1;
    -- Load status for pkm 0
    SELECT status INTO pkm_0_status
            FROM fighting_status
            WHERE pkm_id=pkm_id_0;
    -- Load status for pkm 1
    SELECT status INTO pkm_1_status
            FROM fighting_status
            WHERE pkm_id=pkm_id_1;
    -- Check if pkm 0 is paralyzed
    IF pkm_0_status = 'Paralysis' THEN
        SET pkm_0_spd = 0.25*pkm_0_spd;
    END IF;
    -- Check if pkm 1 is paralyzed
    IF pkm_1_status = 'Paralysis' THEN
        SET pkm_1_spd = 0.25*pkm_1_spd;
    END IF;
    -- Compare move priority
    IF move_0_priority > move_1_priority THEN
        RETURN 0;
    ELSEIF move_1_priority > move_0_priority THEN
        RETURN 1;
    ELSE
        -- Compare pokemon speed
        IF pkm_0_spd > pkm_1_spd THEN
            RETURN 0;
        ELSEIF pkm_1_spd > pkm_0_spd THEN
            RETURN 1;
        ELSE
            -- Choose randomly if speed is the same
            RETURN FLOOR(RAND()*2);
        END IF;
    END IF;
END !

DELIMITER ;


DROP PROCEDURE IF EXISTS log_to_fight;
DROP procedure IF EXISTS use_move;
DROP procedure IF EXISTS deal_effect;
DROP FUNCTION IF EXISTS describe_effect;

DELIMITER $$
-- logger function
CREATE PROCEDURE log_to_fight (
    val VARCHAR(100)
)
BEGIN 
    INSERT INTO fight_log (msg) VALUES
        (val);
END $$

-- effect logger
CREATE FUNCTION describe_effect (
    move_effect VARCHAR(20)
) RETURNS VARCHAR(40)
BEGIN
    DECLARE description VARCHAR(100);
    DECLARE stat VARCHAR(20);
    DECLARE inc TINYINT;
    DECLARE inc_description VARCHAR(20);

    -- log status condition
    IF move_effect = 'burn' THEN SET description=' is burnt';
    ELSEIF move_effect = 'freeze' THEN SET description=' is frozen';
    ELSEIF move_effect = 'paralysis' THEN SET description=' is paralyzed';
    ELSEIF move_effect = 'poison' THEN SET description=' is poisoned';
    ELSEIF move_effect = 'badly poison' THEN SET description=' is badly poisoned';
    ELSEIF move_effect = 'sleep' THEN SET description=' falls asleep';
    ELSE
    -- log stat change
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

    SET handle_badpoison = (target_cur_status='poison' AND move_effect in ('poison', 'badly poison')) OR (ISNULL(target_cur_status) AND move_effect = 'badly poison');

    -- Handle status conditional
    IF (ISNULL(target_cur_status) AND move_effect in ('burn', 'freeze', 'paralysis', 'poison', 'sleep')) OR handle_badpoison THEN
        -- badly poison will have increasing damage based on status_count 
        IF handle_badpoison THEN
            SET move_effect = 'badly poison';
            UPDATE fighting_status SET
                status = 'badly poison',
                status_count = 1
                WHERE pkm_id=target_id;

        -- sleep 2~5 turn
        ELSEIF move_effect = 'sleep' THEN
            UPDATE fighting_status SET
                status = move_effect,
                status_count = 2 + FLOOR(RAND()*4)
                WHERE pkm_id=target_id;

        -- other status condition
        ELSE
            UPDATE fighting_status SET
                status = move_effect
                WHERE pkm_id=target_id;
        END IF;

        CALL log_to_fight(CONCAT(target_name, describe_effect(move_effect)));

    END IF;
    
    -- Handle stat change, input will be like the form "atk +2" or "spdef -3"
    -- stat should be between -6 to +6
    IF move_effect LIKE '% +%' OR move_effect LIKE '% -%' THEN
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

        CALL log_to_fight(CONCAT(target_name, describe_effect(move_effect)));
    END IF;
END $$

-- given attacker and defender and move
-- deal damage and handle move's additional effect
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
    DECLARE hit TINYINT DEFAULT 1;
    DECLARE move_hit_time TINYINT DEFAULT 0;
    DECLARE move_select_hit_time TINYINT;

    SET fainted=0;

    -- get move's info
    SELECT category, move_name, effect_target, effect, prob, min_times + FLOOR(RAND()*(max_times-min_times+1))
    INTO cur_category, cur_mv_name, move_target, move_effect, effect_prob, move_select_hit_time
        FROM movepool
        WHERE mv_id=move_id;

    CALL log_to_fight(CONCAT(atker_name, ' use ', cur_mv_name));

    -- Check miss
    SET hit = is_hit(atk_id, def_id, move_id);
    if hit = 0 THEN
        CALL log_to_fight('But it missed!');
        LEAVE um;
    END IF;
    
    SET effectiveness = move_effectiveness(NULL, def_id, move_id);
    
    -- if effectiveness is zero, then move fail
    IF effectiveness = 0.0 THEN
        CALL log_to_fight('But, it failed!');
        LEAVE um;
    ELSEIF cur_category!='status' THEN
        IF effectiveness < 1.0 THEN
            CALL log_to_fight('It\'s not very effective...');
        ELSEIF effectiveness > 1.0 THEN
            CALL log_to_fight('It\'s super effective!');
        END IF;
    END IF;

    -- handle moves that hit multiple times
    -- most moves will just hit one time
    myloop: WHILE move_hit_time < move_select_hit_time DO
        SET move_hit_time = move_hit_time + 1;
        IF cur_category!='status' THEN
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
                CALL log_to_fight(CONCAT(defer_name, ' fainted!'));
            END IF;
        END IF;

        -- handle additional effect with certain probability
        IF NOT(fainted=1 AND move_target=1) AND RAND()*100<=effect_prob THEN
            -- set addition effect's target and deal effect
            SET target_id = IF(move_target=1, def_id, atk_id);
            SET target_name = IF(move_target=1, defer_name, atker_name);
            CALL deal_effect(move_effect, target_id, target_name);
        END IF;

        IF fainted=1 THEN
            LEAVE myloop;
        END IF;
    END WHILE;

    IF move_select_hit_time>1 THEN
        CALL log_to_fight(CONCAT('HIT ',move_hit_time,' times!'));
    END IF; 

END $$

DELIMITER ;

DROP PROCEDURE IF EXISTS enter_fight;
DROP PROCEDURE IF EXISTS one_turn;
DROP PROCEDURE IF EXISTS check_status_case1;
DROP PROCEDURE IF EXISTS check_status_case2;
DROP FUNCTION  IF EXISTS allfainted;
DROP PROCEDURE IF EXISTS handle_switch;
DROP PROCEDURE IF EXISTS handle_surrender;


DELIMITER $$

-- check if any of the player surrender
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

-- update fighting_status if any of the player switch pokemon
CREATE PROCEDURE handle_switch(
    INOUT cur_pkm_id INTEGER,
    IN switch_pkm_id INTEGER,
    IN player_name VARCHAR(20),
    OUT cur_pkm_name VARCHAR(20)
)
BEGIN
    -- switch
    IF NOT ISNULL(switch_pkm_id) THEN
        -- reset pkm's stat change
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

-- check if a player's pokemon all fainted, which means the player lost
CREATE FUNCTION allfainted(
    fainted_pkm_id INTEGER
) RETURNS TINYINT
BEGIN
    DECLARE allfainted TINYINT DEFAULT 0;
    DECLARE owner_id INTEGER;

    SELECT trainer_id INTO owner_id
        FROM fighting_status 
        WHERE pkm_id=fainted_pkm_id;

    -- check if any of his pokemon is still alive
    SELECT COUNT(pkm_id)=0 INTO allfainted
        FROM fighting_status
        WHERE trainer_id=owner_id AND hp>0;
    RETURN allfainted;
END $$

-- handle status condition at the beginning of one turn
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

-- handle status condition at the end of one turn
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
    
    -- deal burn damage
    IF pkm_status='burn' THEN
        UPDATE fighting_status 
            SET hp = GREATEST(hp - GREATEST(FLOOR(max_hp/16), 1), 0)
            WHERE pkm_id=cur_pkm_id;
        CALL log_to_fight(CONCAT(pkm_name, ' is hurt by its burn!'));
    -- update sleep counter
    ELSEIF pkm_status='sleep' THEN
        UPDATE fighting_status 
            SET status_count = status_count - 1
            WHERE pkm_id=cur_pkm_id;
    -- deal poison damage
    ELSEIF pkm_status='poison' THEN
        UPDATE fighting_status 
            SET hp = GREATEST(hp - GREATEST(FLOOR(max_hp/8), 1), 0)
            WHERE pkm_id=cur_pkm_id;
        CALL log_to_fight(CONCAT(pkm_name, ' is hurt by poison!'));
    -- deal poison damage and update poison counter
    ELSEIF pkm_status='badly poison' THEN
        UPDATE fighting_status 
            SET hp = GREATEST(hp - GREATEST(FLOOR(max_hp*status_count/16), 1), 0),
                status_count = LEAST(status_count+1, 15)
            WHERE pkm_id=cur_pkm_id;
        CALL log_to_fight(CONCAT(pkm_name, ' is hurt by poison!'));
    END IF;
    -- check fainted
    SELECT hp=0 INTO fainted
        FROM fighting_status
        WHERE pkm_id=cur_pkm_id;
    IF fainted THEN 
        CALL log_to_fight(CONCAT(pkm_name, ' fainted!'));
    END IF;
END $$

-- handle everything happened in one turn
-- the events order is listed below
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
    OUT winner TINYINT,
    OUT pkm_1_fainted TINYINT,
    OUT pkm_2_fainted TINYINT
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
    
    SET pkm_1_fainted = 0;
    SET pkm_2_fainted = 0;
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
    IF NOT ISNULL(move_id_1) AND NOT ISNULL(move_id_2) THEN
        SET pkm_1_goes_first = compare_speed(pkm_id_2, pkm_id_1, move_id_2, move_id_1);
    END IF;

    -- two pokemon use moves based on their speed
    IF pkm_1_goes_first=1 THEN
        -- pokemon 1 use move
        IF NOT ISNULL(switch_pkm_id_1) THEN
            SELECT * FROM fighting_status WHERE 1=0; -- do nothing
        -- check some status condition
        ELSEIF pkm_1_status='paralysis' AND RAND()<0.25 THEN
            CALL log_to_fight(CONCAT(pkm_1_name, 'is paralyzed. It can\'t move!'));
        ELSEIF pkm_1_status='freeze' THEN
            CALL log_to_fight(CONCAT(pkm_1_name, 'is frozen. It can\'t move!'));
        ELSEIF pkm_1_status='sleep' THEN
            CALL log_to_fight(CONCAT(pkm_1_name, 'is sleeping. It can\'t move!'));
        ELSE
        -- use move
            CALL use_move(pkm_id_1, pkm_id_2, move_id_1, pkm_1_name, pkm_2_name, pkm_2_fainted);
        END IF;
        -- check fainted
        IF pkm_2_fainted=1 AND allfainted(pkm_id_2)  THEN
            CALL log_to_fight(CONCAT(player_1_name,' wins!'));
            SET winner=1;
            LEAVE ot;
        ELSEIF pkm_2_fainted=0 AND ISNULL(switch_pkm_id_2) THEN
        -- pokemon 2 use move
            SELECT status INTO pkm_2_status
                FROM fighting_status
                WHERE pkm_id=pkm_id_2;
            -- check some status condition
            IF pkm_2_status='paralysis' AND RAND()<0.25 THEN
                CALL log_to_fight(CONCAT(pkm_2_name, 'is paralyzed. It can\'t move!'));
            ELSEIF pkm_2_status='freeze' THEN
                CALL log_to_fight(CONCAT(pkm_2_name, 'is frozen. It can\'t move!'));
            ELSEIF pkm_2_status='sleep' THEN
                CALL log_to_fight(CONCAT(pkm_2_name, 'is sleeping. It can\'t move!'));
            ELSE
            -- use move
                CALL use_move(pkm_id_2, pkm_id_1, move_id_2, pkm_2_name, pkm_1_name, pkm_1_fainted);
            END IF;
            -- check fainted
            IF pkm_1_fainted=1 AND allfainted(pkm_id_1) THEN
                CALL log_to_fight(CONCAT(player_2_name,' wins!'));
                SET winner=2;
                LEAVE ot;
            END IF;
        END IF;
    ELSE
        -- pokemon 2 use move
        IF NOT ISNULL(switch_pkm_id_2) THEN 
            SELECT * FROM fighting_status WHERE 1=0; -- do nothing
        -- check some status condition
        ELSEIF pkm_2_status='paralysis' AND RAND()<0.25 THEN
            CALL log_to_fight(CONCAT(pkm_2_name, 'is paralyzed. It can\'t move!'));
        ELSEIF pkm_2_status='freeze' THEN
            CALL log_to_fight(CONCAT(pkm_2_name, 'is frozen. It can\'t move!'));
        ELSEIF pkm_2_status='sleep' THEN
            CALL log_to_fight(CONCAT(pkm_2_name, 'is sleeping. It can\'t move!'));
        ELSE
        -- use move
            CALL use_move(pkm_id_2, pkm_id_1, move_id_2, pkm_2_name, pkm_1_name, pkm_1_fainted);
        END IF;
        -- check fainted
        IF pkm_1_fainted=1 AND allfainted(pkm_id_1)  THEN
            CALL log_to_fight(CONCAT(player_2_name,' wins!'));
            SET winner=2;
            LEAVE ot;
        ELSEIF pkm_1_fainted=0 AND ISNULL(switch_pkm_id_1) THEN
        -- pokemon 1 use move
            SELECT status INTO pkm_1_status
                FROM fighting_status
                WHERE pkm_id=pkm_id_1;
            -- check some status condition
            IF pkm_1_status='paralysis' AND RAND()<0.25 THEN
                CALL log_to_fight(CONCAT(pkm_1_name, 'is paralyzed. It can\'t move!'));
            ELSEIF pkm_1_status='freeze' THEN
                CALL log_to_fight(CONCAT(pkm_1_name, 'is frozen. It can\'t move!'));
            ELSEIF pkm_1_status='sleep' THEN
                CALL log_to_fight(CONCAT(pkm_1_name, 'is sleeping. It can\'t move!'));
            ELSE
            -- use move
                CALL use_move(pkm_id_1, pkm_id_2, move_id_1, pkm_1_name, pkm_2_name, pkm_2_fainted);
            END IF;
            -- check fainted
            IF pkm_2_fainted=1 AND allfainted(pkm_id_2) THEN
                CALL log_to_fight(CONCAT(player_1_name,' wins!'));
                SET winner=1;
                LEAVE ot;
            END IF;
        END IF;
    END IF;

    -- handle burn poison at random order
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

-- add team info into fighting_status
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



DROP PROCEDURE IF EXISTS pkm_move_info;

DELIMITER $$

CREATE PROCEDURE pkm_move_info(
    IN cur_pkm_id INTEGER,
    OUT move_id_1 INTEGER,
    OUT move_name_1 VARCHAR(20),
    OUT move_id_2 INTEGER,
    OUT move_name_2 VARCHAR(20),
    OUT move_id_3 INTEGER,
    OUT move_name_3 VARCHAR(20),
    OUT move_id_4 INTEGER,
    OUT move_name_4 VARCHAR(20)
)
BEGIN
    SELECT mv_id_1, mv_id_2, mv_id_3, mv_id_4
        INTO move_id_1, move_id_2, move_id_3, move_id_4
        FROM pokemon WHERE pkm_id=cur_pkm_id;
    IF NOT ISNULL(move_id_1) THEN
        SELECT move_name INTO move_name_1
            FROM movepool WHERE mv_id=move_id_1;
    END IF;
    IF NOT ISNULL(move_id_2) THEN
        SELECT move_name INTO move_name_2
            FROM movepool WHERE mv_id=move_id_2;
    END IF;
    IF NOT ISNULL(move_id_3) THEN
        SELECT move_name INTO move_name_3
            FROM movepool WHERE mv_id=move_id_3;
    END IF;
    IF NOT ISNULL(move_id_4) THEN
        SELECT move_name INTO move_name_4
            FROM movepool WHERE mv_id=move_id_4;
    END IF;
END $$

DELIMITER ;

