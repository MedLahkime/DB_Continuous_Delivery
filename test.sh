#!/bin/bash

#
#========================================================================================================
# NOM DU SCRIPT 		:  clone_db_from_SCRIPTs.sh
#========================================================================================================
#--------------------------------------------------------------------------------------------------------
# AUTEURS				: MLE
# DATE DE CREATION		: 13/05/2020
# VERSION 	 			: 1.0
# -------------------------------------------------------------------------------------------------------
# OBJECT				: Ce SCRIPT a pour objectif de preparer les nouveaux SCRIPTs sql qui doivent etre
#						  testes sur le clone de la base de donnees
#						  Il va recuperer les SCRIPTs sql depuis leur emplacement relatif au deploiement en 
#						  cours. Ensuite il va extraire les noms des tables, vues, procedures, et fonctions
#						  pour copier et exporter juste une partie de la base de donnees qu lieu d'une
#						  exportation complete de cette derniere.  
#--------------------------------------------------------------------------------------------------------
# PARAMETRES 			: $1 Chemin dans le file system du workspace job en cours d'execution
#						  $2 Nom d'utilisateur pour se connecter a la base de donnees
#						  $3 Mot de passe pour se connecter a la base de donnees
#						  $4 Numero de la version en cours qui permettra de deduire les dossiers de 
#						  PATT_UTILS/sql a cibler pour deduire les SCRIPTs a preparer pour le deploiement
#						  Exemple : 6.1.4
#						  $5 plateforme source a partir de laquelle prendre les sources sql et les binaires.
#					      Ce parametre n'est present que dans le cas des plateformes (cibles) recette, test
# 						  et prod
#					   	  $6 Nom du projet contient les SCRIPTs sql
#--------------------------------------------------------------------------------------------------------
#========================================================================================================



export username=$1
export password=$2
# VERSION_NUMBER=$4
# VERSION_NAME="V$4"
# PROJECT_SQL_NAME=$5
# PLATEFORME_SOURCE=$6
 # SCRIPT_BASEDIR_PATH=$(dirname "$SCRIPT_PATH")
# . ${SCRIPT_BASEDIR_PATH}/environment_config.sh

# if [[ ${PLATEFORME_SOURCE} != "" ]]; then 
    # VERSIONED_SQL_SCRIPTS_DIRECTORY=${SQL_DEPLOYMENT_DIRECTORY}/${PLATEFORME_SOURCE}/$VERSION_NUMBER/PROCESSED
# else 
    # VERSIONED_SQL_SCRIPTS_DIRECTORY=${VERSIONED_GIT_SQL_SCRIPTS_DIRECTORY}
# fi
#--------------------------------------------------------------------------------------------------------------------------------------------
_USED_DBS=()
_USED_VIEWS=()
_USED_TABLES=()
_USED_TRIGGERS=()
_USED_FUNCTIONS=()
_USED_PROCEDURES=()
_SCRIPTS_LIST=(temp_sql_scripts/test_1.sql temp_sql_scripts/test_2.sql temp_sql_scripts/test_3.sql)
# _SCRIPTS_LIST=( $( mysql --batch mysql -u $username -p$password -N -e "SELECT SCRIPT_name  FROM pixid.SCRIPTs WHERE script_handled ='encoure'" ) )
printf '%s\n' "${_SCRIPTS_LIST[@]}"

# _SCRIPTS_LIST=("${_SCRIPTS_LIST[@]/#/C:/Users/Med/Documents/mypfe/BashTask/temp_sql_scripts/}")
function union_of_arrays() { 
	unset _UNION_MATCH
	_UNION_MATCH=()
	local -n _ARRAY_ONE=$1
	local -n _ARRAY_TWO=$2
	for WORD in ${_ARRAY_ONE[@]}
	do
		if [[ (${_ARRAY_TWO[*]} =~ "$WORD") ]]; then
            _UNION_MATCH+=($WORD)
        fi
	done
}
_OUTPUT="/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;\n /*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;\n /*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;\n /*!50503 SET NAMES utf8mb4 */;\n /*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;\n /*!40103 SET TIME_ZONE='+00:00' */;\n /*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n /*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n /*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;\n /*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;\n"
for SCRIPT in ${_SCRIPTS_LIST[@]}
do
	_CURRENTSCRIPT+=($(echo $(cat $SCRIPT | sed 's/[^0-9  _  a-z  A-Z]/ /g' | tr '[:upper:]' '[:lower:]')))
	
	
	_DB_NAMES=( $( mysql --batch mysql -u $username -p$password -N -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME!='mysql' AND SCHEMA_NAME!='information_schema' AND SCHEMA_NAME!='performance_schema' AND SCHEMA_NAME!='sys' AND SCHEMA_NAME!='sakila';" ) )
	union_of_arrays _CURRENTSCRIPT _DB_NAMES 
	_USED_DBS+=(${_UNION_MATCH[@]})
	_USED_DBS=($(printf "%s\n" "${_USED_DBS[@]}" | sort -u | tr '\n' ' '))
	# $( mysql --batch mysql -u $username -p$password -N -e "USE pixid;update scripts set db_in_script ='${_USED_DBS[@]}' WHERE script_name='${SCRIPT}';" ) 
	for DB in ${_USED_DBS[@]}
	do
		_VIEW_NAMES=( $( mysql --batch mysql -u $username -p$password -N -e "select TABLE_NAME from information_schema.tables where TABLE_TYPE='VIEW' AND TABLE_SCHEMA= '${DB}';" ) )
		union_of_arrays _CURRENTSCRIPT _VIEW_NAMES 
		_USED_VIEWS+=("${_UNION_MATCH[@]/#/$DB.}")
	done
	_USED_VIEWS=($(printf "%s\n" "${_USED_VIEWS[@]}" | sort -u | tr '\n' ' '))
	for VIEW in ${_USED_VIEWS[@]}
	do
		CURRENT_VIEW=(${VIEW//./ })
		_USED_TABLES+=( $( mysql --batch mysql -u $username -p$password -N -e "SELECT DISTINCT CONCAT(TABLE_SCHEMA, '.', TABLE_NAME) FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE WHERE TABLE_SCHEMA= '${CURRENT_VIEW[0]}' AND VIEW_NAME= '${CURRENT_VIEW[1]}';" ) )
	done
	
	for DB in ${_USED_DBS[@]}
	do
		_PROCEDURE_NAMES=( $( mysql --batch mysql -u $username -p$password -N -e "SELECT SPECIFIC_NAME FROM INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='${DB}' AND ROUTINE_TYPE='PROCEDURE';" ) )
		union_of_arrays _CURRENTSCRIPT _PROCEDURE_NAMES 
		_USED_PROCEDURES+=("${_UNION_MATCH[@]/#/$DB.}")
	done
	_USED_PROCEDURES=($(printf "%s\n" "${_USED_PROCEDURES[@]}" | sort -u | tr '\n' ' '))
	_ADDITIONNAL_SCRIPTS=()
	for procedure in ${_USED_PROCEDURES[@]}
	do
		set -f        # disable globbing
		IFS=$'\n'     # set field separator to NL (only)
		PROCEDURE_CREATION=( $( mysql -uroot -pmed123 -N -e "show create procedure ${procedure};" ) )
		if [ ${#PROCEDURE_CREATION[@]} != 0 ]; then
		IFS=$'\t' read -r col1 col2 col3 col4  <<< "${PROCEDURE_CREATION[0]}"
		_PROCEDURE_OUTPUT="${procedure} ${col3}"
		fi
		_ADDITIONNAL_SCRIPTS+=($(printf $_PROCEDURE_OUTPUT | sed 's/[^0-9 _  a-z  A-Z]/ /g' | tr '[:upper:]' '[:lower:]'))
		printf '%s\n' "${_ADDITIONNAL_SCRIPTS[@]}"
	done
		IFS=' '
		
	for DB in ${_USED_DBS[@]}
	do
		_function_names=( $( mysql --batch mysql -u $username -p$password -N -e "SELECT SPECIFIC_NAME FROM INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='${DB}' AND ROUTINE_TYPE='fUNCTION';" ) )
		union_of_arrays _CURRENTSCRIPT _function_names 
		_USED_FUNCTIONS+=("${_UNION_MATCH[@]/#/$DB.}")
	done
	_USED_FUNCTIONS=($(printf "%s\n" "${_USED_FUNCTIONS[@]}" | sort -u | tr '\n' ' '))	
	_CURRENTSCRIPT+=${_ADDITIONNAL_SCRIPTS[@]}
	
	for DB in ${_USED_DBS[@]}
	do
		_table_names=( $( mysql --batch mysql -u $username -p$password -N -e "select TABLE_NAME from information_schema.tables where TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='${DB}';" ) )

		union_of_arrays _CURRENTSCRIPT _table_names 
		_USED_TABLES+=("${_UNION_MATCH[@]/#/$DB.}")
	done	
	_USED_TABLES=($(printf "%s\n" "${_USED_TABLES[@]}" | sort -u | tr '\n' ' '))
	_CURRENTSCRIPT=()
done

for constraint_table in ${_USED_TABLES[@]}
do
	CURRENT_TABLE=(${constraint_table//./ })
	_CONSTRAINT_TABLES=( $( mysql --batch mysql -u $username -p$password -N -e "SELECT CONCAT(TABLE_SCHEMA, '.', REFERENCED_TABLE_NAME) FROM information_schema.KEY_COLUMN_USAGE WHERE CONSTRAINT_SCHEMA = '${CURRENT_TABLE[0]}' AND TABLE_NAME = '${CURRENT_TABLE[1]}' AND REFERENCED_TABLE_NAME != 'null';" ) )
	_USED_TABLES+=(${_CONSTRAINT_TABLES[@]})
done
_USED_TABLES=($(printf "%s\n" "${_USED_TABLES[@]}" | sort -u | tr '\n' ' '))

for DB in ${_USED_DBS[@]}
do
	_OUTPUT="${_OUTPUT} \nDROP DATABASE IF EXISTS $DB;CREATE DATABASE $DB;"
done
for table in ${_USED_TABLES[@]}
do
	IFS=' '
	CURRENT_TABLE=(${table//./ })
	DB_TEMP_NAME=${CURRENT_TABLE[0]}
	set -f        # disable globbing
	IFS=$'\n'     # set field separator to NL (only)
	TABLE_CREATION=( $( mysql -uroot -pmed123 -N -e "show create table ${table};" ) )
	if [ ${#TABLE_CREATION[@]} != 0 ]; then	
	IFS=$'\t' read -r col1 col2   <<< "${TABLE_CREATION[0]}"
	_OUTPUT="${_OUTPUT} \nUSE $DB_TEMP_NAME;\n${col2};"
	fi
done
for VIEW in ${_USED_VIEWS[@]}
do
	IFS=' '
	CURRENT_VIEW=(${VIEW//./ })
	DB_TEMP_NAME=${CURRENT_VIEW[0]}
	set -f        # disable globbing
	IFS=$'\n'     # set field separator to NL (only)
	VIEW_CREATION=( $( mysql -uroot -pmed123 -N -e "show create VIEW ${VIEW};" ) )
	if [ ${#VIEW_CREATION[@]} != 0 ]; then
	IFS=$'\t' read -r col1 col2 col3   <<< "${VIEW_CREATION[0]}"
	_OUTPUT="${_OUTPUT} \nUSE $DB_TEMP_NAME;\n${col2};"
	fi
done
for procedure in ${_USED_PROCEDURES[@]}
do
	IFS=' '
	CURRENT_PROCEDURE=(${procedure//./ })
	DB_TEMP_NAME=${CURRENT_PROCEDURE[0]}
	set -f        # disable globbing
	IFS=$'\n'     # set field separator to NL (only)
	PROCEDURE_CREATION=( $( mysql -uroot -pmed123 -N -e "show create procedure ${procedure};" ) )
	if [ ${#PROCEDURE_CREATION[@]} != 0 ]; then
	IFS=$'\t' read -r col1 col2 col3 col4  <<< "${PROCEDURE_CREATION[0]}"
	_OUTPUT="${_OUTPUT} \nUSE $DB_TEMP_NAME;\n delimiter // \n${col3}; // \n delimiter ; "
	fi
done
for function in ${_USED_FUNCTIONS[@]}
do
	IFS=' '
	current_function=(${function//./ })
	DB_TEMP_NAME=${current_function[0]}
	set -f        # disable globbing
	IFS=$'\n'     # set field separator to NL (only)
	function_creation=( $( mysql -uroot -pmed123 -N -e "show create function ${function};" ) )
	if [ ${#function_creation[@]} != 0 ]; then
	IFS=$'\t' read -r col1 col2 col3 col4  <<< "${function_creation[0]}"
	_OUTPUT="${_OUTPUT} \nUSE $DB_TEMP_NAME; \n delimiter // \n ${col3}// \n delimiter ; "
	fi
done
touch output.sql
printf '%b\n' "${_OUTPUT[@]}"> output.sql
