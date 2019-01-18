# Blacklabelops Volumerize

[![Circle CI](https://circleci.com/gh/blacklabelops/volumerize.svg?style=shield)](https://circleci.com/gh/blacklabelops/volumerize)
[![Open Issues](https://img.shields.io/github/issues/blacklabelops/volumerize.svg)](https://github.com/blacklabelops/volumerize/issues) [![Stars on GitHub](https://img.shields.io/github/stars/blacklabelops/volumerize.svg)](https://github.com/blacklabelops/volumerize/stargazers)
[![Docker Stars](https://img.shields.io/docker/stars/blacklabelops/volumerize.svg)](https://hub.docker.com/r/blacklabelops/volumerize/) [![Docker Pulls](https://img.shields.io/docker/pulls/blacklabelops/volumerize.svg)](https://hub.docker.com/r/blacklabelops/volumerize/)

[![Try in PWD](https://raw.githubusercontent.com/play-with-docker/stacks/master/assets/images/button.png)](https://labs.play-with-docker.com/?stack=https://raw.githubusercontent.com/blacklabelops/volumerize/master/dc-pwd.yml)

Blacklabelops backup and restore solution for Docker volume backups. It is based on the command line tool Duplicity. Dockerized and Parameterized for easier use and configuration.

This is not a tool that can clone and backup data from running databases. You should always stop all containers running on your data before doing backups. Always make sure you're not a victim of unexpected data corruption.

Also note that the easier the tools the easier it is to lose data! Always make sure the tool works correct by checking the backup data itself, e.g. S3 bucket. Check the configuration double time and enable some check options this image offers. E.g. attaching volumes read only.

Features:

* Multiple Backends
* Cron Schedule
* Start and Stop Containers

Supported backends:

* Filesystem
* Amazon S3
* DropBox
* Google Drive
* ssh/scp
* rsync

and many more: [Duplicity Supported Backends](http://duplicity.nongnu.org/index.html)

# Volume Backups Tutorials

Docker Volume Backups on:

Backblaze B2: [Readme](https://github.com/blacklabelops/volumerize/tree/master/backends/BackblazeB2)

Amazon S3: [Readme](https://github.com/blacklabelops/volumerize/tree/master/backends/AmazonS3)

Dropbox: [Readme](https://github.com/blacklabelops/volumerize/tree/master/backends/Dropbox)

Google Drive: [Readme](https://github.com/blacklabelops/volumerize/tree/master/backends/GoogleDrive)

# Make It Short

You can make backups of your Docker application volume just by typing:

~~~~
$ docker run --rm \
    --name volumerize \
    -v yourvolume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize backup
~~~~

> Hooks up your volume with the name `yourvolume` and backups to the volume `backup_volume`

# How It Works

The container has a default startup mode. Any specific behavior is done by defining envrionment variables at container startup (`docker run`). The default container behavior is to start in daemon mode and do incremental daily backups.

Your application data must be saved inside a Docker volume. You can list your volumes with the Docker command `docker volume ls`. You have to attach the volume to the backup container using the `-v` option. Choose an arbitrary name for the folder and add the `:ro`option to make the sources read only.

Example using Jenkins:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     blacklabelops/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Now attach the Jenkins data to folders inside the container and tell blacklabelops/volumerize to backup folder `/source` to folder `/backup`.

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize
~~~~

> Will start the Volumerizer. The volume jenkins_volume is now folder `/source` and backups_volume is now folder `/backup` inside the container.

You can execute commands inside the container, e.g. doing an immediate backup or even restore:

~~~~
$ docker exec volumerize backup
~~~~

> Will trigger a backup.

# Backup Multiple volumes

The container can backup one source folder, see environment variable `VOLUMERIZE_TARGET`. If you want to backup multiple volumes you will have to hook up multiple volumes under the same source folder.

Example:

* Volume: application_data
* Volume: application_database_data
* Volume: application_configuration

Now start the container hook them up under the same folder `source`.

~~~~
$ docker run -d \
    --name volumerize \
    -v application_data:/source/application_data:ro \
    -v application_database_data:/source/application_database_data:ro \
    -v application_configuration:/source/application_configuration:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize
~~~~

> Will run Volumerize on the common parent folder `/source`.

# Backup Restore

A restore is simple. First stop your Volumerize container and start a another container with the same
environment variables and the same volume but without read-only mode! This is important in order to get the same directory structure as when you did your backup!

Tip: Now add the read-only option to your backup container!

Example:

You did your backups with the following settings:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize
~~~~

Then stop the backup container and restore with the following command. The only difference is that we exclude the read-only option `:ro` from the source volume and added it to the backup volume:

~~~~
$ docker stop volumerize
$ docker run --rm \
    -v jenkins_volume:/source \
    -v backup_volume:/backup:ro \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize restore
$ docker start volumerize
~~~~

> Triggers a once time restore. The container for executing the restore command will be deleted afterwards

You can restore from a particular backup by adding a time parameter to the command `restore`. For example, using `restore -t 3D` at the end in the above command will restore a backup from 3 days ago. See [the Duplicity manual](http://duplicity.nongnu.org/duplicity.1.html#sect8) to view the accepted time formats.

To see the available backups, use the command `list` before doing a `restore`.

## Dry run

You can pass the `--dry-run` parameter to the restore command in order to test the restore functionality:

~~~~
$ docker run --rm \
    -v jenkins_volume:/source \
    -v backup_volume:/backup:ro \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize restore --dry-run
~~~~

But in order to see the differences between backup and source you need the verify command:

~~~~
$ docker run --rm \
    -v jenkins_volume:/source \
    -v backup_volume:/backup:ro \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize verify
~~~~

# Periodic Backups

The default cron setting for this container is: `0 0 4 * * *`. That's four o'clock in the morning UTC. You can set your own schedule with the environment variable `VOLUMERIZE_JOBBER_TIME`.

You can set the time zone with the environment variable `TZ`.

The syntax is different from cron because I use Jobber as a cron tool: [Jobber Time Strings](http://dshearer.github.io/jobber/doc/v1.1/#/time-strings)

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "TZ=Europe/Berlin" \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_JOBBER_TIME=0 0 3 * * *" \
    blacklabelops/volumerize
~~~~

> Backups at three o'clock in the morning according to german local time.

# Docker Container Restarts

This image can stop and start Docker containers before and after backup. Docker containers are specified using the environment variable `VOLUMERIZE_CONTAINERS`. Just enter their names in a empty space separated list.

Example:

* Docker container application with name `application`
* Docker container application database with name `application_database`

Note: Needs the parameter `-v /var/run/docker.sock:/var/run/docker.sock` in order to be able to start and stop containers on the host.

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_CONTAINERS=application application_database" \
    blacklabelops/volumerize
~~~~

> The startup routine will be applied to the following scripts: backup, backupFull, restore and periodBackup.

Test the routine!

~~~~
$ docker exec volumerize backup
~~~~

### Additional Docker CLI API configurations
> If the docker host version is earlier than 1.12 then include the following docker api setting, Volumerize uses docker CLI ver 1.12 which uses Docker API version 1.24. One needs to set the compatible API version of the docker host 
ie. Docker host version 1.11 uses API 1.23

~~~~
docker version
Client:
 Version:      1.11.2
 API version:  1.23
 Go version:   go1.8
 Git commit:   5be46ee-synology
 Built:        Fri May 12 16:36:47 2017
 OS/Arch:      linux/amd64

Server:
 Version:      1.11.2
 API version:  1.23
 Go version:   go1.8
 Git commit:   5be46ee-synology
 Built:        Fri May 12 16:36:47 2017
 OS/Arch:      linux/amd64
~~~~
Then use  the following -e argument
~~~~
$ docker run -d \
    --name volumerize \
    -v /var/run/docker.sock:/var/run/docker.sock \
    ...
    ...
    -e "DOCKER_API_VERSION=1.23" \
    ...
    ...
    blacklabelops/volumerize
~~~~
### Additional Docker considerations
Warning: Make sure your container is running under the correct restart policy. Tools like Docker, Docker-Compose, Docker-Swarm, Kubernetes and Cattle may restart the container even when Volumerize stops it. Backups done under running instances may end in corrupted backups and even corrupted data. Always make sure that the command `docker stop` really stops an instance and there will be no restart of the underlying deployment technology. You can test this by running `docker stop` and check with `docker ps` that the container is really stopped.

# Duplicity Parameters

Under the hood blacklabelops/volumerize uses duplicity. See here for duplicity command line options: [Duplicity CLI Options](http://duplicity.nongnu.org/duplicity.1.html#sect5)

You can pass duplicity options inside Volumerize. Duplicity options will be passed by the environment-variable `VOLUMERIZE_DUPLICITY_OPTIONS`. The options will be added to all blacklabelops/volumerize commands and scripts. E.g. the option `--dry-run` will put the whole container in demo mode as all duplicity commands will only be simulated.

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_DUPLICITY_OPTIONS=--dry-run" \
    blacklabelops/volumerize
~~~~

> Will only operate in dry-run simulation mode.

# Symmetric Backup Encryption

You can encrypt your backups by setting a secure passphrase inside the environment variable `PASSPHRASE`.

Creating a secure passphrase:

~~~~
$ docker run --rm blacklabelops/volumerize openssl rand 128 -base64
~~~~

> Prints an appropriate password on the console.

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "PASSPHRASE=Jzwv1V83LHwtsbulVS7mMyijStBAs7Qr/V2MjuYtKg4KQVadRM" \
    blacklabelops/volumerize
~~~~

> Same functionality as described above but all backups will be encrypted.

# Asymmetric Key-Based Backup Encryption

You can encrypt your backups with secure secret keys.

You need:

* A key, specified by the environment-variable `VOLUMERIZE_GPG_PRIVATE_KEY`
* A key passphrase, specified by the environment-variable `PASSPHRASE`

Creating a key? Install gpg on your comp and type:

~~~~
$ gpg2 --full-gen-key
Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048)
Requested keysize is 2048 bits   
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)
Key does not expire at all
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: YourName
Email address: yourname@youremail.com
Comment:                            
You selected this USER-ID:
    "YourName <yourname@youremail.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
$ gpg2 --export-secret-keys --armor yourname@youremail.com > MyKey.asc
~~~~

> Note: Currently, this image only supports keys without passwords. The import routine is at fault, it would always prompt for passwords.

You need to get the key id:
```shell
$ gpg -k yourname@youremail.com | head -n 2 | tail -n 1 | awk '{print $1}'
```

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -v $(pwd)/MyKey.asc:/key/MyKey.asc \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_GPG_PRIVATE_KEY=/key/MyKey.asc" \
    -e GPG_KEY_ID=<MyKeyID>
    -e "PASSPHRASE=" \
    blacklabelops/volumerize
~~~~

> This will import a key without a password set.

Test the routine!

~~~~
$ docker exec volumerize backup
~~~~

# Enforcing Full Backups Periodically

The default behavior is that the initial backup is a full backup. Afterwards, Volumerize will perform incremental backups. You can enforce another full backup periodically by specifying the environment variable `VOLUMERIZE_FULL_IF_OLDER_THAN`.

The format is a number followed by one of the characters s, m, h, D, W, M, or Y. (indicating seconds, minutes, hours, days, weeks, months, or years)

Examples:

* After three Days: 3D
* After one month: 1M
* After 55 minutes: 55m

Volumerize Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -v cache_volume:/volumerize-cache \
    -e "TZ=Europe/Berlin" \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_FULL_IF_OLDER_THAN=7D" \
    blacklabelops/volumerize
~~~~

> Will enforce a full backup after seven days.

For the difference between a full and incremental backup, see [Duplicity's documentation](http://duplicity.nongnu.org/duplicity.1.html).

# Post scripts and pre scripts (prepost strategies)


Pre-scripts must be located at `/preexecute/$duplicity_action/$your_scripts_here`.

Post-scripts must be located at `/postexecute/$duplicity_action/$your_scripts_here`.

`$duplicity_action` folder must be named `backup`, `restore` or `verify`.

> Note: `backup` action is the same for the scripts `backup`, `backupFull`, `backupIncremental` and `periodicBackup`.

All `.sh` files located in the `$duplicity_action` folder will be executed in alphabetical order.

When using prepost strategies, this will be the execution flow: `pre-scripts -> stop containers -> duplicity action -> start containers -> post-scripts`.

Some premade strategies are available at [prepost strategies](prepost_strategies).

# Container Scripts

This image creates at container startup some convenience scripts.
Under the hood blacklabelops/volumerize uses duplicity. To pass script parameters, see here for duplicity command line options: [Duplicity CLI Options](http://duplicity.nongnu.org/duplicity.1.html#sect5)

| Script | Description |
|--------|-------------|
| backup | Creates an backup with the containers configuration |
| backupFull | Creates a full backup with the containers configuration |
| backupIncremental | Creates an incremental backup with the containers configuration |
| list | List all available backups |
| verify | Compare the latest backup to your local files |
| restore | Be Careful! Triggers an immediate force restore with the latest backup |
| periodicBackup | Same script that will be triggered by the periodic schedule |
| startContainers | Starts the specified Docker containers |
| stopContainers | Stops the specified Docker containers |
| remove-older-than | Delete older backups ([Time formats](http://duplicity.nongnu.org/duplicity.1.html#toc8))|
| cleanCacheLocks | Cleanup of old Cache locks. |
| prepoststrategy `$execution_phase` `$duplicity_action` | Execute all `.sh` files for the specified exeuction phase and duplicity action in alphabetical order. |

`$execution_phase` must be `preAction` or `postAction`.

`$duplicity_action` must be `backup`, `verify` or `restpore`.

Example triggering script inside running container:

~~~~
$ docker exec volumerize backup
~~~~

> Executes script `backup` inside container with name `volumerize`

Example passing script parameter:

~~~~
$ docker exec volumerize backup --dry-run
~~~~

> `--dry-run` will simulate not execute the backup procedure.


# Build The Project

Check out the project at Github.

# Multiple Backups

You can specify multiple backup jobs with one container with enumerated environment variables. Each environment variable must be followed by a number starting with 1. Example `VOLUMERIZE_SOURCE1`, `VOLUMERIZE_SOURCE2` or `VOLUMERIZE_SOURCE3`.

The following environment variables can be enumerated:

* VOLUMERIZE_SOURCE
* VOLUMERIZE_TARGET
* VOLUMERIZE_CACHE
* VOLUMERIZE_INCLUDE

When using multiple backup jobs you will have to specify a cache directory for each backup. The minimum required environment variables for each job is:

* VOLUMERIZE_SOURCE
* VOLUMERIZE_TARGET
* VOLUMERIZE_CACHE

Also the included helper scripts will change their behavior when you use enumerated environment variables. By default each script will run on all backup jobs.

Example: Executing the script `backup` will backup all jobs.

The first parameter of each script can be a job number, e.g. `1`, `2` or `3`.

Example: Executing the script `backup 1` will only trigger backup on job 1.

Full example for multiple job specifications:

~~~~
$ docker run -d \
    --name volumerize \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v jenkins_volume:/source:ro \
    -v jenkins_volume2:/source2:ro \
    -v backup_volume:/backup \
    -v backup_volume2:/backup2 \
    -v cache_volume:/volumerize-cache \
    -v cache_volume2:/volumerize-cache2 \
    -e "VOLUMERIZE_CONTAINERS=jenkins jenkins2" \
    -e "VOLUMERIZE_SOURCE1=/source" \
    -e "VOLUMERIZE_TARGET1=file:///backup" \
    -e "VOLUMERIZE_CACHE1=/volumerize-cache" \
    -e "VOLUMERIZE_SOURCE2=/source2" \
    -e "VOLUMERIZE_TARGET2=file:///backup2" \
    -e "VOLUMERIZE_CACHE2=/volumerize-cache2" \
    blacklabelops/volumerize
~~~~

## Build the Image

~~~~
$ docker build -t blacklabelops/volumerize .
~~~~

## Run the Image

~~~~
$ docker run -it --rm blacklabelops/volumerize bash
~~~~
