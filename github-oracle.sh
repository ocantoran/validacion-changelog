#!/bin/bash

# Rutas y archivos
declare -r main_url="https://raw.githubusercontent.com/DataDog/integrations-core/refs/heads/master/oracle/CHANGELOG.md"
declare -r log_file="/opt/Oracle-Changelog/changelog_update.log"
declare -r changelog_path="/opt/Oracle-Changelog"

# Función principal
function getChangelog () {
  cd "${changelog_path}" || exit 1

  # Si no existe, descargar por primera vez
  if [[ ! -f CHANGELOG.md ]]; then
    curl -sS -f --retry 3 --retry-delay 5 -O "${main_url}"
    if [[ $? -ne 0 ]]; then
      echo "[ERROR] Falló la descarga inicial desde ${main_url}" >> "$log_file"
      return
    fi
    echo "[INFO] Archivo CHANGELOG.md descargado por primera vez." >> "$log_file"
  else
    # Descargar archivo temporal y validar
    curl -sS -f --retry 3 --retry-delay 5 -o CHANGELOG.md.temp "${main_url}"
    if [[ $? -ne 0 ]]; then
      echo "[ERROR] Falló la descarga del archivo temporal desde ${main_url}" >> "$log_file"
      return
    fi

    # Comparar hash
    md5_temp_value=$(md5sum CHANGELOG.md.temp | awk '{print $1}')
    md5_original_value=$(md5sum CHANGELOG.md | awk '{print $1}')

    if [[ "${md5_temp_value}" == "${md5_original_value}" ]]; then
      rm -f CHANGELOG.md.temp
    else
      timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      echo "[${timestamp}] Se ha detectado una actualización en el CHANGELOG de la integración de Oracle en Datadog. Revisa los cambios aquí: https://github.com/DataDog/integrations-core/blob/master/oracle/CHANGELOG.md" >> "$log_file"
      mv CHANGELOG.md.temp CHANGELOG.md
    fi
  fi
}

# Bucle principal
while true; do
  getChangelog
  sleep 120
done
