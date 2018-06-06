# Using Volumerize With Amazon S3

Volumerize can backup Docker volumes on Amazon S3.

You have to perform the following steps:

Login to Amazon Web Service developers console and create a service account.

The Amazon developers console: [Amazon Developers Console](https://aws.amazon.com/console/)

In order to use all Volumerize features you need the following policy:

~~~~
{
    "Version":"2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::BUCKET_NAME",
                "arn:aws:s3:::BUCKET_NAME/*"
            ]
        }
    ]
}
~~~~

> Replace BUCKET_NAME with your bucket name!

Remember the following details:

* The AWS Access key of your user.
* The AWS Secret key of your user.
* The region of your bucket.
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

Now build your s3 url according to the template:

`s3:://s3.<bucket-region>.amazonaws.com/<bucket-name>[/<path>]`. Regions: [Amazon S3 Regions](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)

Start the container in demon mode with your AWS credentials:

~~~~
$ docker run -d \
    --name volumerize \
    -v volumerize_cache:/volumerize-cache \
    -v jenkins_volume:/source:ro \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=s3://s3.eu-central-1.amazonaws.com/duplicitytest" \
    -e "AWS_ACCESS_KEY_ID=QQWDQIWIDO1QO" \
    -e "AWS_SECRET_ACCESS_KEY=ewlfkwkejflkjwlkej3fjw381" \
    blacklabelops/volumerize
~~~~

> `volumerize_cache` is the local data cache.

You have to start an initial full backup:

~~~~
$ docker exec volumerize backupFull
~~~~

# Restore from Amazon S3

Restore is easy, just pass the same environment variables and start the restore script:

> Note: Remove the read-only option `:ro` on the source volume.

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=s3://s3.eu-central-1.amazonaws.com/duplicitytest" \
    -e "AWS_ACCESS_KEY_ID=QQWDQIWIDO1QO" \
    -e "AWS_SECRET_ACCESS_KEY=ewlfkwkejflkjwlkej3fjw381" \
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

Verify against the Amazon S3 Drive content:

~~~~
$ docker run --rm \
    -v jenkins_test_restore:/source \
    -e "VOLUMERIZE_SOURCE=/source" \
    -e "VOLUMERIZE_TARGET=s3://s3.eu-central-1.amazonaws.com/duplicitytest" \
    -e "AWS_ACCESS_KEY_ID=QQWDQIWIDO1QO" \
    -e "AWS_SECRET_ACCESS_KEY=ewlfkwkejflkjwlkej3fjw381" \
    blacklabelops/volumerize verify
~~~~

> Will perform a single verification of the volume contents against the Amazon S3 archive.

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
    -e "VOLUMERIZE_TARGET=s3://s3.eu-central-1.amazonaws.com/duplicitytest" \
    -e "AWS_ACCESS_KEY_ID=QQWDQIWIDO1QO" \
    -e "AWS_SECRET_ACCESS_KEY=ewlfkwkejflkjwlkej3fjw381" \
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
