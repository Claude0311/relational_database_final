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