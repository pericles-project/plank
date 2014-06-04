GitServer = require("git-server")

gitServerPort = process.env.PLANK_GIT_PORT or 7000

createRepoServer = (repoName) ->
  repo =
    name: repoName
    anonRead: true

  server = new GitServer
    repoLocation: "/tmp/plank"
    repos: [repo]
    port: gitServerPort++

  return server

module.exports = (req, res, next) ->
  console.info "Loading Git Server..."
  gitServer = createRepoServer req.repoName
  console.info gitServer
  console.info "Git Server on http://localhost:#{gitServerPort}/#{req.repoName}.git"

  next()