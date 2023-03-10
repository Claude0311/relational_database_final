import csv
import re

datas = []
with open('movepool.csv') as f:
    spamreader = csv.reader(f, delimiter=',')
    header = next(spamreader) # ignore first line
    print(header)
    for [mv_id,move_name,ele_type,pp,priority,category,atk,accuracy,prob,description,effect_target,min_times,max_times] in spamreader:
        if mv_id=='': continue
        description = description.lower()
        effect = ''
        if 'burn' in description: effect = 'burn'
        elif 'freeze' in description: effect = 'freeze'
        elif 'paraly' in description: effect = 'paralysis'
        elif 'badly poison' in description: effect = 'badly poison'
        elif 'poison' in description: effect = 'poison'
        elif 'sleep' in description: effect = 'sleep'

        if effect!='':
            description = re.sub(r"\[[^)]*\}", effect, description)

        else:
            if 'special attack' in description: effect = 'spatk '
            elif 'special defense' in description: effect = 'spdef '
            elif 'attack' in description: effect = 'atk '
            elif 'defense' in description: effect = 'def '
            elif 'speed' in description: effect = 'spd '
            elif 'accuracy' in description: effect = 'acc '
            elif 'evasion' in description: effect = 'evasion '

            if 'raise' in description: effect += '+'
            elif 'lower' in description: effect += '-'
            
            if 'by one stage' in description: effect += '1'
            elif 'by two stage' in description: effect += '2'
            elif 'by three stage' in description: effect += '3'
        if effect!='' and prob=='': prob='100'

        datas.append([mv_id,move_name,ele_type,pp,priority,category,atk,accuracy,prob,effect,description,effect_target,min_times,max_times])

with open('movepool_cleanup.csv', 'w', newline='') as csvfile:
    spamwriter = csv.writer(csvfile, delimiter=',',
                            quotechar='"', quoting=csv.QUOTE_MINIMAL)
    spamwriter.writerow(['mv_id','move_name','ele_type','pp','priority','category','atk','accuracy','prob','effect','description','effect_target','min_times','max_times'])
    for data in datas:
        spamwriter.writerow(data)
