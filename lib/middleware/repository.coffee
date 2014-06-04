plank = require("../")
queue = require("../queue")
uuid = require("node-uuid")

module.exports = (req, res, next) ->
  return next "Missing xIP id (xid) in body" if not req.body?.payload?.xid?
  return next "Missing xIP uri (xuri) in body" if not req.body?.payload?.xuri?
  return next "Missing workflow id (wid) in body" if not req.body?.payload?.wid?

  xid = req.body.payload.xid
  xuri = req.body.payload.xuri
  [wid, wstep] = req.body.payload.wid.split "/"
  return next "Workflow id does not contain step (/step)" if not wstep
  wstep = parseInt wstep
  wiid = req.body.payload.wiid or uuid.v4()

  repoName = plank.getRepoName xuri, wid
  repoPath = plank.getRepoPath xuri, wid

  req.xid = xid
  req.xuri = xuri
  req.repoName = repoName
  req.repoPath = repoPath

  req.wid = wid
  req.wstep = wstep
  req.wiid = wiid

  req.queue =
    xid: xid
    xuri: xuri
    wid: "#{wid}/#{wstep}"
    wiid: wiid
    state: "PENDING"
    commits: []

  queue[wiid] ?= {}
  queue[wiid][wstep] = req.queue

  console.info "[REPO] Trying to clone #{xuri}..."
  plank.getRepo xuri, repoPath, (err, repo) ->
    return next err if err
    console.info "[REPO] Cloned repo succesfully."
    req.repo = repo
    return next()
