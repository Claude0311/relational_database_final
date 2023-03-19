DROP USER IF EXISTS 'appadmin'@'localhost';
DROP USER IF EXISTS 'appclient'@'localhost';

CREATE USER 'appadmin'@'localhost' IDENTIFIED BY 'adminpw';
CREATE USER 'appclient'@'localhost' IDENTIFIED BY 'clientpw';
-- Can add more users or refine permissions
GRANT ALL PRIVILEGES ON pokedb.* TO 'appadmin'@'localhost';
GRANT SELECT, EXECUTE ON pokedb.* TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON pokedb.`trainer` TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON pokedb.`pokemon` TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON pokedb.`owns` TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON pokedb.`team` TO 'appclient'@'localhost';
GRANT ALL PRIVILEGES ON pokedb.`fighting_status` TO 'appclient'@'localhost';
GRANT ALL PRIVILEGES ON pokedb.`fight_log` TO 'appclient'@'localhost';

FLUSH PRIVILEGES;
