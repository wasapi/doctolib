#!/bin/bash

USER_AGENT="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0"
BASE_URL=www.doctolib.fr
START_DATE=$(date +%Y-%m-%d)
NB_JOURS=2
PRINT_CMD=0

usage() { echo "Usage: $0 -n <nom>/<ville>/<spécialité> [-d <YYYY-MM-DD>] [-j <2-15>] [-m <entier>] [-l <entier>]" 1>&2; exit 1; }

while getopts "n:d:j:m:l:" opt; do
    case "${opt}" in
        n)
            PRACTICE_NAME=${OPTARG##*/}
	    PRACTICE_CITY=$(echo ${OPTARG} | cut -d/ -f2)
	    PRACTICE_TYPE=${OPTARG%%/*}
	    PRACTICE_FULLNAME=${OPTARG}
            ;;
        d)
            START_DATE=${OPTARG}
            ;;
        j)
            NB_JOURS=${OPTARG}
	    [ ${NB_JOURS} -ge 2 ] && [ ${NB_JOURS} -le 15 ] || usage
            ;;
        m)
            VISIT_MOTIVES_IDS=${OPTARG}
            ;;
        l)
            PRACTICE_IDS=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${PRACTICE_FULLNAME}" ]; then
    usage
fi

#Motif de visite
if [ -z "${VISIT_MOTIVES_IDS}" ]; then
  PRINT_CMD=1
  curl -sA "${USER_AGENT}" https://${BASE_URL}/booking/${PRACTICE_NAME}.json | jq -r '.data.visit_motives[] | "\(.id) => \(.name)"'
  read -r -p "Sélectionner un motif de visite (id): " VISIT_MOTIVES_IDS
fi

#Agenda
AGENDA_IDS=$(curl -sA "${USER_AGENT}" https://${BASE_URL}/booking/${PRACTICE_NAME}.json | jq -jr '.data.agendas[] | "\(.id)-"' | sed 's/-$//')

#Localisation
if [ -z "${PRACTICE_IDS}" ]; then
  PRINT_CMD=1
  curl -sA "${USER_AGENT}" https://${BASE_URL}/${PRACTICE_FULLNAME}.json | jq -r '.data.places[] | "\(.practice_ids[0]) => \(.short_name) \(.full_address)"'
  read -r -p "Sélectionner un localisation (id): " PRACTICE_IDS
fi

#Requète

if [ ${PRINT_CMD} -eq 1 ]; then
  echo "commande:"
  echo "${0} -n ${PRACTICE_FULLNAME} -d ${START_DATE} -j ${NB_JOURS} -m ${VISIT_MOTIVES_IDS} -l ${PRACTICE_IDS}"
  echo "url:"
  echo "https://${BASE_URL}/availabilities.json?start_date=${START_DATE}&visit_motive_ids=${VISIT_MOTIVES_IDS}&agenda_ids=${AGENDA_IDS}&practice_ids=${PRACTICE_IDS}&limit=${NB_JOURS}"
  echo "Créneaux:"
fi

curl -sA "${USER_AGENT}" "https://${BASE_URL}/availabilities.json?start_date=${START_DATE}&visit_motive_ids=${VISIT_MOTIVES_IDS}&agenda_ids=${AGENDA_IDS}&practice_ids=${PRACTICE_IDS}&limit=${NB_JOURS}" | jq -r .availabilities[].slots[]
