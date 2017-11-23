var releases = undefined;
var gh = undefined;

function getReleasesSorted() {
  var dfd = $.Deferred();
  gh.getRepo('meco-group','gilc').listReleases().then(function(resp) {
  // gh.getRepo('casadi','casadi').listReleases().then(function(resp) {
    // sort by created_at key
    resp.data.sort(function(a, b){
      var keyA = new Date(a.created_at);
      var keyB = new Date(b.created_at);
      if(keyA < keyB) return 1;
      if(keyA > keyB) return -1;
      return 0;
    });
    dfd.resolve(resp);
  }).catch(function(err) {
    dfd.reject(err.message);
  });
  return dfd.promise();
}

function getOpenIssuesCount() {
  var dfd = $.Deferred();
  gh.getRepo('casadi','casadi').getDetails().then(function(res) {
    dfd.resolve(res.data.open_issues_count);
  });
  return dfd.promise();
}

function getRateStatus() {
  var dfd = $.Deferred();
  gh.getRateLimit().getRateLimit().then(function(resp) {
    // resolve with remaining nr of calls and time until reset (in seconds)
    dfd.resolve(resp.data.rate.remaining, new Date(resp.data.rate.reset * 1000));
  }).catch(function(error) {
    dfd.reject(error.message);
  });
  return dfd.promise();
}

function printRateInfo() {
  getRateStatus().then(function(calls, time) {
    console.log(calls + " remaining calls until reset in " + Math.round((time-new Date())/1000/60) + " mins.");
  });
}

// download stats from sourceforge
function getDownloadStats() {
  var dfd = $.Deferred();
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() {
    if(xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      dfd.resolve(JSON.parse(xmlHttp.responseText));
    }
  }
  xmlHttp.open("GET", "https://sourceforge.net/projects/casadi/files/stats/json?start_date=2014-10-29&end_date=2017-11-22", true); // false for synchronous request
  xmlHttp.send(null);
  return dfd.promise();
}

// MOCK-UP function
function showReleases(relData) {
  // print the release table
  var release = relData.data;
  $(release).each(function(nr, rel) {
    // console.log(rel);
    if(nr == 0) var panel = "<div class=\"panel panel-success\">";
    else var panel = "<div class=\"panel panel-default\">";

    panel +=  "<div class=\"panel-heading\" data-toggle=\"collapse\" data-parent=\"#accordion\" href=\"#collapse" + nr + "\">" +
                "<h4 class=\"panel-title pull-left\">" + rel.tag_name + "</h4>" +
                "<h6 class=\"panel-title pull-right\">" + new Date(rel.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }) + "</h6>" +
                "<div class=\"clearfix\"></div>" +
              "</div>";
    if(nr == 0) panel += "<div id=\"collapse" + nr + "\" class=\"panel-collapse collapse in\">";
    else panel += "<div id=\"collapse" + nr + "\" class=\"panel-collapse collapse\">";
    // panel +=
    panel += "<div class=\"panel-body\">" +
    "<ul class=\"nav nav-pills\">" +
              "<li class=\"active\"><a href=\"#tab1default\" data-toggle=\"tab\">Download</a></li>" +
              "<li><a href=\"#tab2default\" data-toggle=\"tab\">Changelog</a></li>" +
              "<li><a href=\"#tab3default\" data-toggle=\"tab\">Instructions</a></li>" +
              "</ul>" + rel.body + "</div>" +
              "</div></div>";

    $("div#accordion").append(panel);
  });
}
