var request, serializeObject,
  __hasProp = {}.hasOwnProperty;

request = require('request');

exports.GoogleCalendar = (function() {

  function GoogleCalendar(calendarId) {
    this.calendarId = calendarId;
    if (!(this instanceof GoogleCalendar)) {
      return new GoogleCalendar(this.calendarId);
    }
  }

  GoogleCalendar.prototype.getUrl = function(controller) {
    if (controller == null) {
      controller = 'ical';
    }
    return "https://www.google.com/calendar/" + controller + "/" + this.calendarId + "%40group.calendar.google.com/public/basic";
  };

  GoogleCalendar.prototype.getICalUrl = function() {
    return "" + (this.getUrl()) + ".ics";
  };

  GoogleCalendar.prototype.getJSON = function(parameters, callback) {
    var url,
      _this = this;
    url = "" + (this.getUrl('feeds')) + "?" + (serializeObject(parameters)) + "&alt=jsonc&hl=cs";
    return request({
      uri: url,
      timeout: 2000
    }, function(err, res, body) {
      var items;
      if (res && res.statusCode !== 200) {
        err = res.statusCode;
      }
      if (err) {
        callback(new Error('Could not fetch dates from calendar: ' + err));
      } else {
        try {
          items = JSON.parse(body).data.items;
          console.log(items);
          callback(null, items);
        } catch (err) {
          callback(new Error('Could not fetch dates from calendar: ' + err));
        }
      }
    });
  };

  return GoogleCalendar;

})();

serializeObject = function(obj) {
  var key, pairs, value;
  pairs = [];
  for (key in obj) {
    if (!__hasProp.call(obj, key)) continue;
    value = obj[key];
    pairs.push("" + (encodeURIComponent(key)) + "=" + (encodeURIComponent(value)));
  }
  return pairs.join('&');
};
