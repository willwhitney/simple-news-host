request = require 'request'
moment = require 'moment'
FeedParser = require 'feedparser'

parser = new FeedParser()
regex = new RegExp '<p>(.*)(?=<div )'

article_list = []

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

  if article_list[0]? and article.unix_timestamp > article_list[0].unix_timestamp
    article_list.unshift article
  else
    article_list.push article
  article_list.splice(20)
  # console.log article.description
  # console.log "\n\n"

start_fetching = ->
  fetch()
  setInterval -> 
    fetch()
  , 5 * (60 * 1000)

fetch = ->
  console.log 'fetching new at ' + moment().format('dddd, MMMM Do YYYY, h:mm:ss a')
  reqObj = {'uri': 'http://feeds.guardian.co.uk/theguardian/rss'}
  if article_list[article_list.length - 1]?
    reqObj['headers'] = {'If-Modified-Since' : article_list[article_list.length - 1] }
  request reqObj, (err, response, body) ->
    article_list = []
    parser.parseString(body)

articles = ->
  article_list

exports.start_fetching = start_fetching
exports.fetch = fetch
exports.articles = articles
