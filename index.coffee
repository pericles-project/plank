express = require("express")
bodyParser = require("body-parser")

uuid = require("node-uuid")
fs = require("fs")
restler = require("restler")

PLANK_HOST = "localhost"
PLANK_PORT = process.env.PLANK_PORT or "7000"

WFS_HOST = process.env.WFS_HOST or "localhost"
WFS_PORT = process.env.WFS_PORT or "8000"
WFS_URI = process.env.PLANK_WF_URI or "http://#{WFS_HOST}:#{WFS_PORT}"

plank = require("./lib")

app = express()

app.use bodyParser()
app.all "/handlers/:action", require "./lib/middleware/repository"
#app.use require "./lib/middleware/git-server"

# curl -H "Content-Type: application/json" -d '{"payload":{"xid":"1","xuri":"https://github.com/pericles-project/tests.git","wid":"1/0"}}' http://localhost:3000/zero

queue = require("./lib/queue")

app.get "/status/:wiid?", (req, res, next) ->
  return res.send queue[req.query.wiid] if req.query?.wiid? and queue[req.query.wiid]?
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

app.all "/handlers/:action", (req, res, next) ->
  console.info "[ENFORCER] Figuring out what to do next..."
  req.queue.state = "COMPLETED"
  wUri = "#{WFS_URI}/workflows/#{req.wid}/#{req.wstep+1}"
  console.info "[ENFORCER] Trying to get wf step from #{wUri}"

  restler.get wUri
  .on "complete", (result, response) =>
    return next result.message if result instanceof Error

    if response.statusCode is 200
      console.info "[ENFORCER] Next step is for compoenent #{result.id} on #{result.url}..."
      restler.postJson result.url,
        payload:
          xid: req.xid
          xuri: req.xuri
          wid: "#{req.wid}/#{req.wstep+1}"
          wiid: req.queue.wiid
        params: result.params

app.listen PLANK_PORT