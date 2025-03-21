FROM docker.io/httpd:2.4

COPY etc/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY etc/webdav.conf /usr/local/apache2/conf/webdav.conf
COPY scripts/start.sh /opt/start.sh

RUN chmod +x "/opt/start.sh"

CMD "/opt/start.sh"
