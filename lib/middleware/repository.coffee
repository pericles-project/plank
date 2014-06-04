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

  req.state =
    payload:
      xid: xid
      xuri: xuri
      wid: wid
      wstep: wstep
      wiid: wiid
    params: req.body.params
    repo:
      name: plank.getRepoName xuri, wid
      path: plank.getRepoPath xuri, wid
    state: "PENDING"
    commits: {}

  queue[wiid] ?= {}
  queue[wiid][wstep] = req.state

  res.send req.state

  console.info "[REPO] Trying to clone #{xuri}..."
  plank.getRepo xuri, req.state.repo.path, (err, repo) ->
    return next err if err
    console.info "[REPO] Cloned repo succesfully."
    #req.repo = repo
    return next()
