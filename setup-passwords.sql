DROP FUNCTION make_salt;
DROP FUNCTION authenticate;
DROP PROCEDURE sp_add_user;
-- File for Password Management section of Final Project

-- (Provided) This function generates a specified number of characters for using as a
-- salt in passwords.
DELIMITER !
CREATE FUNCTION make_salt(num_chars INT) 
RETURNS VARCHAR(20) NOT DETERMINISTIC
BEGIN
    DECLARE salt VARCHAR(20) DEFAULT '';

    -- Don't want to generate more than 20 characters of salt.
    SET num_chars = LEAST(20, num_chars);

    -- Generate the salt!  Characters used are ASCII code 32 (space)
    -- through 126 ('z').
    WHILE num_chars > 0 DO
        SET salt = CONCAT(salt, CHAR(32 + FLOOR(RAND() * 95)));
        SET num_chars = num_chars - 1;
    END WHILE;

    RETURN salt;
END !
DELIMITER ;

-- [Problem 1a]
-- Adds a new user to the trainer table, using the specified password (max
-- of 20 characters). Salts the password with a newly-generated salt value,
-- and then the salt and hash values are both stored in the table.
DELIMITER !
CREATE PROCEDURE sp_add_user(new_username VARCHAR(20), password VARCHAR(20))
BEGIN
  DECLARE salt CHAR(8);
  DECLARE password_hash BINARY(64);
  SELECT make_salt(8) AS salt INTO salt;
  SELECT SHA2(CONCAT(salt, password), 256) INTO password_hash;
  INSERT INTO trainer (trainer_name, salt, password_hash)  
  VALUES (new_username, salt, password_hash);
END !
DELIMITER ;

-- [Problem 1b]
-- Authenticates the specified username and password against the data
-- in the user_info table.  Returns 1 if the user appears in the table, and the
-- specified password hashes to the value for the user. Otherwise returns 0.
DELIMITER !
CREATE FUNCTION authenticate(username VARCHAR(20), password VARCHAR(20))
RETURNS TINYINT DETERMINISTIC
BEGIN
  DECLARE user_salt CHAR(8);
  DECLARE pswd_hash BINARY(64);

  IF username IN (SELECT trainer_name FROM trainer) THEN
    SELECT salt INTO user_salt
            FROM trainer
            WHERE trainer_name=username;
    SELECT password_hash INTO pswd_hash
            FROM trainer
            WHERE trainer_name=username;
    IF pswd_hash = SHA2(CONCAT(user_salt, password), 256) THEN
      RETURN 1;
    ELSE  
      RETURN 0;
    END IF;
  ELSE
    RETURN 0;
  END IF;
END !
DELIMITER ;

-- [Problem 1c]
-- Add at least two users into your user_info table so that when we run this file,
-- we will have examples users in the database.
CALL sp_add_user('Josh', 'abc123');
CALL sp_add_user('Jeff', 'password123');
-- [Problem 1d]
-- Optional: Create a procedure sp_change_password to generate a new salt and change the given
-- user's password to the given password (after salting and hashing)
