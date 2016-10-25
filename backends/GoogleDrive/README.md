# Using Volumerize With Google Drive

Volumerize can backup Docker volumes on Google Drive.

You have to perform the following steps:

Login to Google developers console and create a service account.

Read on how to create the app key on Google directive: [Note on PyDrive](http://duplicity.nongnu.org/duplicity.1.html#sect22)

The Google developers console: [Google Developers Console](https://console.developers.google.com./)

On the app page you need to generate the `OAuth client ID` and retrieve the `Client ID` and `Client Secret`.

First we start our example container with some data to backup:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     blacklabelops/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Start the container in `Authorization Mode` follow the authorization instructions and store your credentials inside a Docker volume!

~~~~
$ docker run -it --rm \
    -v volumerize_cache:/volumerize-cache \
    -v volumerize_credentials:/credentials \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdocs:///youremail@gmail.com/backup" \
    -e "GOOGLE_DRIVE_ID=12312786-e99grj1k5lwjepofjwpoejfpe5nqvkd3e.apps.googleusercontent.com" \
    -e "GOOGLE_DRIVE_SECRET=FWeofWefkefnkef" \
    blacklabelops/volumerize backup
~~~~

> Note: The routine will fail, you still have to enable the Google Drive API for your project. See the URL inside the log output.

Setup Volumerize to use Google Drive for backups of the volume `jenkins_volume`.

Start the container in demon mode:

~~~~
$ docker run -d \
    --name volumerize \
    -v volumerize_cache:/volumerize-cache \
    -v volumerize_credentials:/credentials \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdocs://youremail@gmail.com/backup" \
    blacklabelops/volumerize
~~~~

> `volumerize_cache` is the local data cache.

You can start an initial full backup:

~~~~
$ docker exec volumerize backupFull
~~~~

# Restore from Google Drive

Restore is easy, just pass the same environment variables and start the restore script:

> Note: Remove the read-only option `:ro` on the source volume.

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v volumerize_credentials:/credentials \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdocs://youremail@gmail.com/backup" \
    blacklabelops/volumerize restore
~~~~

> Will perform a test restore inside a separate volume `jenkins_test_restore`

Check the contents of the volume:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    blacklabelops/alpine ls -R /source
~~~~

> Lists files inside the source volume

Verify against the Google Drive content:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v volumerize_credentials:/credentials \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdocs://youremail@gmail.com/backup" \
    blacklabelops/volumerize verify
~~~~

> Will perform a single verification of the volume contents against the Google Drive archive.

# Start and Stop Docker Containers

Volumerize can stop containers before backup and start them after backup.

First start a test container with the name `jenkins`

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     blacklabelops/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Now add the containers name inside the environment variable `VOLUMERIZE_CONTAINERS` and start Volumerize in demon mode:

~~~~
$ docker run -d \
    --name volumerize \
    -v jenkins_volume:/source:ro \
    -v volumerize_cache:/volumerize-cache \
    -v volumerize_credentials:/credentials \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=gdocs://youremail@gmail.com/backup" \
    -e "VOLUMERIZE_CONTAINERS=jenkins" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    blacklabelops/volumerize
~~~~

> Needs access to the docker host over the directive `-v /var/run/docker.sock:/var/run/docker.sock`

You can test the backup routine:

~~~~
$ docker exec volumerize backup
~~~~

> Triggers the backup inside the volume, the name `jenkins` should appear on the console.

> Note: Make sure your container is not running with docker auto restart!
