// var gh = undefined;
//
// $(document).ready(function() {
//   gh = new GitHub();
// });

function printVMatrix(release) {
  // var gh = new GitHub();
  // var repo = gh.getRepo('casadi','casadi');
  // var issues = gh.getIssues('casadi','casadi');
  // console.log();
  // console.log(gh);
  printRateInfo();


  var gh = new GitHub();
  gh.getRepo('casadi','casadi').listReleases().then(function(resp) {
    console.log(resp);
  })
}

function getLatestRelease() {
  return null;
}

function getRateStatus() {
  var dfd = $.Deferred();
  var gh = new GitHub();
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
