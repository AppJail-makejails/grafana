# Grafana

Grafana is an open-source analytics and visualization web application. It connects to time series databases and other data sources, allowing users to build dashboards that display metrics, logs, and traces. Grafana supports data sources including Prometheus, AWS CloudWatch, Graphite, InfluxDB, Elasticsearch, PostgreSQL, and MySQL.

wikipedia.org/wiki/Grafana

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Grafana_logo.svg/500px-Grafana_logo.svg.png" width="30%" height="auto" alt="Grafana logo">

## How to use this Makejail

### Standalone

To run the latest stable version of Grafana, run the following command:

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose="3000:3000" \
    -o template=template.conf \
    ghcr.io/appjail-makejails/grafana grafana
```

Where:

* `appjail oci run` is an AppJail CLI command that runs a new container from an image.
* `-Pd` runs the container in the background, and with `-P`, it runs persistently (this means that any parameters you've specified will be retained after the container is restarted).
* `-o expose="3000:3000"` expose a container’s port(s) to external hosts, allowing they to reach the container’s port via a host port. In this case, we can reach the container’s port 3000 via the host’s port 3000. Remove this argument if you do not want external hosts to be able to access your service and you only need the host to access it using the container's IPv4 address or hostname.
* `-o template=template.conf` specify a custom `appjail-template(5)`. See below.
* `ghcr.io/appjail-makejails/grafana` is the image to run.
* `grafana` assign a logical name to the container (e.g. `grafana`).

**template.conf**:

Although not strictly necessary, `mount.procfs` could be needed to avoid the error `logger=grafana-apiserver t=2026-08-12T15:46:49.768972248-04:00 level=error msg="Could not get process start time, stat /proc/26634: no such file or directory"`.

```
exec.start: "/bin/sh /etc/rc"
exec.stop: "/bin/sh /etc/rc.shutdown jail"
mount.devfs
persist
mount.procfs
```

#### Stop the Grafana container

To stop the Grafana container, run the following command:

```console
$ appjail jail list -j grafana name container_pid
NAME     CONTAINER_PID
grafana  68682
$ appjail stop grafana
```

#### Save your Grafana data

By default, Grafana uses an embedded SQLite version 3 database to store configuration, users, dashboards, and other data. When you run OCI images as containers, changes to these Grafana data are written to the filesystem within the container, which will only persist for as long as the container exists. If you stop and remove the container, any filesystem changes (i.e. the Grafana data) will be discarded. To avoid losing your data, you can set up persistent storage using [AppJail volumes](https://appjail.readthedocs.io/en/latest/fs-mgmt/) for your container.

```console
$ mkdir -p data
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o fstab="$PWD/data /var/db/grafana <pseudofs>" \
    -o expose="3000:3000" \
    -o template=template.conf \
    -e PUID=$(id -u) \
    -e PGID=$(id -g) \
    ghcr.io/appjail-makejails/grafana grafana
```

#### Use environment variables to configure Grafana

Grafana supports specifying custom configuration settings using [environment variables](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#override-configuration-with-environment-variables).

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose="3000:3000" \
    -o template=template.conf \
    -e GF_LOG_LEVEL=debug \
    ghcr.io/appjail-makejails/grafana grafana
```

#### Install plugins in the AppJail container

You can install plugins in Grafana from the official and community [plugins page](https://grafana.com/grafana/plugins) or by using a custom URL to install a private plugin. These plugins allow you to add new visualization types, data sources, and applications to help you better visualize your data.

Grafana currently supports three types of plugins: panel, data source, and app. For more information on managing plugins, refer to [Plugin Management](https://grafana.com/docs/grafana/latest/administration/plugin-management/).

To install plugins in the AppJail container, complete the following steps:

1. Pass the plugins you want to be installed to AppJail with the `GF_PLUGINS_PREINSTALL` environment variable as a comma-separated list.

   This starts a background process that installs the list of plugins while Grafana server starts.

   For example:

   ```console
   $ appjail oci run -Pd \
       -o overwrite=force \
       -o virtualnet=":<random> default" \
       -o nat \
       -o expose="3000:3000" \
       -o template=template.conf \
       -e "GF_PLUGINS_PREINSTALL=grafana-clock-panel, grafana-simple-json-datasource" \
       ghcr.io/appjail-makejails/grafana grafana
   ```

2. To specify the version of a plugin, add the version number to the `GF_PLUGINS_PREINSTALL` environment variable.

   For example:

   ```console
   $ appjail oci run -Pd \
       -o overwrite=force \
       -o virtualnet=":<random> default" \
       -o nat \
       -o expose="3000:3000" \
       -o template=template.conf \
       -e "GF_PLUGINS_PREINSTALL=grafana-clock-panel@1.0.1" \
       ghcr.io/appjail-makejails/grafana grafana
   ```

3. To install a plugin from a custom URL, use the following convention to specify the URL: `<plugin ID>@[<plugin version>]@<url to plugin zip>`.

   For example:

   ```console
   $ appjail oci run -Pd \
       -o overwrite=force \
       -o virtualnet=":<random> default" \
       -o nat \
       -o expose="3000:3000" \
       -o template=template.conf \
       -e "GF_PLUGINS_PREINSTALL=custom-plugin@@https://github.com/VolkovLabs/custom-plugin.zip" \
       ghcr.io/appjail-makejails/grafana grafana
   ```

##### Example

The following example runs the latest stable version of Grafana, listening on port 3000, with the container named `grafana`, persistent storage in the `/var/appjail-volumes/grafana/storage` directory, the server root URL set, and the official [clock panel](https://grafana.com/grafana/plugins/grafana-clock-panel) plugin installed.

```console
$ mkdir -p /var/appjail-volumes/grafana/storage
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose="3000:3000" \
    -o template=template.conf \
    -e "GF_SERVER_ROOT_URL=http://my.grafana.server/" \
    -e "GF_PLUGINS_PREINSTALL=grafana-clock-panel" \
    -o fstab="/var/appjail-volumes/grafana/storage /var/db/grafana <pseudofs>" \
    -e PUID=$(id -u) \
    -e PGID=$(id -g) \
    ghcr.io/appjail-makejails/grafana grafana
```

### Deploy using `appjail-director`

AppJail Director is a software tool that makes it easy to define and share applications that consist of multiple containers. It works by using a YAML file, usually called `appjail-director.yml`, which lists all the services that make up the application. You can start the containers in the correct order with a single command, and with another command, you can shut them down. For more information about the benefits of using AppJail Director and how to use it refer to [Use AppJail Director](https://github.com/DtxdF/director#quick-start).

#### Before you begin

To run Grafana via AppJail Director, install the Director tool on your machine. To determine if the Director tool is available, run the following command:

```console
$ appjail-director --version
```

If the Director tool is unavailable, refer to [Install AppJail Director](https://github.com/DtxdF/director#installation).

#### Run the latest stable version of Grafana

To run the latest stable version of Grafana using AppJail Director, complete the following steps:

1. Create an `appjail-director.yml` file.

   ```console
   $ # first go into the directory where you have created this appjail-director.yml file
   $ cd /path/to/appjail-director-directory
   $ # now create the appjail-director.yml file
   $ touch appjail-director.yml
   $ # Optionally set DIRECTOR_PROJECT env into a .env file to avoid specifying it by CLI
   $ echo DIRECTOR_PROJECT=grafana > .env
   ```

2. Now, add the following code into the `appjail-director.yml` file.

   For example:

   ```yaml
   options:
     - virtualnet: ':<random> default'
     - nat:

   services:
     grafana:
       name: grafana
       makejail: gh+AppJail-makejails/grafana
       options:
         - expose: '3000:3000'
         - template: !ENV '${PWD}/template.conf'
         - container: 'args:--pull'
   ```

3. To run `appjail-director.yml`, run the following command:

   ```console
   $ # start the grafana container
   $ appjail-director up
   ```

   Where:

   * `up` = to bring the container up and running

To determine that Grafana is running, open a browser window and type `http://grafana:3000` (from the same host) or `http://host-ip:3000` (from external hosts). The sign in screen should appear.

#### Stop the Grafana container

To stop the Grafana container, run the following command:

```console
$ appjail-director down
```

**Note**: For more information about using AppJail Director commands, refer to [appjail-director](https://github.com/DtxdF/director#documentation).

#### Save your Grafana data

1. Create the directory where you will be mounting your data, in this case is `$PWD/data`:

   ```
   mkdir data
   ```

2. Now, add the following code into the `appjail-director.yml` file.

   ```yaml
   options:
     - virtualnet: ':<random> default'
     - nat:

   services:
     grafana:
       name: grafana
       makejail: gh+AppJail-makejails/grafana
       options:
         - expose: '3000:3000'
         - template: !ENV '${PWD}/template.conf'
         - container: 'args:--pull'
        oci:
          environment:
            - PUID: 1000 # change this to $(id -u)
            - PGID: 1000 # change this to $(id -g)
        volumes:
          - data: /var/db/grafana

   volumes:
     data:
       device: !ENV '${PWD}/data'
   ```

3. Save the file and run the following command:

   ```console
   $ appjail-director up
   ```

### Default paths

Grafana comes with default configuration parameters that remain the same among versions regardless of the operating system or the environment (for example, virtual machine, AppJail, Docker, Kubernetes, etc.). You can refer to the [Configure Grafana](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/) documentation to view all the default configuration settings.

The following configurations are set by default when you start the Grafana AppJail container. When running in AppJail you cannot change the configurations by editing the `conf/grafana.ini` file. Instead, you can modify the configuration using [environment variables](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#override-configuration-with-environment-variables).

| Setting | Default value |
| --- | --- |
| `GF_PATHS_CONFIG` | `/usr/local/etc/grafana/grafana.ini` |
| `GF_PATHS_DATA` | `/var/db/grafana` |
| `GF_PATHS_HOME` | `/usr/local/share/grafana` |
| `GF_PATHS_LOGS` | `/var/log/grafana` |
| `GF_PATHS_PLUGINS` | `/var/db/grafana/plugins` |
| `GF_PATHS_PROVISIONING` | `/usr/local/etc/grafana/provisioning` |

### Arguments (stage: build)

* `grafana_from` (default: `ghcr.io/appjail-makejails/grafana`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `grafana_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).

### Environment (OCI image)

* `PGID` (default: `1000`): Equivalent to `PUID` but for the Process Group ID.
* `PUID` (default: `1000`): Process User ID for the container's main process, allowing you to match the owner of files written to mounted host volumes to your host system's user. Writable volumes are changed based on this environment variable.

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        NO_PKGCLEAN: "1"
      cache_dirs: ["pkgcache0:/var/cache/pkg"]
```
