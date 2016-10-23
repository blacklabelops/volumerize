# Blacklabelops Volumerize

Blacklabelops backup and restore solution for Docker volume backups. It is based on the command line tool Duplicity. Dockerized and Parameterized for easier use and configuration.

Always remember that this no wizard tool that can clone and backup data from running databases. You should always stop all containers running on your data before doing backups. Always make sure your not victim of unexpected data corruption.

Also note that the easier the tools are the easier it is to lose data! Always make sure the tool works correct by checking the backup data itself, e.g. S3 bucket. Check the configuration double time and enable some check options this image offers. E.g. attaching volumes read only.

Supported backends:

* Filesystem
* Amazon S3
* DropBox
* Google Drive
* ssh/scp
* rsync

and many more: [Duplicity Supported Backends](http://duplicity.nongnu.org/index.html)

> Note: Some backends require binaries which may not be available inside this image. Please open a ticket when you require something.

# Make It Short

You can make backups of your Docker application volume just by typing:

~~~~
$ docker run -it --rm \
    --name volumerize \
    -v yourvolume:/source:ro \
    -v backup_volume:/backup \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize backup
~~~~

> Hooks up your volume with the name `yourvolume` and backups to the volume `backup_volume`

# How It Works

The container has a default startup mode. Any specific behavior is done by defining envrionment variables at container startup (`docker run`). The default container behavior is to start in demon mode and do incremental daily backups.

You application data must be saved inside a Docker volume. You can list your volumes with the Docker command `docker volume ls`. You have to attach the volume to the backup container using the `-v` option. Choose an arbitrary name for the folder and add the `:ro`option to make the sources read only.

Example using Jenkins:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     blacklabelops/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Now attach the Jenkins data to folders inside the container and tell blacklabelops/volumerize to backup folder `/source` to folder `/target`.

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize
~~~~

> Will start the Volumerizer. The volume jenkins_volume is now folder `/source` and backups_volume is now folder `/backup` inside the container.

You can execute commands inside the container, e.g. doing an immediate backup or even restore:

~~~~
$ docker exec volumerize backup
~~~~

> Will trigger an incremental backup.

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
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize
~~~~

> Will run Volumerize on the common parent folder `/source`.

# Backup Restore

A restore is simple. First stop your Volumerize container and start a another container with the same
environment variables and the same volume but without read only mode! This is important in order to get the same directory structure as when you did your backup!

Tip: Now add the read only option to your backup container!

Example:

You did your backups with the following settings:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize
~~~~

Then stop the backup container and restore with the following command. The only difference is that we exclude the read only option `:ro` from the source volume and added it to the backup volume:

~~~~
$ docker stop volumerize
$ docker run --rm \
    -v jenkins_volume:/source \
    -v backup_volume:/backup:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    blacklabelops/volumerize restore
$ docker start volumerize
~~~~

> Triggers a once time restore. The container for executing the restore command will be deleted afterwards

# Periodic Backups

The default cron setting for this container is: `0 0 4 * * *`. That's four a clock in the morning UTC. You can set your own schedule with the environment variable `VOLUMERIZE_JOBBER_TIME`.

You can set the time zone with the environment variable `TZ`.

The syntax is different from cron because I use Jobber as a cron tool: [Jobber Time Strings](http://dshearer.github.io/jobber/doc/v1.1/#/time-strings)

Example:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v backup_volume:/backup \
    -e "TZ=Europe/Berlin"
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=file:///backup" \
    -e "VOLUMERIZE_JOBBER_TIME=0 0 3 * * *" \
    blacklabelops/volumerize
~~~~

> Backups three o'clock in the morning according to german local time.

# Container Scripts

This image creates at container startup some convenience scripts.

| Script | Description |
|--------|-------------|
| backup | Creates an incremental backup with the containers configuration |
| backupFull | Creates a full backup the the containers configuration |
| verify | Compare the latest backup to your local files |
| restore | Be Careful! Triggers an immediate force restore with the latest backup |
| periodicBackup | Same script that will be triggered by the periodic schedule |

Example triggering script inside running container:

~~~~
$ docker exec volumerize backup
~~~~

> Executes script `backup` inside container with name `volumerize`

# Build The Project

## Build the Image

~~~~
$ docker build -t blacklabelops/volumerize .
~~~~

## Run the Image

~~~~
$ docker run -it --rm blacklabelops/volumerize bash
~~~~
