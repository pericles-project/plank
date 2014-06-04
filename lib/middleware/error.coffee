module.exports = (err, req, res, next) ->
  return next() unless err

  req.state.state = "ERROR"
  req.state.error = message: err