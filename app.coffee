#!/usr/bin/env coffee
express  = require('express')
sm       = require('sitemap')
markdown = require('node-markdown').Markdown
XRegExp  = require('xregexp').XRegExp
date     = require('./lib/date.coffee')
fs       = require("fs")

calendarId = '6gg9b82umvrktnjsfvegq1tb24'
gcal       = require('./lib/googlecalendar.coffee').GoogleCalendar(calendarId)


app = module.exports = express.createServer()

sitemap = module.exports = sm.createSitemap(
    hostname:"http://jsconf.cz",
    cacheTime: 600000,
    urls: [
      { url: '/meetups/', changefreq: 'weekly',  priority: 0.9 },
      { url: '/conferences/', changefreq: 'monthly',  priority: 0.3 },
    ]
)

# Configuration
app.configure () ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + '/public')

app.configure 'development', () ->
  app.set 'cacheInSeconds', 0
  app.set 'port', 3333
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.configure 'production', () ->
  app.set 'cacheInSeconds', 60 * 60
  app.set 'port', process.env.PORT or 5000
  app.use express.errorHandler()


# Content caching
cache = require('./lib/pico.coffee').Pico(app.settings.cacheInSeconds)


# Routes
app.get '/*', (req, res, next) ->
  if req.headers.host.match(/^www/) isnt null
    res.redirect('http://' + req.headers.host.replace(/^www\./, '') + req.url)
  else
    next()

app.get '/sitemap.xml', (req, res) ->
  res.header('Content-Type', 'application/xml')
  res.send( sitemap.toString() )

app.get '/robots.txt', (req, res) ->
  res.header('Content-Type', 'text/plain')
  res.send('User-Agent: *')

app.get '/', (req, res) ->

  content = cache.get 'websiteContent'
  if content
    res.render 'index', content
  else
    gcalOptions =
      'futureevents': true
      'orderby'     : 'starttime'
      'sortorder'   : 'ascending'
      'fields'      : 'items(details)'
      'max-results' : 3

    gcal.getJSON gcalOptions, (err, data) ->
      if data && data.length
        events = []
        for item in data
          regex = XRegExp('Kdy:.*?(?<day>\\d{1,2})\\. (?<month>\\w+)\\.? (?<year>\\d{4})')
          parts = XRegExp.exec(item.details, regex)
          foo = date.convert(parts.year, parts.month, parts.day)

          talks = XRegExp.exec(item.details, XRegExp('Popis události: (.*)', 's'))
          if (talks && talks[1])
            [talk1, talk2] = talks[1].split('---')
          else
            [talk1, talk2] = ['', '']

          events.push
            date: date.format(foo, "%b %%o, %Y")
            talk1: markdown(talk1)
            talk2: markdown(talk2)

        content =
          'events': events,
          'view': 'index',
          'conferences' : [markdown(str = fs.readFileSync(__dirname + '/wiki/conferences.markdown', "utf8"))]

        # Store content in cache
        cache.set 'websiteContent', content

      else
        content =
          'events': [],
          'view': 'index',
          'conferences' : [markdown(str = fs.readFileSync(__dirname + '/wiki/conferences.markdown', "utf8"))]
        # console.log err

      res.render 'index', content

app.get '/jsconf.ics', (req, res) ->
  res.redirect gcal.getICalUrl

app.get '/meetups', (req, res) ->
  str = fs.readFileSync(__dirname + '/wiki/meetups.markdown', "utf8")
  content =
    'events': [],
    'view': 'meetups',
    'markup' : [markdown(str)]
  res.render 'wiki', content

app.get '/conferences', (req, res) ->
  str = fs.readFileSync(__dirname + '/wiki/conferences.markdown', "utf8")
  content =
    'events': [],
    'view': 'conferences',
    'markup' : [markdown(str)]
  res.render 'wiki', content

app.get  '/404', (req, res) ->
  content =
    'events': [],
    'view': 'conferences'
  res.status 404
  res.render '404', content

app.listen app.settings.port
console.log "Express server listening in #{ app.settings.env } mode at http://localhost:#{ app.settings.port }/"
