DROP TABLE IF EXISTS fight_log;
DROP TRIGGER IF EXISTS trigger_log_insert;

-- battle logger
-- deleted when battle ends
-- retrived rows with is_new=1 when one turn ends and set is_new to 0
CREATE TABLE fight_log (
    msg_ind INTEGER AUTO_INCREMENT,
    msg VARCHAR(100),
    isnew TINYINT DEFAULT 1,
    -- pkm info
    p1_id INTEGER,
    p2_id INTEGER,
    p1_pkdex SMALLINT,
    p2_pkdex SMALLINT,
    p1_pkm_name VARCHAR(20),
    p2_pkm_name VARCHAR(20),
    -- pkm battle status
    p1_status VARCHAR(20),
    p2_status VARCHAR(20),
    p1_hp INTEGER,
    p2_hp INTEGER,
    p1_max_hp INTEGER,
    p2_max_hp INTEGER,
    PRIMARY KEY (msg_ind)
);

DELIMITER !
CREATE TRIGGER trigger_log_insert BEFORE INSERT
    ON fight_log FOR EACH ROW
BEGIN
    DECLARE p1_id INTEGER;
    DECLARE p2_id INTEGER;
    DECLARE pkdex_1 SMALLINT;
    DECLARE pkdex_2 SMALLINT;
    DECLARE p1_name VARCHAR(20);
    DECLARE p2_name VARCHAR(20);
    DECLARE p1_status VARCHAR(8);
    DECLARE p2_status VARCHAR(8);
    DECLARE p1_hp INTEGER;
    DECLARE p2_hp INTEGER;
    DECLARE p1_max_hp INTEGER;
    DECLARE p2_max_hp INTEGER;

    SELECT pkm_id, pkdex, pkm_name, status, hp, max_hp
        INTO p1_id, pkdex_1, p1_name, p1_status, p1_hp, p1_max_hp
        FROM fighting_status NATURAL JOIN pokemon NATURAL JOIN pokedex
        WHERE choosen=1 ORDER BY trainer_id LIMIT 1;

    SELECT pkm_id, pkdex, pkm_name, status, hp, max_hp
        INTO p2_id, pkdex_2, p2_name, p2_status, p2_hp, p2_max_hp
        FROM fighting_status NATURAL JOIN pokemon NATURAL JOIN pokedex
        WHERE choosen=1 ORDER BY trainer_id LIMIT 1 OFFSET 1;

    SET NEW.p1_id = p1_id;
    SET NEW.p2_id = p2_id;
    SET NEW.p1_pkdex = pkdex_1;
    SET NEW.p2_pkdex = pkdex_2;
    SET NEW.p1_pkm_name = p1_name;
    SET NEW.p2_pkm_name = p2_name;

    SET NEW.p1_status = p1_status;
    SET NEW.p2_status = p2_status;
    SET NEW.p1_hp = p1_hp;
    SET NEW.p2_hp = p2_hp;
    SET NEW.p1_max_hp = p1_max_hp;
    SET NEW.p2_max_hp = p2_max_hp;
END !
DELIMITER ;