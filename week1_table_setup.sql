DROP PROCEDURE IF EXISTS enter_fight;
DROP TRIGGER IF EXISTS trg_fight_insert;
DROP TABLE IF EXISTS fighting_status;
DROP TABLE IF EXISTS team;
DROP TABLE IF EXISTS owns;
DROP TABLE IF EXISTS trainer;
DROP TABLE IF EXISTS fight_log;
DROP VIEW IF EXISTS pokemon_view;
DROP TRIGGER IF EXISTS pkm_randomizer;
DROP TABLE IF EXISTS pokemon;
DROP TABLE IF EXISTS know;
DROP TABLE IF EXISTS pokedex;
DROP TABLE IF EXISTS movepool;
DROP TABLE IF EXISTS type_chart;
DROP TABLE IF EXISTS nature_table;

CREATE TABLE pokedex (
    pkdex SMALLINT,
    pkm_name VARCHAR(20),
    ele_type_1 VARCHAR(8) NOT NULL,
    ele_type_2 VARCHAR(8),
    -- Species strength 0~255
    strength_hp TINYINT,
    strength_atk TINYINT,
    strength_def TINYINT,
    strength_spatk TINYINT,
    strength_spdef TINYINT,
    strength_spd TINYINT,
    PRIMARY KEY (pkdex)
);
CREATE INDEX ind_pkdex ON pokedex(pkdex);

CREATE TABLE movepool (
    mv_id INTEGER AUTO_INCREMENT,
    move_name VARCHAR(20),
    ele_type VARCHAR(8),
    pp TINYINT,
    -- -5 ~ +5
    priority TINYINT DEFAULT 0,
    -- physical, special, status
    category VARCHAR(8),
    -- NULL if is pure status move
    -- 0 ~ 200?
    movepower TINYINT,
    -- 0 ~ 100
    accuracy TINYINT,
    -- additional effect, NULL if is pure atk move
    -- Flinch, +- atk, status, confuse
    -- 0 ~ 100?
    prob TINYINT,
    -- 
    effect VARCHAR(20),
    -- 0 is itself, 1 is opponent
    effect_target TINYINT DEFAULT 1,
    -- times: 1, 2, or 2~5
    min_times TINYINT NOT NULL DEFAULT 1,
    max_times TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (mv_id)
);
CREATE INDEX ind_mvid ON movepool(mv_id);
-- not supporting:
-- demage itself, heal itself, field, mist, constant damage(dragon rage)
-- Metronome, One-Hit-KO


CREATE TABLE know (
    pkdex SMALLINT,
    mv_id INTEGER,
    PRIMARY KEY (pkdex, mv_id),
    FOREIGN KEY (pkdex) REFERENCES pokedex(pkdex),
    FOREIGN KEY (mv_id) REFERENCES movepool(mv_id)
);

CREATE TABLE type_chart (
    atker VARCHAR(8),
    defer VARCHAR(8),
    effective NUMERIC(2, 1) default 1.0, # 0, 0.5, 1, 2
    PRIMARY KEY (atker, defer)
);

CREATE TABLE nature_table (
    nature_id TINYINT,
    nature VARCHAR(7),
    nature_atk NUMERIC(2,1) DEFAULT 1.0,
    nature_def NUMERIC(2,1) DEFAULT 1.0,
    nature_spatk NUMERIC(2,1) DEFAULT 1.0,
    nature_spdef NUMERIC(2,1) DEFAULT 1.0,
    nature_spd NUMERIC(2,1) DEFAULT 1.0,
    PRIMARY KEY (nature_id)
);

CREATE TABLE pokemon (
    pkm_id INTEGER NOT NULL AUTO_INCREMENT,
    pkdex SMALLINT,
    -- default 50, not planning to design exp system
    lv TINYINT DEFAULT 50,
    nature_id TINYINT,
    gender TINYINT,
    mv_id_1 INTEGER,
    mv_id_2 INTEGER,
    mv_id_3 INTEGER,
    mv_id_4 INTEGER,
    -- can select manually,
    -- sum 510, each max 252
    EV_hp TINYINT DEFAULT 0,
    EV_atk TINYINT DEFAULT 0,
    EV_def TINYINT DEFAULT 0,
    EV_spatk TINYINT DEFAULT 0,
    EV_spdef TINYINT DEFAULT 0,
    EV_spd TINYINT DEFAULT 0, 
    -- randomly generated, 0~31 
    IV_hp TINYINT ,
    IV_atk TINYINT,
    IV_def TINYINT,
    IV_spatk TINYINT,
    IV_spdef TINYINT,
    IV_spd TINYINT,
    PRIMARY KEY (pkm_id),
    FOREIGN KEY (pkdex, mv_id_1) REFERENCES know(pkdex, mv_id), 
    FOREIGN KEY (pkdex, mv_id_2) REFERENCES know(pkdex, mv_id), 
    FOREIGN KEY (pkdex, mv_id_3) REFERENCES know(pkdex, mv_id), 
    FOREIGN KEY (pkdex, mv_id_4) REFERENCES know(pkdex, mv_id), 
    FOREIGN KEY (nature_id) REFERENCES nature_table(nature_id),
    CHECK ( EV_hp+EV_atk+EV_def+EV_spatk+EV_spdef+EV_spd <= 510 ),
    CHECK ( EV_hp <= 252 AND EV_atk <= 252 AND EV_def<=252 AND EV_spatk<=252 AND EV_spdef<=252 AND EV_spd<=252 )
);
CREATE INDEX ind_pkm ON pokemon(pkm_id);

DELIMITER !
CREATE TRIGGER pkm_randomizer
BEFORE INSERT
ON pokemon
FOR EACH ROW
BEGIN
    IF ISNULL(NEW.IV_hp)    THEN SET NEW.IV_hp    = FLOOR( RAND()*32 ); END IF;
    IF ISNULL(NEW.IV_atk)   THEN SET NEW.IV_atk   = FLOOR( RAND()*32 ); END IF;
    IF ISNULL(NEW.IV_def)   THEN SET NEW.IV_def   = FLOOR( RAND()*32 ); END IF;
    IF ISNULL(NEW.IV_spatk) THEN SET NEW.IV_spatk = FLOOR( RAND()*32 ); END IF;
    IF ISNULL(NEW.IV_spdef) THEN SET NEW.IV_spdef = FLOOR( RAND()*32 ); END IF;
    IF ISNULL(NEW.IV_spd)   THEN SET NEW.IV_spd   = FLOOR( RAND()*32 ); END IF;
    
    IF ISNULL(NEW.nature_id) THEN SET NEW.nature_id = FLOOR( RAND()*25 ); END IF;
    IF ISNULL(NEW.gender) THEN SET NEW.gender = FLOOR( RAND()*2 ); END IF;
END !
DELIMITER ;

-- automatically generated from EVs, IVs, LV, Species strength 
CREATE VIEW pokemon_view AS 
    SELECT pkm_id, 
        pkm_name,
        nature,
        lv,
        FLOOR((2*strength_hp + IV_hp + FLOOR(EV_hp/4))*lv/100)+lv+10 AS hp, 
        FLOOR( (FLOOR((2*strength_atk + IV_atk + FLOOR(EV_atk/4))*lv/100)+5)*nature_atk ) AS atk, 
        FLOOR( (FLOOR((2*strength_def + IV_def + FLOOR(EV_def/4))*lv/100)+5)*nature_def ) AS def,
        FLOOR( (FLOOR((2*strength_spatk + IV_spatk + FLOOR(EV_spatk/4))*lv/100)+5)*nature_spatk ) AS spatk,
        FLOOR( (FLOOR((2*strength_spdef + IV_spdef + FLOOR(EV_spdef/4))*lv/100)+5)*nature_spdef ) AS spdef,
        FLOOR( (FLOOR((2*strength_spd + IV_spd + FLOOR(EV_spd/4))*lv/100)+5)*nature_spd ) AS spd
    FROM pokemon, pokedex, nature_table;


CREATE TABLE trainer (
    trainer_id      INTEGER NOT NULL AUTO_INCREMENT,
    trainer_name    VARCHAR(20) NOT NULL,
    password        VARCHAR(20) NOT NULL,
    PRIMARY KEY (trainer_id)
);
CREATE INDEX ind_trainer ON trainer(trainer_id);

CREATE TABLE owns (
    trainer_id INTEGER NOT NULL,
    pkm_id     INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (trainer_id, pkm_id),
    FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id),
    FOREIGN KEY (pkm_id)     REFERENCES pokemon(pkm_id)
);

CREATE TABLE team (
    trainer_id  INTEGER NOT NULL UNIQUE,
    pkm_id_1    INTEGER NOT NULL,
    pkm_id_2    INTEGER,
    pkm_id_3    INTEGER,
    pkm_id_4    INTEGER,
    pkm_id_5    INTEGER,
    pkm_id_6    INTEGER,
    PRIMARY KEY (trainer_id),
    FOREIGN KEY (trainer_id, pkm_id_1) REFERENCES owns(trainer_id, pkm_id),
    FOREIGN KEY (trainer_id, pkm_id_2) REFERENCES owns(trainer_id, pkm_id),
    FOREIGN KEY (trainer_id, pkm_id_3) REFERENCES owns(trainer_id, pkm_id),
    FOREIGN KEY (trainer_id, pkm_id_4) REFERENCES owns(trainer_id, pkm_id),
    FOREIGN KEY (trainer_id, pkm_id_5) REFERENCES owns(trainer_id, pkm_id),
    FOREIGN KEY (trainer_id, pkm_id_6) REFERENCES owns(trainer_id, pkm_id)
);

-- It should be created when a battle degins,
-- and delete when battle ends
-- totally 12 rows
CREATE TABLE fighting_status (
    trainer_id INTEGER NOT NULL,
    pkm_id     INTEGER NOT NULL UNIQUE,
    -- The first pokemon set to 1
    choosen    TINYINT DEFAULT 0, 
    hp         INTEGER,
    max_hp     INTEGER,
    -- health (NULL), burn, Freeze, Paralysis, Poison, Badly poisoned, sleep
    status     VARCHAR(20) DEFAULT NULL,
    -- Badly poisoned 
        -- -n/16 hp very turn, reset when switch
    -- Sleep
        -- 2~5 turn (countdown), reset when switch
    status_count INTEGER DEFAULT NULL,
    sp_status   VARCHAR(20) DEFAULT NULL, -- confuse, attracted, ...
    -- -6 ~ +6
    atk         TINYINT DEFAULT 0,
    def         TINYINT DEFAULT 0,
    spatk        TINYINT DEFAULT 0,
    spdef        TINYINT DEFAULT 0,
    spd         TINYINT DEFAULT 0,
    acc         TINYINT DEFAULT 0,
    evasion     TINYINT DEFAULT 0
);

-- handler when entering a fight
DELIMITER !
-- import pkm hp
CREATE TRIGGER trg_fight_insert BEFORE INSERT
    ON fighting_status FOR EACH ROW
BEGIN
    DECLARE pkm_hp INTEGER;
    DECLARE hi INTEGER;

    IF ISNULL(NEW.pkm_id) THEN
        -- if pkm_id is null, data will be ignored
        SET NEW.pkm_id=NULL;
    ELSE
        SELECT hp INTO pkm_hp
            FROM pokemon_view
            WHERE pkm_id=NEW.pkm_id;

        SET NEW.hp = pkm_hp;
        SET NEW.max_hp = pkm_hp;
    END IF;
END !

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
    END WHILE;
END !

DELIMITER ;

CREATE TABLE fight_log (
    msg VARCHAR(100) NOT NULL
);



/* procedure fight
check_speed()
attack_first()
additional_effect_first()
attack_second()
additional_effect_second()
#poison, burn, ...
process_status()

procedure form_team
choose_pkm
set_move
set_ability
set_nature
set_strength */
