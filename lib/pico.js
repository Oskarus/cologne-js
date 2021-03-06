
exports.Pico = (function() {

  function Pico(cachingTime) {
    this.cachingTime = cachingTime != null ? cachingTime : 60;
    if (!(this instanceof Pico)) {
      return new Pico(this.cachingTime);
    }
    this.cache = [];
  }

  Pico.prototype.set = function(key, value) {
    var _this = this;
    this.cache[key] = value;
    return setTimeout((function() {
      return _this.cache[key] = null;
    }), this.cachingTime * 1000);
  };

  Pico.prototype.get = function(key) {
    if (this.cache) {
      return this.cache[key];
    }
  };

  return Pico;

})();
