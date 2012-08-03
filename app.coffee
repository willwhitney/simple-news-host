request = require 'request'
express = require 'express'
FeedParser = require 'feedparser'
lessMiddleware = require 'less-middleware'
moment = require 'moment'

parser = new FeedParser()
app = express()

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use("/styles", lessMiddleware({ src: __dirname + '/styles'}))
  app.use("/styles", express.static(__dirname + '/styles'))

articles = []

regex = new RegExp '<p>(.*)(?=<div class="related")'
parser.on 'article', (article) ->
  # console.log article.description
  article.unix_timestamp = +new Date(article.pubdate)
  article.pretty_timestamp = moment(article.pubdate).fromNow()

  paras = article.description.match(regex)
  article.description = paras[0] if paras? and paras[0]?
  
  if articles[0]? and article.unix_timestamp > articles[0].unix_timestamp
    articles.unshift article
  else
    articles.push article
  articles.splice(20)


fetch = ->
  console.log 'fetching new at ' + moment().format('dddd, MMMM Do YYYY, h:mm:ss a')
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
  for article in articles
    article.pretty_timestamp = moment(article.pubdate).fromNow()
  app.render 'articles', {'articles': articles}, (err, html) ->
    # console.log err
    res.send html

app.listen 1999
