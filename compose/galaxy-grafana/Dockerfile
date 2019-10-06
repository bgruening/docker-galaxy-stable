FROM grafana/grafana:5.4.3
ADD grafana.db /var/lib/grafana/grafana.db
ADD influxdb.yaml /etc/grafana/provisioning/datasources/influxdb.yaml
ADD boards.yaml /etc/grafana/provisioning/dashboards/boards.yaml
ADD node-detail.json /var/lib/grafana/dashboards/node-detail.json

# Switch to root since need to chown/chmod
USER root
RUN chown grafana:grafana /var/lib/grafana/grafana.db && \
	chmod 664 /var/lib/grafana/grafana.db
USER grafana
