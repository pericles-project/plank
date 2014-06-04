# Plank

## Installation / Development guide

    npm install
    npm install nodemon -g
    PLANK_HOST=localhost PLANK_PORT=7000 WFS_HOST=localhost WFS_PORT=8000 nodemon index.coffee

### Nodegit issues

#### OSX

    brew update
    brew install cmake
    cd node_modules/nodegit/ && npm install ejs &&  npm run-script gen && npm install && cd ../..
