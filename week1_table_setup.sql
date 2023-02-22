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

CREATE TABLE movepool (
    mv_id INTEGER AUTO_INCREMENT,
    move_name VARCHAR(20),
    ele_type VARCHAR(8),
    pp TINYINT,
    -- -5 ~ +5
    priority TINYINT DEFAULT 0,
    -- physical, special, status
    catagolry VARCHAR(8),
    -- NULL if is pure status move
    -- 0 ~ 200?
    atk TINYINT,
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
    pkm_id INTEGER AUTO_INCREMENT,
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
        FLOOR((2*strength_hp + IV_hp + FLOOR(EV_hp/4))*lv/100)+lv+10 AS hp, 
        FLOOR( (FLOOR((2*strength_atk + IV_atk + FLOOR(EV_atk/4))*lv/100)+5)*nature_atk ) AS atk, 
        FLOOR( (FLOOR((2*strength_def + IV_def + FLOOR(EV_def/4))*lv/100)+5)*nature_def ) AS def,
        FLOOR( (FLOOR((2*strength_spatk + IV_spatk + FLOOR(EV_spatk/4))*lv/100)+5)*nature_spatk ) AS spatk,
        FLOOR( (FLOOR((2*strength_spdef + IV_spdef + FLOOR(EV_spdef/4))*lv/100)+5)*nature_spdef ) AS spdef,
        FLOOR( (FLOOR((2*strength_spd + IV_spd + FLOOR(EV_spd/4))*lv/100)+5)*nature_spd ) AS spd
    FROM pokemon, pokedex, nature_table;


/* CREATE TABLE trainer (
    trainer_id,
    name,
    password
)

CREATE TABLE owns (
    trainer_id,
    pkm_id
)

CREATE TABLE team (
    trainer_id,
    pkm_id_1,
    pkm_id_2,
    pkm_id_3,
    pkm_id_4,
    pkm_id_5,
    pkm_id_6,
) */

-- It should be created when a battle degins,
-- and delete when battle ends
-- totally 12 rows
/* CREATE TABLE fighting_status (
    trainer_id,
    pkm_id,
    hp,
    -- health, poison, paralyzed, ...
    status,
    sp_status, -- confuse, attracted, ...
    -- -6 ~ +6
    atk,
    def,
    satk,
    sdef,
    spd,
    acc,
    evasion
) */

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
