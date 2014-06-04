clone = require("nodegit").Repo.clone
open = require("nodegit").Repo.open
git = require("nodegit")

sha1 = require("sha1")

plank =
  getRepoPath: (repoUrl, branchName) ->
    repoName = @getRepoName repoUrl, branchName
    repoPath = "/tmp/plank/#{repoName}.git"
    console.info "Path for #{repoUrl} is #{repoPath}."
    return repoPath

  getRepoName: (repoUrl, branchName) ->
    return "#{sha1(repoUrl)}-#{branchName}"

  getRepo: (remoteRepo, repoPath, cb) ->
    # Check if repo is cloned localy
    clonedPath = repoPath
    open clonedPath, (err, repo) ->
      if err
        clone remoteRepo, clonedPath, null, cb
      else
        cb null, repo

  commit: (repoPath, fileName, message, cb) ->
    open repoPath, (err, repo) ->
      return cb err if err

      repo.openIndex (openIndexError, index) ->
        throw openIndexError  if openIndexError

        index.read (readError) ->
          throw readError  if readError

          console.info "[REPO] Adding file '#{fileName}'..."
          index.addByPath fileName, (addByPathError) ->
            throw addByPathError  if addByPathError

            index.write (writeError) ->
              throw writeError if writeError

              index.writeTree (writeTreeError, oid) ->
                throw writeTreeError  if writeTreeError

                git.Reference.oidForName repo, "HEAD", (oidForName, head) ->
                  throw oidForName  if oidForName

                  #get latest commit (will be the parent commit)
                  repo.getCommit head, (getCommitError, parent) ->
                    throw getCommitError  if getCommitError
                    author = git.Signature.create("Scott Chacon", "schacon@gmail.com", 123456789, 60)
                    committer = git.Signature.create("Scott A Chacon", "scott@github.com", 987654321, 90)

                    #commit
                    console.info "[REPO] Commiting file '#{fileName}' with message '#{message}'..."
                    repo.createCommit "HEAD", author, committer, message, oid, [parent], (error, commitId) ->
                      console.log "[REPO] New Commit:", commitId.sha()

                      return cb null, commitId

module.exports = plank