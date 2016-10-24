# Using Volumerize With Dropbox

Volumerize can backup Docker volumes on Dropbox.

You have to perform the following steps:

1. Login to you Dropbox account and create an app key.

Read on how to create the app key on Dropbox: [Note on Dropbox Access](http://duplicity.nongnu.org/duplicity.1.html#toc12)

The Dropbox App Creation Page: [Dropbox App Creation](https://www.dropbox.com/developers/apps/create)

1. On the app page you need to generate the `Generated access token` for the environment variable `DPBX_ACCESS_TOKEN`.

1. First we start our example container with some data to backup:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     blacklabelops/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

1. Start the container in demon mode and pass the access token through the environment variable `DPBX_ACCESS_TOKEN`.

Setup Volumerize to use Dropbox for backups of the volume `jenkins_volume`. Make sure you have already created the backup folder inside Dropbox, e.g. here `/Apps/Volumerize`.

Start the container in demon mode:

~~~~
$ docker run -d \
    --name volumerize \
    -v volumerize_cache:/volumerize-cache \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=dpbx:///Apps/Volumerize" \
    -e "DPBX_ACCESS_TOKEN=JUtoLXXwNNMAAAAAAA" \
    blacklabelops/volumerize
~~~~

> `volumerize_cache` is the local data cache.

1. You can start an initial backup:

~~~~
$ docker exec volumerize backup
~~~~

# Restore from Dropbox

Restore is easy, just pass the same environment variables and start the restore script:

> Note: Remove the read-only option `:ro` on the source volume.

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=dpbx:///Apps/Volumerize" \
    -e "DPBX_ACCESS_TOKEN=JUtoLXXwNNMAAAAAAA" \
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

Verify against the dropbox content:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=dpbx:///Apps/Volumerize" \
    -e "DPBX_ACCESS_TOKEN=JUtoLXXwNNMAAAAAAA" \
    blacklabelops/volumerize verify
~~~~

> Will perform a single verification of the volume contents against the dropbox archive.

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
    -v volumerize_cache:/volumerize-cache \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=dpbx:///Apps/Volumerize" \
    -e "DPBX_ACCESS_TOKEN=JUtoLXXwNNMAAAAAAA" \
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
