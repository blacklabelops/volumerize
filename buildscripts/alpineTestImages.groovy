node('docker') {
    checkout scm
    sh './buildscripts/release.sh && ./buildscripts/cleanAlpineContainers.sh'
    try {
      sh './buildscripts/release.sh && ./buildscripts/testSupportedAlpineImages.sh'
    } finally {
      sh './buildscripts/release.sh && ./buildscripts/cleanAlpineContainers.sh'
    }
}
