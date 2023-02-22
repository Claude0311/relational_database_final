CREATE TABLE pokedex (
    pkdex,
    pkm_name,
    ele_type_1,
    ele_type_2, # might be NULL
    # Species strength 0~255
    strength_hp,
    strength_atk,
    strength_def,
    strength_spatk,
    strength_spdef,
    strength_spd,
)

CREATE TABLE movepool (
    mv_id,
    move_name,
    ele_type,
    pp,
    priority,
    # physical, special, status
    catagolry, 
    # NULL if is pure status move
    atk,
    accuracy,
    # additional effect, NULL if is pure atk move
    # Flinch, +- atk, status, confuse
    prob,
    effect,
    # times: 1, 2, or 2~5
    times
)
# not supporting:
# demage itself, heal itself, field, mist, constant damage(dragon rage)
# Metronome, One-Hit-KO


CREATE TABLE know (
    pkdex,
    mv_id
)

CREATE TABLE type_chart (
    atker,
    defer,
    effective, # 0, 0.5, 1, 2
)

CREATE TABLE pokemon (
    pkm_id,
    pkdex,
    # default 50, not planning to design exp system
    lv, 
    nature,
    gender,
    mv_id_1,
    mv_id_2,
    mv_id_3,
    mv_id_4,
    # can select manually, 
    # sum 510, each max 252
    EVs,
    # random;y generated, 0~255 
    IVs,
)

# automatically generated from EVs, IVs, LV, Species strength 
CREATE VIEW pokemon_view (
    pkm_id,
    hp,
    atk,
    def,
    sp_atk,
    sp_def,
    spd
)

CREATE TABLE trainer (
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
)

# It should be created when a battle degins,
# and dropped when battle ends
# totally 12 rows
CREATE TABLE fighting_status (
    trainer_id,
    pkm_id,
    hp,
    # health, poison, paralyzed, ...
    status,
    sp_status, # confuse, attracted, ...
    # -6 ~ +6
    atk,
    def,
    satk,
    sdef,
    spd,
    acc,
    evasion
)

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
