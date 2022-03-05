#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective grant Postgresql to a user in a scripted manner
# PG_DB="user_some_pgdb_name"; PG_DB_USER=${USER}

PG_DB=$1
PG_DB_USER=$2

su - postgres <<EOF
psql
\connect ${PG_DB} ;
GRANT USAGE ON SCHEMA topology TO ${PG_DB_USER} ;
GRANT SELECT ON ALL TABLES IN SCHEMA topology TO ${PG_DB_USER} ;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA topology TO ${PG_DB_USER} ;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA topology TO ${PG_DB_USER} ;
GRANT USAGE ON SCHEMA public TO ${PG_DB_USER};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${PG_DB_USER};
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO ${PG_DB_USER} ;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${PG_DB_USER} ;
\q
EOF

echo "Grants applied"

