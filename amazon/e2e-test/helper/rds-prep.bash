#!/bin/bash

set -ex

: ${DEFAULT_REGION:=$(aws configure get region)}
: ${REGION:=${DEFAULT_REGION:=eu-central-1}}
: ${RDS_DB_PASSWORD:="cl6nnAzT3R"}
: ${RDS_NAME:=au-test-db}
: ${RDS_DB_USER:=dbmaster}
: ${RDS_DB_NAME:=hdc}

PSQL="docker run -i --rm -e PGPASSWORD=${RDS_DB_PASSWORD} library/postgres psql"

function create_rds() {
    aws rds create-db-instance --db-instance-identifier ${RDS_NAME} --db-name ${RDS_DB_NAME} \
    --allocated-storage 120 --db-instance-class db.t2.medium --engine postgres --backup-retention-period 0 \
    --master-username ${RDS_DB_USER} --master-user-password ${RDS_DB_PASSWORD} --region ${REGION} || echo "already exists"

    aws rds wait db-instance-available --db-instance-identifier ${RDS_NAME} --region ${REGION}

    RDS_DB_ADDRESS=$(aws rds describe-db-instances --db-instance-identifier ${RDS_NAME} --region ${REGION} | jq '.DBInstances[0].Endpoint.Address')
    RDS_DB_ADDRESS=$(echo ${RDS_DB_ADDRESS} | tr -d '"' )
    RDS_DB_PORT=$(aws rds describe-db-instances --db-instance-identifier ${RDS_NAME} --region ${REGION} | jq '.DBInstances[0].Endpoint.Port')

    create_rds_databases
}

function create_rds_databases() {
#command -v psql >/dev/null 2>&1 || { echo "psql not available" ; return 0 ; }
PGPASSWORD=${RDS_DB_PASSWORD} $PSQL --host=${RDS_DB_ADDRESS} --port=${RDS_DB_PORT} --username=${RDS_DB_USER} --dbname ${RDS_DB_NAME} <<EOF 
create user hiveuser with password '${RDS_DB_PASSWORD}' ;
create role rangeruser with password '${RDS_DB_PASSWORD}' CREATEROLE CREATEDB LOGIN ;
create user hdcuser with password '${RDS_DB_PASSWORD}' ;
create user ambariuser with password '${RDS_DB_PASSWORD}' ;
create database hive;
create database ranger;
create database hdc;
create database ambari;
grant all privileges on database hive to hiveuser;
grant all privileges on database ranger to rangeruser;
grant all privileges on database hdc to hdcuser;
grant all privileges on database ambari to ambariuser;
EOF
}

function terminate_rds() {
    aws rds delete-db-instance --db-instance-identifier ${RDS_NAME} --skip-final-snapshot --region ${REGION}  
}

case "$1" in
    "create_rds")
      create_rds
      ;;
    "terminate_rds")
      terminate_rds
      ;;
esac
