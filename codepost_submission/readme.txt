step 1
download data from google drive (see link-to-data.txt)

step 2
start mysql and run the commands:
```
USE pokedb
source setup.sql
source setup-passwords.sql
source grant
source load-data.sql
source queries.sql
source setup-routines.sql
```

step 3
make sure the /pkmimg is downloaded and put in the same direction with app-client.py
run client python, which will allows you to build your own team and fight
You can also login with the prebuilt account/password:
```
Cynthia / cyn321
Blue / blue123
```
This is a 1v1 battle with only 1 UI, so we image two player sit in front of the same computer,
take turns inputing commands

step 4
run python app-admin.py, which will connect to the database with ALL PRIVILEGES and having delete-trainers feature


Note: If any bug happen, please contact us or download the latest version from github:
https://github.com/Claude0311/relational_database_final
