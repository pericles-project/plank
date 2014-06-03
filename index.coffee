express = require("express")
uuid = require("node-uuid")
fs = require("fs")
restler = require("restler")

plank = require("./lib")

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

app.listen process.env.PORT || 3000