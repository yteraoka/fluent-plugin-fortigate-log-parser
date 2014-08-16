fluent-plugin-fortigate-log-parser
==================================

FortiGate syslog parser for Fluentd

This fluentd plugin parse CSV format FortiGate log

You can use GeoLite Country file for World Map in Kibana.

You can build poor man's FortiAnalyzer.

## Plugin setup

With td-agent:

Put `out_fortigate_syslog_parser.rb` into /etc/td-agent/plugin directory.

## FortiGate config

```
$ show log syslogd2 setting
config log syslogd2 setting
    set status enable
    set server "10.20.30.40"
    set csv enable
    set facility local6
end
```

## Sample td-agent (fluentd) config

```:td-agent.conf
<source>
  type tail
  format none
  path /var/log/local6/%Y%m%d/fortigate
  tag raw.fortigate
  pos_file /var/log/td-agent/fortidate.pos
</source>

<match raw.fortigate>
  type fortigate_log_parser
  remove_prefix raw
  country_map_file /etc/td-agent/country.map
  fortios_version 5
</match>

<match fortigate>
  type rewrite_tag_filter
  rewriterule1 type ^traffic$ traffic.fortigate
  rewriterule2 type ^utm$     utm.fortigate
  rewriterule3 type ^event$   event.fortigate
</match>

<match traffic.fortigate>
  type elasticsearch
  host kibana-server
  port 9200
  logstash_format true
  logstash_prefix fg_traffic
  flush_interval 5s
</match>

<match utm.fortigate>
  type elasticsearch
  host kibana-server
  port 9200
  logstash_format true
  logstash_prefix fg_utm
  flush_interval 10s
</match>

<match event.fortigate>
  type elasticsearch
  host kibana-server
  port 9200
  logstash_format true
  logstash_prefix fg_event
  flush_interval 10s
</match>
```

Fluentd merged fluent-plugin-tail-ex features in v0.10.45.
And td-agent 1.1.19 include fluentd v0.10.45.

## Generate country.map file

```
curl -O http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip
unzip GeoIPCountryCSV.zip
ruby mkCountryMap.rb GeoIPCountryWhois.csv > country.map
```
