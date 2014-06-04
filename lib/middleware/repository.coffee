plank = require("../")

module.exports = (req, res, next) ->
  console.info req.body
  return next "Missing xIP id (xid) in body" if not req.body?.payload?.xid?
  return next "Missing xIP uri (xuri) in body" if not req.body?.payload?.xuri?
  return next "Missing workflow id (wid) in body" if not req.body?.payload?.wid?

  xid = req.body.payload.xid
  xuri = req.body.payload.xuri
  wid = req.body.payload.wid
  repoName = plank.getRepoName xuri, wid
  repoPath = plank.getRepoPath xuri, wid

  req.xid = xid
  req.xuri = xuri
  req.repoName = repoName
  req.repoPath = repoPath

  console.info "Trying to clone #{xuri}..."
  plank.getRepo xuri, repoPath, (err, repo) ->
    return next err if err
    console.info "Cloned repo succesfully."
    req.repo = repo
    return next()
