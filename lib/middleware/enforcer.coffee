restler = require("restler")

WFS_HOST = process.env.WFS_HOST or "localhost"
WFS_PORT = process.env.WFS_PORT or "8000"
WFS_URI = process.env.PLANK_WF_URI or "http://#{WFS_HOST}:#{WFS_PORT}"

module.exports = (req, res, next) ->
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