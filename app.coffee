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

regex = new RegExp '<p>(.*)(?=<div )'
parser.on 'article', (article) ->
  # console.log article.description
  article.unix_timestamp = +new Date(article.pubdate)
  article.pretty_timestamp = moment(article.pubdate).fromNow().toUpperCase()

  paras = article.description.match(regex)
  article.description = paras[0] if paras? and paras[0]?
  
  article.paragraphs = article.description.substring(3, article.description.lastIndexOf('</p>')).split('</p><p>')
  article.mob_paragraphs = article.paragraphs.slice(0,3)
  article.desk_paragraphs = article.paragraphs.slice(0,5)
  # console.log article.paragraphs
  
  if articles[0]? and article.unix_timestamp > articles[0].unix_timestamp
    articles.unshift article
  else
    articles.push article
  articles.splice(20)
  # console.log article.description
  # console.log "\n\n"


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


is_mobile = (req) ->
  ua = req.header('user-agent')
  if (/mobile/i.test(ua)) 
    return true
  else return false

app.get '/', (req, res) ->
  for article in articles
    article.pretty_timestamp = moment(article.pubdate).fromNow().toUpperCase()
    
  view = "desktop"
  if is_mobile(req)
    view = "mobile"
    
  app.render view, {'articles': articles}, (err, html) ->
    console.log err if err?
    res.send html

port = process.env.PORT || 1999
app.listen port
