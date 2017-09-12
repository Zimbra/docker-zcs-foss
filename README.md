## Introduction

This provides a simple two-container cluster:

- `zimbra` - A non-persisting Zimbra installation.  When you stop the cluster, everything is lost. This is intended for testing purposes only. Current running version 8.8.3.
- `bind` - A simple bind DNS server, preconfigured with MX and A records.

## Preconditions

The following assumes you have `docker` and `docker-compose` installed.  See [this page](https://github.com/Zimbra/docker-zcs-dev-machine) for help with that.


## Setup

Clone a copy of this repo. Then, from inside your local clone of the repo:

Copy the file `DOT-env` to `.env`.  Update `.env` as desired.

## Start the Cluster

Run the command `docker-compose up -d && docker logs -f zimbra`. When you see `SETUP COMPLETE`, you can `C-c` out of the `docker logs...` command.

To log into the `zimbra` container just do `docker exec -it zimbra bash`.

## Stop the Cluster

Run the command `docker-compose down` (from inside the local copy of this repo that you cloned).
