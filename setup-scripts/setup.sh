# setup.sh
# Use command-line arguments
ORACLE_PASSWORD=$ORACLE_PASSWORD
ORACLE_DATABASE=$ORACLE_DATABASE
# Use the variables in your script
sqlplus system/$ORACLE_PASSWORD@//localhost:1521/$ORACLE_DATABASE <<-EOSQL
    -- Your SQL commands here
	@createUser.sql $ORACLE_DATABASE SUPPORT
	@createUser.sql $ORACLE_DATABASE SUPPORT
	
EOSQL




