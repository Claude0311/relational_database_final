# import required module
import os
import csv
# assign directory
directory = 'pkmimg'

with open('pokedex_cleanup.csv', encoding="utf-8") as f1:
    f1_csv = csv.reader(f1, delimiter=',')
    
    for row in f1_csv:
        name = row[1].lower().replace('.','')
        if name=='pkm_name': continue
        print(name)
        with open('pkmimg/%s'%name, mode="r", encoding="utf-8" ) as f2:
            print(f2.read())