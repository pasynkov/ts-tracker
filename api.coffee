request = require "request"
xml2js = require "xml2js"


class Api

  constructor: (@config)->
    @apiUrl = "http://api.worksnaps.com/api"

  getMunites: (from_timestamp, to_timestamp, callback)=>

    @request(
      "projects/#{@config.projectId}/time_entries"
      {from_timestamp, to_timestamp}
      (err, res)->

        len = res?.time_entries?.time_entry?.length
        result = if len then len * 10 else 0
        callback err, result
    )

  request: (method, data, callback)=>

    request.get {
      url:  @apiUrl + "/" + method + ".xml"
      qs: data
      auth:
        user: @config.token
        pass: "ignored"
    } , (err, response, body)->

      if err
        return callback err

      if response.statusCode > 400
        return callback "Code #{response.statusCode}"

      xml2js.parseString body, callback

  format: (minutes, human = false)->

    minus = ""

    if minutes < 0
      minutes = minutes * -1
      h = Math.floor(minutes / 60)
      m = Math.round(minutes - h * 60)
      minus = "-"
    else
      h = Math.floor(minutes / 60)
      m = Math.round(minutes - h * 60)

    result = "#{minus}"

    if m < 5
      m = 0
    else if m > 55
      m = 0
      h++
    else
      unless human
        m = Math.round(m/60)

    result += "#{h}"
    if m
      if human
        result += "ч.#{m}м."
      else
        result += ".#{m}"

    unless human
      result += "ч."

    return result

module.exports = Api