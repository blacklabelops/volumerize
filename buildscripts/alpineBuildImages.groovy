node('docker') {
    checkout scm
    sh './buildscripts/release.sh && ./buildscripts/buildSupportedAlpineImages.sh'
}
