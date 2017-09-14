## Introduction

This provides a simple two-container cluster:

- `zimbra` - A basic Zimbra installation. This is intended primarily for testing.  Currently running version 8.8.3.
- `bind` - A simple bind DNS server, preconfigured with MX and A records.

## Preconditions

The following assumes you have `docker` and `docker-compose` installed.  See [this page](https://github.com/Zimbra/docker-zcs-dev-machine) for help with that.


## Setup

Clone a copy of this repo. Then, from inside your local clone of the repo:

Copy the file `DOT-env` to `.env`.  Update `.env` as desired.

## Start the Cluster

Run the command `docker-compose up -d && docker logs -f zimbra`. When you see `SETUP COMPLETE`, you can `C-c` out of the `docker logs...` command. The _first_ time you do this, it will take longer to complete startup as it is having to run `zmsetup.pl` and apply your configuration.  Future startups are faster.  See the _Data Persistence_ section below for details.

To log into the `zimbra` container just do `docker exec -it zimbra bash`.

## Stop the Cluster

Run the command `docker-compose down` (from inside the local copy of this repo that you cloned).

## Installed Zimbra Packages

These are the packages that are selected for installation:

- `zimbra-ldap`
- `zimbra-mta`
- `zimbra-store`
- `zimbra-apache`
- `zimbra-spell`
- `zimbra-memcached`
- `zimbra-proxy`
- `zimbra-imapd`

## Data Persistence

**NOTE: This is experimental.**

The `docker-compose.yml` defines a Docker volume that gets mounted to `/opt/zimbra`.  It gets created the first time you bring up the containers.  You can see the volume that gets created, as in the following example:

    $ docker volume ls
    DRIVER              VOLUME NAME
    local               dockerzcsfoss_opt_zimbra

Normally, when you stop the cluster, you would lose your current Zimbra data. But with this volume, when you restart the cluster, it will remount that volume and you just keep going where you left off last.

This feature is marked as experimental, because during a normal install configuration, some information outside of `/opt/zimbra` is added or changed and it is possible that, at the current time, not all of that is being restored correctly.  Take a look at the `init` script in the `slash-zimbra` directory to see what is currently being handled.  Let me know if I missed anything.

If you _want_ to reset the data, just stop the cluster and remove the volume like this:

	docker volume rm dockerzcsfoss_opt_zimbra

The next time you start the cluster it will recreate that volume run through the `zmsetup.pl` process again.

## Disabling Data Persistence

If you do _not_ need the _Data Persistence_ feture, just edit the `docker-compose.yml` file and remove the following:


    volumes:
      - type: volume
        source: opt_zimbra
        target: /opt/zimbra
        volume:
          nocopy: false


    volumes:
        opt_zimbra:

