#!/usr/bin/env bash
set -euo pipefail

# Configuración general
SSH_HOST=${SSH_HOST:-10.0.0.1}
SSH_PORT=${SSH_PORT:-22}
SSH_USER=${SSH_USER:-1234}
MQTT_BROKER=${MQTT_BROKER:-10.0.10.3}
MQTT_PORT=${MQTT_PORT:-1883}
MQTT_TOPIC=${MQTT_TOPIC:-ssh/primary_diagnosis}
REMOTE_CMD=${REMOTE_CMD:-"show primary_diagnosis"}
INTERVAL=${INTERVAL:-300} # 5 minutos

# Validar SSHPASS
if [ -z "${SSHPASS:-}" ]; then
  echo "ERROR: la variable SSHPASS no está definida"
  exit 1
fi

echo "Iniciando consultas SSH cada ${INTERVAL}s a ${SSH_HOST}, publicando en ${MQTT_BROKER}:${MQTT_PORT}/${MQTT_TOPIC}"

run_once() {
  TIMESTAMP=$(date --iso-8601=seconds)
  echo "️Ejecutando comando SSH en ${SSH_HOST} a las ${TIMESTAMP}"

  OUTPUT=$(sshpass -e ssh -p ${SSH_PORT} \
    -oHostKeyAlgorithms=+ssh-rsa \
    -oPubkeyAcceptedKeyTypes=+ssh-rsa \
    -oStrictHostKeyChecking=no \
    -oUserKnownHostsFile=/dev/null \
    -l "${SSH_USER}" "${SSH_HOST}" "${REMOTE_CMD}" 2>&1) || SSH_RC=$?
  SSH_RC=${SSH_RC:-0}

  PAYLOAD=$(jq -n --arg ts "$TIMESTAMP" --arg host "$SSH_HOST" \
    --arg cmd "$REMOTE_CMD" --arg output "$OUTPUT" \
    --argjson code $SSH_RC \
    '{timestamp:$ts, host:$host, command:$cmd, exit_code:$code, output:$output}')

  mosquitto_pub -h "${MQTT_BROKER}" -p "${MQTT_PORT}" -t "${MQTT_TOPIC}" -m "${PAYLOAD}" || \
    echo "Error publicando MQTT"

  echo "Publicado en MQTT: ${MQTT_TOPIC}"
}

# Bucle infinito
while true; do
  run_once
  sleep "${INTERVAL}"
done
