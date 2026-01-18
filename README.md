# Grafana

Grafana is an open source and composable observability and data visualization platform. Visualize metrics, logs, and traces from multiple sources like Prometheus, Loki, Elasticsearch, InfluxDB, Postgres and many more.

grafana.com

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Grafana_logo.svg/800px-Grafana_logo.svg.png" alt="grafana logo" width="30%" height="auto">

## How to use this Makejail

```sh
mkdir -p .volumes/data
mkdir -p .volumes/conf
appjail makejail \
    -j grafana \
    -f gh+AppJail-makejails/grafana \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=3000 \
    -o fstab="$PWD/.volumes/data grafana-data <volumefs>" \
    -o fstab="$PWD/.volumes/conf grafana-conf <volumefs>"
```

### Arguments (stage: build):

* `grafana_tag` (default: `14.3`): see [#tags](#tags).
* `grafana_ajspec` (default: `gh+AppJail-makejails/grafana`): Entry point where the `appjail-ajspec(5)` file is located.

### Volumes

| Name           | Owner | Group | Perm | Type | Mountpoint             |
| -------------- | ----- | ----- | ---- | ---- | ---------------------- |
| grafana-data   | 904   | 904   | 750  |  -   | /var/db/grafana        |
| grafana-conf   | 0     | 0     |  -   |  -   | /usr/local/etc/grafana |

## Tags

| Tag    | Arch    | Version        | Type   |
| ------ | ------- | -------------- | ------ |
| `14.3` | `amd64` | `14.3-RELEASE` | `thin` |
| `15` | `amd64` | `15` | `thin` |
