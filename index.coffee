express = require("express")
sha1 = require("sha1")
uuid = require("node-uuid")
fs = require("fs")
restler = require("restler")

#Branch = require("nodegit").Branch
clone = require("nodegit").Repo.clone
open = require("nodegit").Repo.open
git = require("nodegit")

plank =
  getRepoPath: (repoUrl, branchName) =>
    path = "/tmp/plank-#{sha1(repoUrl)}-#{branchName}"
    console.info "Path for #{repoUrl} is #{path}."
    return path

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


app = express()

app.get "/zero", (req, res, next) ->
  remoteGitRepo = req.query.repo
  workUuid = uuid.v4()
  repoPath = plank.getRepoPath remoteGitRepo, workUuid
  console.info "Trying to clone #{remoteGitRepo}"
  plank.getRepo remoteGitRepo, repoPath, (err, repo) ->
    console.info "Local repository seems here..."
    # console.info "Creating branch for work #{workUuid}..."
    # console.info Branch.prototype.create repo, repo.getCommit("HEAD"), true
    # repo.getBranch workUuid,
    newFileName = "new-file-#{uuid.v4()}.tmp"
    console.info "Add a new file named '#{newFileName} in #{repoPath}/#{newFileName}"
    fs.appendFile "#{repoPath}/#{newFileName}", "New line or whatever...", (err) ->
      return res.send err if err
      console.info "Written a new file."

      plank.commit repoPath, newFileName, "Create new random file.", (err, commitIdNew) ->
        return next err if err

        fs.appendFile "#{repoPath}/README.md", "Something happening...\r\n", (err) ->
          return next err if err

          plank.commit repoPath, "README.md", "Modify readme file.", (err, commitIdEdit) ->
            return next err if err

            commits = {}
            commits[commitIdNew] = newFileName
            commits[commitIdEdit] = "README.md"

            if req.query.forward
              restler.get("http://localhost:#{process.env.PORT}/zero?repo=#{repoPath}")

            return res.send commits

#app.get "/one", (req, res) ->
#  remoteGitRepo = req.query.repo
#  console.info "Trying to clone #{remoteGitRepo}"
#  clone remoteGitRepo, repoPath, null, (err, repo) ->
#    return err if err
#    console.info "Congrats."
#    return res.send "Ok"

app.listen process.env.PORT || 3000