express = require("express")
clone = require("nodegit").Repo.clone

throw new Error "Missing PLANK_GIT_PATH" if not process.env.PLANK_GIT_PATH
repoPath = process.env.PLANK_GIT_PATH

app = express()


#clone 'https://github.com/pericles-project/testbed-deploy.git', '/tmp/plank-0', null, (err, repo) ->
#  return err if err
#  console.info repo

app.get "/one", (req, res) ->
  remoteGitRepo = req.query.repo
  console.info "Trying to clone #{remoteGitRepo}"
  clone remoteGitRepo, repoPath, null, (err, repo) ->
    return err if err
    console.info "Congrats."
    return res.send "Ok"

app.listen process.env.PORT || 3000