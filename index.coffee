express = require("express")
bodyParser = require("body-parser")

uuid = require("node-uuid")
fs = require("fs")
restler = require("restler")

plank = require("./lib")

app = express()

app.use bodyParser()
app.use require "./lib/middleware/repository"
#app.use require "./lib/middleware/git-server"

# curl -H "Content-Type: application/json" -d '{"payload":{"xid":"1","xuri":"https://github.com/pericles-project/tests.git","wid":"test-1"}}' http://localhost:3000/zero

app.get "/zero", (req, res, next) ->
  newFileName = "new-file-#{uuid.v4()}.tmp"

  console.info "Add a new file named '#{newFileName} in #{req.repoPath}/#{newFileName}"
  fs.appendFile "#{req.repoPath}/#{newFileName}", "New line or whatever...", (err) ->
    return next err if err

    console.info "Written a new file."
    plank.commit req.repoPath, newFileName, "Create new random file.", (err, commitIdNew) ->
      return next err if err

      fs.appendFile "#{req.repoPath}/README.md", "Something happening...\r\n", (err) ->
        return next err if err

        plank.commit req.repoPath, "README.md", "Modify readme file.", (err, commitIdEdit) ->
          return next err if err

          commits = {}
          commits[commitIdNew] = newFileName
          commits[commitIdEdit] = "README.md"

          if req.query.forward
            restler.get("http://localhost:#{process.env.PORT}/zero?repo=#{req.repoPath}")

          req.commits = commits

          return next()

app.use (req, res, next) ->
  console.info "Figuring out what to do next..."
  return res.send req.commits

app.listen process.env.PORT || 3000