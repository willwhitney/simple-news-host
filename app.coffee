request = require 'request'
express = require 'express'
FeedParser = require 'feedparser'
lessMiddleware = require 'less-middleware'

parser = new FeedParser()
app = express()

app.configure ->
  app.set 'views', __dirname + '/views'
  # app.set 'styles', __dirname + '/styles'
  
  app.set 'view engine', 'jade'
  app.use("/styles", lessMiddleware({ src: __dirname + '/styles'}))
  app.use("/styles", express.static(__dirname + '/styles'))



articles = []

regex = new RegExp '<p>(.*)<div class="related"'
parser.on 'article', (article) ->
  paras = article.description.match(regex)
  article.description = paras[0] if paras? and paras[0]?
  articles.push article

fetch = ->
  reqObj = {'uri': 'http://feeds.guardian.co.uk/theguardian/rss'}
  if articles[articles.length - 1]?
    reqObj['headers'] = {'If-Modified-Since' : articles[articles.length - 1] }
  request reqObj, (err, response, body) ->
    articles = []
    parser.parseString(body)

fetch()
setInterval -> 
  fetch()
, 5 * (60 * 1000)

app.get '/', (req, res) ->
  app.render 'articles', {'articles': articles}, (err, html) ->
    console.log err if err?
    res.send html
  
app.listen 1999