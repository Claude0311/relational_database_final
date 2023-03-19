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