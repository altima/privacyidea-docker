FROM python:3.8

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV PRIVACYIDEA_CONFIGFILE=/etc/privacyidea/pi.cfg
ENV PRIVACYIDEA_DB_ADDR=mysql
ENV PRIVACYIDEA_DB_USER=privacyidea
ENV PRIVACYIDEA_DB_PASSWORD=privacyidea
ENV PRIVACYIDEA_DB_DATABASE=privacyidea
ENV PRIVACYIDEA_ADMIN_USER=admin
ENV PRIVACYIDEA_ADMIN_PASSWORD=admin

COPY scripts/entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

WORKDIR /code

RUN mkdir /etc/privacyidea
RUN mkdir /var/log/privacyidea
RUN mkdir /var/lib/privacyidea

#prerequisits
RUN pip install gunicorn
RUN pip install mysqlclient

#application
ENV PRIVACYIDEA_VERSION=3.6.3
RUN pip install -r https://raw.githubusercontent.com/privacyidea/privacyidea/v${PRIVACYIDEA_VERSION}/requirements.txt
RUN pip install privacyidea==${PRIVACYIDEA_VERSION}

#mounts
VOLUME [ "/etc/privacyidea" ]
EXPOSE 5000

#start
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
CMD [ "gunicorn", "privacyidea.app:create_app()", "--bind", "0.0.0.0:5000" ]