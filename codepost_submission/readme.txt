# step 1
download data from google drive (see link-to-data.txt)


# step 2
start mysql and run the commands:
(we put the trigger in setup.sql instead of setup-routines.sql)
```
USE pokedb
source setup.sql
source setup-passwords.sql
source grant-permissions.sql
source load-data.sql
source queries.sql
source setup-routines.sql
```


# step 3
make sure the /pkmimg is downloaded and put in the same direction with app-client.py
You can create your own team or login with the prebuilt account/password:
```
Cynthia / cyn321
Blue / blue123
```
This is a 1v1 battle with only 1 UI, so we image two player sit in front of the same computer,
take turns inputing commands
Run python app-client.py, which will allows you to build your own team and start battle


# step 4
Run python app-admin.py, which will connect to the database with ALL PRIVILEGES and having delete-trainers feature


# comments
## If any bug happen, please contact us or download the latest version from github:
https://github.com/Claude0311/relational_database_final

## Dataset source
https://github.com/veekun/pokedex/tree/master/pokedex/data/csv
