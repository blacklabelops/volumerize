/**
 * Jenkins 2.0 Buildfile
 **/

/**
 * Build parameters, must be adjusted when forked!
 **/
dockerImageName = 'blacklabelops/volumerize'
dockerTags = ["latest"] as String[]
dockerTestCommands =
 ["echo hello world",
  "ps -All",
  "uname -r",
  "whoami",
  "cat /etc/hosts",
  "cat /etc/passwd"] as String[]
dockerRepositories = [["","Dockerhub","DockerhubEmail"]] as String[][]
dockerImages = ["blacklabelops/alpine:3.4"] as String[]

def getBranchName() {
  def branchName = env.JOB_NAME.replaceFirst('.+/', '')
  echo 'Building on Branch: ' + branchName
  def tagPostfix = ''
  if (branchName != null && !'master'.equals(branchName)) {
     tagPostfix = branchName
  }
  return tagPostfix
}

return this;
