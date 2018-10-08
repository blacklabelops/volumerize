# Using Volumerize With Backblaze B2

Volumerize can backup Docker volumes on Backblaze B2.

You have to perform the following steps:

Login to Backblaze B2 and create an application key.

The Backblaze B2 Buckets (select `Show Account ID and Application Key`): [B2 Cloud Storage Buckets](https://secure.backblaze.com/b2_buckets.htm)

Remember the following details:

* The application key ID.
* The application key.
* The bucket name.

First we start our example container with some data to backup:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     blacklabelops/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Now build your B2 url according to the template:

`b2://account_id[:application_key]@bucket_name/[folder/]`.

Start the container in demon mode with your url:

~~~~
$ docker run -d \
    --name volumerize \
    -v volumerize_cache:/volumerize-cache \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=b2://003945h951emn6p0000000001:H006yG2V7+pogtolEFwCexcZUWJdkNc@volumerizetest/" \
    blacklabelops/volumerize
~~~~

> Will backup to application id 003945h951emn6p0000000001 using application key H006yG2V7+pogtolEFwCexcZUWJdkNc inside bucket volumerizetest.

Start the first backup:

~~~~
$ docker exec volumerize backup
~~~~

# Restore from Backblaze B2

Restore is easy, just pass the same environment variables and start the restore script:

> Note: Remove the read-only option `:ro` on the source volume.

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v volumerize_cache:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=b2://003945h951emn6p0000000001:H006yG2V7+pogtolEFwCexcZUWJdkNc@volumerizetest/" \
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

Verify against the Backblaze B2 content:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v volumerize_cache:/volumerize-cache \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=b2://003945h951emn6p0000000001:H006yG2V7+pogtolEFwCexcZUWJdkNc@volumerizetest/" \
    blacklabelops/volumerize verify
~~~~

> Will perform a single verification of the volume contents against the Backblaze B2 archive.

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
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=b2://003945h951emn6p0000000001:H006yG2V7+pogtolEFwCexcZUWJdkNc@volumerizetest/" \
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
