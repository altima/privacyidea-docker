#!/bin/bash
set -e

create_config(){
  if [ ! -e /etc/privacyidea/pi.cfg ]; then

    cat >/etc/privacyidea/pi.cfg <<EOF
import logging
SUPERUSER_REALM = ['super']
PI_ENCFILE = '/etc/privacyidea/enckey'
PI_AUDIT_KEY_PRIVATE = '/etc/privacyidea/private.pem'
PI_AUDIT_KEY_PUBLIC = '/etc/privacyidea/public.pem'
PI_LOGFILE = '/var/log/privacyidea/privacyidea.log'
PI_LOGLEVEL = logging.INFO
EOF
    if [ !$(grep "^PI_PEPPER" /etc/privacyidea/pi.cfg) ]; then
      # PEPPER does not exist, yet
      PEPPER="$(tr -dc A-Za-z0-9_ </dev/urandom | head -c24)"
      echo "PI_PEPPER = '$PEPPER'" >> /etc/privacyidea/pi.cfg
    fi
    if [ !$(grep "^SECRET_KEY" /etc/privacyidea/pi.cfg || true) ]; then
      # SECRET_KEY does not exist, yet
      SECRET="$(tr -dc A-Za-z0-9_ </dev/urandom | head -c24)"
      echo "SECRET_KEY = '$SECRET'" >> /etc/privacyidea/pi.cfg
    fi
    if [ !$(grep "^SQLALCHEMY_DATABASE_URI" /etc/privacyidea/pi.cfg) ]; then
      echo "SQLALCHEMY_DATABASE_URI = 'mysql://$PRIVACYIDEA_DB_USER:$PRIVACYIDEA_DB_PASSWORD@$PRIVACYIDEA_DB_ADDR/$PRIVACYIDEA_DB_DATABASE'" >> /etc/privacyidea/pi.cfg
    fi

    pi-manage create_enckey
    pi-manage create_audit_keys
    pi-manage createdb

    # default admin
    PRIVACYIDEA_ADMIN_USER=${PRIVACYIDEA_ADMIN_USER:admin}
    PRIVACYIDEA_ADMIN_PASS=${PRIVACYIDEA_ADMIN_PASS:admin}

    if [ -n "${PRIVACYIDEA_ADMIN_USER}" -o -n "${PRIVACYIDEA_ADMIN_PASS}" ]; then
      pi-manage admin add ${PRIVACYIDEA_ADMIN_USER} -p ${PRIVACYIDEA_ADMIN_PASS}
    fi

    # keycloak admin
    PRIVACYIDEA_KEYCLOAK_USER=${PRIVACYIDEA_KEYCLOAK_USER:keycloak}
    PRIVACYIDEA_KEYCLOAK_PASS=${PRIVACYIDEA_KEYCLOAK_PASS:keycloak}

    if [ -n "${PRIVACYIDEA_KEYCLOAK_USER}" -o -n "${PRIVACYIDEA_KEYCLOAK_PASS}" ]; then
      pi-manage admin add ${PRIVACYIDEA_KEYCLOAK_USER} -p ${PRIVACYIDEA_KEYCLOAK_PASS}
    fi

    mkdir -p /var/log/privacyidea
    mkdir -p /var/lib/privacyidea
    touch /var/log/privacyidea/privacyidea.log
    
    chmod 600 /etc/privacyidea/enckey
    chmod 600 /etc/privacyidea/private.pem

  fi
}

create_config

exec $@