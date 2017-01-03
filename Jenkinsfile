/** Jenkins 2.0 Buildfile
*
* Slave 'docker' can be started by typing:
* docker run -d -v /var/run/docker.sock:/var/run/docker.sock --link jenkins:jenkins -e "SWARM_CLIENT_LABELS=docker" blacklabelops/swarm-dockerhost
**/
node {
  checkout scm
  stage 'Build Images'
  parallel("image-alpine": { load './buildscripts/alpineBuildImages.groovy' })
  stage 'Test Images'
  parallel("image-alpine": { load './buildscripts/alpineTestImages.groovy' })
}
