DROP USER IF EXISTS 'appadmin'@'localhost';
DROP USER IF EXISTS 'appclient'@'localhost';

CREATE USER 'appadmin'@'localhost' IDENTIFIED BY 'adminpw';
CREATE USER 'appclient'@'localhost' IDENTIFIED BY 'clientpw';
-- Can add more users or refine permissions
GRANT ALL PRIVILEGES ON final_project.* TO 'appadmin'@'localhost';
GRANT SELECT, EXECUTE ON final_project.* TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON final_project.`trainer` TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON final_project.`pokemon` TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON final_project.`owns` TO 'appclient'@'localhost';
GRANT SELECT, INSERT, UPDATE ON final_project.`team` TO 'appclient'@'localhost';
GRANT ALL PRIVILEGES ON final_project.`fighting_status` TO 'appclient'@'localhost';
GRANT ALL PRIVILEGES ON final_project.`fight_log` TO 'appclient'@'localhost';

FLUSH PRIVILEGES;
