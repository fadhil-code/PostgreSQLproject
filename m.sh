#!/bin/bash
# Allow traffic on port 5432
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
iptables -A INPUT -p tcp --sport 5432 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 5432 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 5432 -j ACCEPT
# Installing Postgres files...
pt-get update
apt-get install -y curl gnupg2
echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" >> /etc/apt/sources.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql
service postgresql restart
# Create a user
#CREATE USER replicant REPLICATION LOGIN CONNECTION LIMIT 2 ENCRYPTED PASSWORD 'root'
psql -U postgres -c "CREATE USER replicant REPLICATION LOGIN CONNECTION LIMIT 2 ENCRYPTED PASSWORD 'root';"
# Configuring PostgreSQL
sed -i "s/#listen_addresses = 'localhsot'/ listen_addresses = '*'/" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#hot_standby = off/hot_standby = on/" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#wal_level = minimal/wal_level = replica/" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#max_wal_senders = 1/max_wal_senders = 10/" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#wal_keep_segments = 32/wal_keep_segments = 32/" /etc/postgresql/12/main/postgresql.conf
# user connection
cp /etc/postgresql/12/main/pg_hba.conf /etc/postgresql/12/main/pg_hba{`date +%s`}.bkp
sed  -i '/host    replication/d' /etc/postgresql/12/main/pg_hba.conf
echo "host    replication     replica             127.0.0.1/32                 md5" | tee -a /etc/postgresql/12/main/pg_hba.conf
echo "host    replication     replica             192.168.0.2/24                 md5" | tee -a /etc/postgresql/12/main/pg_hba.conf
echo "host    replication     replica             192.168.0.3/24                 md5" | tee -a /etc/postgresql/12/main/pg_hba.conf
service postgresql restart

