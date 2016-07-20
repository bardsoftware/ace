define(function(require, exports, module) {
    require("ace/ext/jquery");
    require("ace/ext/bootstrap/js/bootstrap.min");
    var cssBootstrapPath = require.toUrl("./bootstrap/css/bootstrap.min.css ");
    var linkBootstrap = $("<link>").attr({
      rel: "stylesheet",
      href: cssBootstrapPath
    });
    $("head").append(linkBootstrap);
});
