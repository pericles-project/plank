express = require("express")
bodyParser = require("body-parser")

uuid = require("node-uuid")
fs = require("fs")
restler = require("restler")

PLANK_HOST = "localhost"
PLANK_PORT = process.env.PLANK_PORT or "7000"

plank = require("./lib")

app = express()

app.use bodyParser()
app.all "/handlers/:action", require "./lib/middleware/repository"
#app.use require "./lib/middleware/git-server"

# curl -H "Content-Type: application/json" -d '{"payload":{"xid":"1","xuri":"https://github.com/pericles-project/tests.git","wid":"1/0"}}' http://localhost:3000/zero

queue = require("./lib/queue")

app.get "/status/:wiid?/:wstep?", (req, res, next) ->
  if req.params?.wiid?
    return res.send "Not found", 404 if not queue[req.params.wiid]
    if req.params?.wstep? and queue[req.params.wiid][req.params.wstep]
      return res.send "Not found", 404 if not queue[req.params.wiid][req.params.wstep]
      return res.send queue[req.params.wiid][req.params.wstep]
    return res.send queue[req.params.wiid]
  return res.send queue

app.post "/handlers/x", (req, res, next) ->
  console.info "[HANDLER:X] Handler triggered."
  req.queue.state = "WORKING"

  newFileName = "new-file-#{uuid.v4()}.tmp"
  console.info "[HANDLER:X] Adding new file with name '#{newFileName}'..."
  setTimeout =>
    fs.appendFile "#{req.repoPath}/#{newFileName}", "New line or whatever...", (err) ->
      return next err if err

      console.info "[HANDLER:X] Added."
      console.info "[HANDLER:X] Committing file..."
      plank.commit req.repoPath, newFileName, "Create new random file.", (err, commitId) ->
        return next err if err

        console.info "[HANDLER:X] Committed."
        req.queue.commits.push "#{commitId}"
        return next()
  , 10 * 1000

app.post "/handlers/y", (req, res, next) ->
  console.info "[HANDLER:Y] Handler triggered."
  req.queue.state = "WORKING"

  setTimeout =>
    console.info "[HANDLER:Y] Adding a new line to 'README.md'..."
    fs.appendFile "#{req.repoPath}/README.md", "\r\nSomething happening...", (err) ->
      return next err if err

      console.info "[HANDLER:Y] Line added."
      console.info "[HANDLER:Y] Committing file..."
      plank.commit req.repoPath, "README.md", "Modify readme file.", (err, commitId) ->
        return next err if err

        console.info "[HANDLER:Y] Committed."
        req.queue.commits.push "#{commitId}"
        return next()
  , 10 * 1000

app.all "/handlers/:action", require("./lib/middleware/enforcer")

app.listen PLANK_PORT