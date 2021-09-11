# Using Volumerize With Mega.nz

Volumerize can backup Docker volumes on Mega.nz.

You have to perform the following steps:

Pass your Mega.nz credentials to Volumerize and use the appropriate Mega.nz URL scheme.

First we start our example container with some data to backup:

~~~~
$ docker run \
     -d -p 80:8080 \
     --name jenkins \
     -v jenkins_volume:/jenkins \
     blacklabelops/jenkins
~~~~

> Starts Jenkins and stores its data inside the Docker volume `jenkins_volume`.

Start the container with the appriopriate scheme in `VOLUMERIZE_TARGET` and your credentials.

The scheme can be `mega://`, `megav2://` or `megav3://` depending on your account's creation date. According to [duplicity's documentation](http://duplicity.nongnu.org/vers8/duplicity.1.html#sect7) account created prior to November 2018 must use `mega://`.

Pass your credentials in the `VOLUMERIZE_TARGET` with the syntax `mega://user:password@mega.nz/some_dir`. Adapt it to your scheme.  
You can also pass your credentials through a configuration file with the syntax:
~~~~ini
[Login]
Username = user
Password = password
~~~~
The configuration file must be in `/root/` and it's name must reflect the scheme. `.megarc` for v1, `.megav2rc` for v2 and `.megav3rc` for v3.

Assuming our local configuration file is named _megarc_ and our account's scheme is v3.
~~~~
$ docker run -it --rm \
    -v megarc:/root/.megav3rc \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=megav3://mega.nz/backup" \
    blacklabelops/volumerize backup
~~~~

# Restore from Mega.nz

Restore is easy, just pass the same environment variables and start the restore script:

> Note: Remove the read-only option `:ro` on the source volume.

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v megarc:/root/.megav3rc \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=megav3://mega.nz/backup" \
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

Verify against the Mega.nz content:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -v megarc:/root/.megav3rc \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=megav3://mega.nz/backup" \
    blacklabelops/volumerize verify
~~~~

> Will perform a single verification of the volume contents against the Mega.nz archive.

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
    -v megarc:/root/.megav3rc \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=megav3://mega.nz/backup" \
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
