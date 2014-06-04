express = require("express")
bodyParser = require("body-parser")

uuid = require("node-uuid")
fs = require("fs")
restler = require("restler")

PLANK_HOST = "localhost"
PLANK_POST = process.env.PLANK_PORT or "7000"

WFS_HOST = process.env.WFS_HOST or "localhost"
WFS_PORT = process.env.WFS_PORT or "8000"
WFS_URI = process.env.PLANK_WF_URI or "http://#{WFS_HOST}:#{WFS_PORT}"

plank = require("./lib")

app = express()

app.use bodyParser()
app.use require "./lib/middleware/repository"
#app.use require "./lib/middleware/git-server"

# curl -H "Content-Type: application/json" -d '{"payload":{"xid":"1","xuri":"https://github.com/pericles-project/tests.git","wid":"1/0"}}' http://localhost:3000/zero

app.post "/handlers/zero", (req, res, next) ->
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
            restler.get("http://#{PLANK_HOST}:#{PLANK_PORT}/zero?repo=#{req.repoPath}")

          req.commits = commits

          return next()

#app.post "/handlers/encode-video", (req, res, next) ->
#  console.info "ffmpeg -.... #{req.repoPath}"
#  plank.commit "#{req.repoPath}/fuck-if-i-know.txt", "message", (err, commitId) ->
#    return next err if err
#
#    next()

app.use (req, res, next) ->
  console.info "Figuring out what to do next..."
  wUri = "#{WFS_URI}/workflows/#{req.wid}/#{req.wstep+1}"
  console.info "Trying to get wf step from #{wUri}"

  restler.get wUri
  .on "complete", (result) =>
    return next result.message if result instanceof Error
    console.info result

    return res.send req.commits

app.listen PLANK_PORT