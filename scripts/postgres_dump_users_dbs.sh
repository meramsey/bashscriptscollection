#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective dump all Postgresql db's for a cPanel user in a scripted manner
Username=$1

USER_HOME=$(eval echo ~"${Username}") ;
postgres_dump_path="$USER_HOME/pg_dumps"
sudo mkdir -p "${postgres_dump_path}"
for PG_DB in $(sudo cpapi2 --user="${Username}" Postgres listdbs|grep db| grep -v listdbs |sed 's/^[ \t]*//;s/[ \t]*$//'| sed 's/db: //g'| tr '/' '\n'); do echo "${PG_DB}"; su - postgres <<EOF
pg_dump ${PG_DB} -N topology -T spatial_ref_sys > ${PG_DB}.pgsql
echo "$PG_DB Exported /var/lib/pgsql/${PG_DB}.pgsql"
EOF
done
for PG_DB in $(sudo ls -1 /var/lib/pgsql | grep "${Username}"); do echo "${PG_DB}"; sudo mv /var/lib/pgsql/"${PG_DB}" "${postgres_dump_path}"/"${PG_DB}" ; done
sudo chown -R "${Username}":"${Username}" "${postgres_dump_path}"
echo "Checking ${postgres_dump_path}";
sudo ls -lah "${postgres_dump_path}"
