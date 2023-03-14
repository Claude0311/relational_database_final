# import required module
import os
# assign directory
directory = 'pkmimg'

# iterate over files in
# that directory
maxline = 0
maxfile = ''
for filename in os.listdir(directory):
    f = os.path.join(directory, filename)
    # checking if it is a file
    if os.path.isfile(f):
        with open(f, mode="r", encoding="utf-8") as file:
            l = file.readline()
            c = l.count("▀")-l.count("▄")-l.count(' ')
            if c>maxline:
                maxline = c
                maxfile = f

print(c)
print(f)