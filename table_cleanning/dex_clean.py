import csv
import re

datas = []
max_des = 0
with open('pokedex.csv') as f:
    spamreader = csv.reader(f, delimiter=',')
    # header = next(spamreader) # ignore first line
    # print(header)
    last_ind = ''
    for [pkdex,pkm_name,ele_type_1,ele_type_2,strength_hp,strength_atk,strength_def,strength_spatk,strength_spdef,strength_spd] in spamreader:
        if pkdex==last_ind: continue
        else: last_ind = pkdex

        if ele_type_2=='': ele_type_2 = 'NULL'

        datas.append([pkdex,pkm_name,ele_type_1,ele_type_2,strength_hp,strength_atk,strength_def,strength_spatk,strength_spdef,strength_spd])

print('max des', max_des)

with open('pkdex_cleanup.csv', 'w', newline='') as csvfile:
    spamwriter = csv.writer(csvfile, delimiter=',',
                            quotechar='"', quoting=csv.QUOTE_MINIMAL)
    # spamwriter.writerow(['mv_id','move_name','ele_type','pp','priority','category','atk','accuracy','prob','effect','description','effect_target','min_times','max_times'])
    for data in datas:
        spamwriter.writerow(data)
