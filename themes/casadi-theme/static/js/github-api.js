var releases = undefined;
var gh = undefined;

document.addEventListener("DOMContentLoaded", function() {
  gh = new GitHub({ token: 'f17675f2f0578a5bfde132ee479a95b1150324af' });
  printRateInfo();
  getAllReleases().then(function(rel) {
    console.log(rel);
    releases = rel;
    printReleaseTables(rel);
  });
});

function printReleaseTables(relArray) {
  // print the latest release table
  var latest = relArray.data[0];
  var th = "<thead><tr><th>Version</th><th>Release date</th><th>Links</th></tr></thead>";
  $("table#latest-release").append(th);
  var tb = "<tbody><tr><td>" + latest.tag_name + "</td><td>" + latest.published_at + "</td><td><a href=\"" + latest.html_url + "\" target=\"_blank\">Github</a></td></tr></tbody>";
  $("table#latest-release").append(tb);

  // print the remaining releases
  var rest = relArray.data.slice(1);
  // var th = "<tr><th>Version</th><th>Release date</th><th>Links</th></tr>";
  $("table#all-releases").append(th);
  $("table#all-releases").append("<tbody>");
  $.each(rest, function(index, value) {
    var tr = "<tr><td>" + value.tag_name + "</td><td>" + value.published_at + "</td><td><a href=\"" + value.html_url + "\" target=\"_blank\">Github</a></td></tr>";
    $("table#all-releases").append(tr);
  });
  $("table#all-releases").append("</tbody>");
}

// call-intensive !
function getLatestRelease() {
  var dfd = $.Deferred();
  // getAllReleases().then(function(data) {
  //   dfd.resolve(data[0]);
  // }).catch(function(err) {
  //   console.log(err);
  //   dfd.reject(err.message);
  // });
  dfd.resolve("No. Sorry, but no.");
  return dfd.promise();
}

function getAllReleases() {
  var dfd = $.Deferred();
  gh.getRepo('casadi','casadi').listReleases().then(function(resp) {
    dfd.resolve(resp);
  }).catch(function(err) {
    console.log(err);
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
