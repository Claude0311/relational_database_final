DROP FUNCTION IF EXISTS calculate_damage;
DROP FUNCTION IF EXISTS move_effectiveness;

DELIMITER !
CREATE FUNCTION move_effectiveness (
    atk_id INTEGER,
    def_id INTEGER,
    move_id INTEGER
) RETURNS FLOAT
BEGIN
    -- For effectiveness calculation
    DECLARE factor FLOAT default 1.0;
    DECLARE tmp_factor NUMERIC(2, 1) default 1.0;
    DECLARE mv_ele_type VARCHAR(8);

    DECLARE atk_ele_type_1 VARCHAR(8);
    DECLARE atk_ele_type_2 VARCHAR(8);

    DECLARE def_ele_type_1 VARCHAR(8);
    DECLARE def_ele_type_2 VARCHAR(8);

    SELECT ele_type_1, ele_type_2 INTO atk_ele_type_1, atk_ele_type_2
        FROM pokemon, pokedex WHERE pkm_id=atk_id;

    SELECT ele_type INTO mv_ele_type
        FROM movepool WHERE mv_id=move_id;

    SELECT ele_type_1, ele_type_2 INTO def_ele_type_1, def_ele_type_2
        FROM pokemon, pokedex WHERE pkm_id=def_id;

    IF atk_ele_type_1=mv_ele_type OR atk_ele_type_2=mv_ele_type THEN
        SET factor = 1.5;
    END IF;

    SELECT effective INTO tmp_factor
        FROM type_chart 
        WHERE atker=mv_ele_type AND defer=def_ele_type_1;
    SET factor = factor * tmp_factor;

    IF NOT ISNULL(def_ele_type_2) THEN
        SELECT effective INTO tmp_factor
            FROM type_chart 
            WHERE atker=mv_ele_type AND defer=def_ele_type_2;
        SET factor = factor * tmp_factor;
    END IF;

    RETURN factor;
END !

CREATE FUNCTION calculate_damage (
    atk_id INTEGER,
    def_id INTEGER,
    move_id INTEGER
) RETURNS INTEGER
BEGIN
    DECLARE damage FLOAT;
    
    DECLARE factor FLOAT DEFAULT 1.0;
    DECLARE cur_status VARCHAR(20);
    
    DECLARE cur_atk TINYINT;
    DECLARE cur_def TINYINT;
    DECLARE cur_lv TINYINT;
    DECLARE cur_movepower TINYINT;
    DECLARE cur_catagolry VARCHAR(8);

    SELECT catagolry, movepower INTO cur_catagolry, cur_movepower
        FROM movepool
        WHERE mv_id=move_id;

    IF cur_catagolry='physical' THEN
        SELECT atk, lv INTO cur_atk, cur_lv
            FROM pokemon_view
            WHERE pkm_id=atk_id;

        SELECT status INTO cur_status
            FROM fighting_status
            WHERE pkm_id=atk_id;

        SELECT def INTO cur_def
            FROM pokemon_view
            WHERE pkm_id=def_id;

        IF status='BURN' THEN
            SET factor = 0.5;
        END IF;

    ELSEIF cur_catagolry='special' THEN
        SELECT spatk, lv INTO cur_atk, cur_lv
            FROM pokemon_view
            WHERE pkm_id=atk_id;

        SELECT spdef INTO cur_def
            FROM pokemon_view
            WHERE pkm_id=def_id;
    END IF;

    SET factor = factor * move_effectiveness(atk_id, def_id, move_id);
    IF factor=0 THEN RETURN 0; END IF;
    SET factor = factor * ( 1 - 0.15 * RAND() );

    SET damage = ( ( 2*cur_lv+10 )/250 * cur_atk/cur_def * cur_movepower + 2 ) * factor;
    SET damage = FLOOR(damage);
    IF damage<1 THEN SET damage = 1; END IF;
    RETURN damage;
END !

DELIMITER ;

SELECT move_effectiveness(1, 2, 56) AS 'Hydro Pump',
move_effectiveness(1, 2, 58) AS 'Ice Beam',
move_effectiveness(1, 2, 86) AS 'Thunder Wave',
move_effectiveness(1, 2, 435) AS 'Discharge';

SELECT calculate_damage(1, 2, 56) AS 'Hydro Pump',
calculate_damage(1, 2, 58) AS 'Ice Beam',
calculate_damage(1, 2, 86) AS 'Thunder Wave',
calculate_damage(1, 2, 435) AS 'Discharge';