express = require 'express'
lessMiddleware = require 'less-middleware'
moment = require 'moment'
content = require './content'

app = express()
app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use("/styles", lessMiddleware({ src: __dirname + '/styles'}))
  app.use("/styles", express.static(__dirname + '/styles'))

is_mobile = (req) ->
  ua = req.header('user-agent')
  if (/mobile/i.test(ua)) 
    return true
  else return false

app.get '/', (req, res) ->
  for article in content.articles()
    article.pretty_timestamp = moment(article.pubdate).fromNow().toUpperCase()
    
  view = "desktop"
  if is_mobile(req)
    view = "mobile"
    
  app.render view, {'articles': content.articles()}, (err, html) ->
    console.log err if err?
    res.send html

content.start_fetching()

port = process.env.PORT || 1999
app.listen port