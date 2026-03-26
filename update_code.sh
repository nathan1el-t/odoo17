#!/usr/bin/env bash
set -euo pipefail

OD_SERVICE="odoo17"
LIVE_DIR="/opt/odoo17/odoo17"
TEMP_DIR="/home/azureuser/deploy-temp"
VENV_DIR="/opt/odoo17/odoo17-venv"
ODOO_USER="odoo17"

echo "[1] Stop Odoo (if service exists)"
if systemctl is-active --quiet ${OD_SERVICE} || systemctl is-enabled --quiet ${OD_SERVICE} 2>/dev/null; then
    sudo systemctl stop ${OD_SERVICE}
else
    echo "Service ${OD_SERVICE} not found or not loaded, skipping stop."
fi

echo "[2] Copy updated code (no delete, safe merge)"
sudo cp -rT --no-preserve=ownership "${TEMP_DIR}/" "${LIVE_DIR}/"

echo "[3] Install updated requirements (if exists)"
if [ -f "${LIVE_DIR}/requirements.txt" ]; then
    sudo -u ${ODOO_USER} bash -lc "
        source ${VENV_DIR}/bin/activate &&
        pip install --upgrade pip -q --disable-pip-version-check &&
        pip install -r ${LIVE_DIR}/requirements.txt \
            --upgrade --upgrade-strategy only-if-needed \
            --disable-pip-version-check -q
    "
fi

echo "[4] Fix file ownership"
sudo chown -R ${ODOO_USER}:${ODOO_USER} ${LIVE_DIR}

echo "[5] Start Odoo (if service exists)"
if systemctl list-unit-files ${OD_SERVICE}.service | grep -q ${OD_SERVICE}; then
    sudo systemctl start ${OD_SERVICE}
else
    echo "Service ${OD_SERVICE} not found, skipping start. You may need to install the service manually later."
fi

echo "Deployment complete."
