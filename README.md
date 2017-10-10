## Introduction

This branch deploys a 2-node Zimbra installation. Currently running version 8.8.3. It is configured to deploy into a Docker swarm.  You can easily configure a local Docker engine to run a single-node swarm, so this is not difficult to handle.  These are the services that get deployed with the stack

- `zimbra`. This service runs the following:
    - `zimbra-ldap`
    - `zimbra-mta`
    - `zimbra-snmp`
    - `zimbra-memcached`
    - `zimbra-proxy`
    - `zimbra-imapd`
    - `STAF`
- `mailbox`
    - `zimbra-store`
    - `zimbra-apache`
    - `zimbra-snmp`
    - `zimbra-spell`


## Preconditions




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
- `zimbra-logger`
- `zimbra-mta`
- `zimbra-store`
- `zimbra-apache`
- `zimbra-spell`
- `zimbra-memcached`
- `zimbra-proxy`
- `zimbra-imapd`


## Running in a local docker swarm

These instructions assume that you have _Virtualbox_ installed. _NOTE:_ They will work just fine whether you are using _Docker for Mac_ or some other Docker installation.

## Create local VMs to run the swarm on

    $ docker-machine create --driver virtualbox vm1
    $ docker-machine create --driver virtualbox vm2
    $ docker-machine create --driver virtualbox vm3

_NOTE:_ The above `docker-machine create` command will create machines with default settings.  These may be a bit underpowered.  The following command shows some options you can use:

	$ docker-machine create --virtualbox-disk-size 32000 \
	  --virtualbox-memory 6144 \
	  --virtualbox-cpu-count 4 \
	  --driver virtualbox <machine-name>

See [this page](https://docs.docker.com/machine/drivers/virtualbox/#usage) for an explanation of the options.


## Initialize the swarm

    $ docker-machine ls
    NAME   ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
    vm1    -        virtualbox   Running   tcp://192.168.99.100:2376           v17.09.0-ce
    vm2    -        virtualbox   Running   tcp://192.168.99.101:2376           v17.09.0-ce
    vm3    -        virtualbox   Running   tcp://192.168.99.102:2376           v17.09.0-ce

### Manager runs on vm1

    $ docker-machine ssh vm1 "docker swarm init --advertise-addr 192.168.99.100"
    Swarm initialized: current node (f59l3muq14vmkjg4m1yy7sycy) is now a manager.

    To add a worker to this swarm, run the following command:

        docker swarm join --token SWMTKN-1-3rgvuj0tkieslsrahy02tl1yp8yaq30w6d62knak9p8d4t4rdc-3kijt9tomeu41xq762j10mq96 192.168.99.100:2377

    To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.


### vm2 & vm3 are workers

    $ docker-machine ssh vm2 "docker swarm join --token SWMTKN-1-3rgvuj0tkieslsrahy02tl1yp8yaq30w6d62knak9p8d4t4rdc-3kijt9tomeu41xq762j10mq96 192.168.99.100:2377"

    This node joined a swarm as a worker.

    $ docker-machine ssh vm3 "docker swarm join --token SWMTKN-1-3rgvuj0tkieslsrahy02tl1yp8yaq30w6d62knak9p8d4t4rdc-3kijt9tomeu41xq762j10mq96 192.168.99.100:2377"

    This node joined a swarm as a worker.

## Configure the shell to "talk" to the manager node

    $ eval $(docker-machine env vm1)

Results:

    $ env | grep DOCKER
    DOCKER_HOST=tcp://192.168.99.100:2376
    DOCKER_MACHINE_NAME=vm1
    DOCKER_TLS_VERIFY=1
    DOCKER_CERT_PATH=/Users/gordy/.docker/machine/machines/vm1

    $ docker-machine ls
    NAME   ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
    vm1    *        virtualbox   Running   tcp://192.168.99.100:2376           v17.09.0-ce
    vm2    -        virtualbox   Running   tcp://192.168.99.101:2376           v17.09.0-ce
    vm3    -        virtualbox   Running   tcp://192.168.99.102:2376           v17.09.0-ce


## Deploy the stack

    $ docker stack deploy -c docker-compose.swarm.yml zcs
    Creating network zcs_default
    Creating service zcs_zimbra

## Observe the zcs_zimbra service logs

    $ docker service logs -f zcs_zimbra

## Connect to the zcs_zimbra service

    Determine where it is running

    $ docker service ps zcs_zimbra
    ID                  NAME                IMAGE                     NODE                DESIRED STATE       CURRENT STATE             ERROR               PORTS
    qcj4t3yo8j3a        zcs_zimbra.1        zimbra/zcs-foss:latest    vm2                 Running             Preparing 2 minutes ago


## Connect to the machine that is running zcs_zimbra

$ docker-machine ssh vm2

## Find the container running the zcs_zimbra service

    $ docker ps --filter "name=zcs_zimbra"
    CONTAINER ID        IMAGE                     COMMAND             CREATED             STATUS              PORTS                                                                                                       NAMES
    a1d8fb65a91f        zimbra/zcs-foss:latest    "/zimbra/init"      31 minutes ago      Up 31 minutes       22/tcp, 25/tcp, 80/tcp, 110/tcp, 143/tcp, 443/tcp, 465/tcp, 587/tcp, 993/tcp, 995/tcp, 7071/tcp, 8443/tcp   zcs_zimbra.1.qcj4t3yo8j3aju92efwz7hmfg

Or, more compactly (because you just need the container ID):

    $ docker ps -q --filter "name=zcs_zimbra"
    a1d8fb65a91f

Then you can connet to the container like normal.

	$ docker exec -it a1d8fb65a91f bash


## Cleaning Up

### Remove the stack

    $ docker stack rm zcs

    Removing service zcs_zimbra
    Removing network zcs_default

### Tear Down the Swarm

Tell each machine to leave the swarm. Note that you have to _force_ the manager to leave.

    $ docker-machine ssh vm3 "docker swarm leave"
    Node left the swarm.

    $ docker-machine ssh vm2 "docker swarm leave"
    Node left the swarm.

    $ docker-machine ssh vm1 "docker swarm leave --force"
    Node left the swarm.

Stop the machines.

    $ for m in {1..3}; do docker-machine stop vm${m}; done
    Stopping "vm1"...
    Machine "vm1" was stopped.
    Stopping "vm2"...
    Machine "vm2" was stopped.
    Stopping "vm3"...
    Machine "vm3" was stopped.

Remove the machines.

    $ for m in {1..3}; do docker-machine rm -y vm${m}; done
    About to remove vm1
    WARNING: This action will delete both local reference and remote instance.
    Successfully removed vm1
    About to remove vm2
    WARNING: This action will delete both local reference and remote instance.
    Successfully removed vm2
    About to remove vm3
    WARNING: This action will delete both local reference and remote instance.
    Successfully removed vm3
