---
title: "Get CasADi"
description: "no description"
type: singles
---

# Get CasADi

Here you can easily get your personal copy of CasADi.
Choose your *desired version and platform* below.

<!-- TABLE WITH LABELS -->
<div class="panel-group" id="accordion"></div>

<!-- <table id="overview-releases" class="release">
  <col class="version">
  <col class="date">
  <col class="binary">
</table> -->

<script>
  <!-- MOCK-UP -->
  //document.addEventListener("DOMContentLoaded", function() {
  //  justShowANiceReleaseTable();
  //});

  <!-- THE REAL THING -->
  document.addEventListener("DOMContentLoaded", function() {
    gh = new GitHub({ token: 'f17675f2f0578a5bfde132ee479a95b1150324af' });
    printRateInfo();
    getReleasesSorted().then(function(rel) {
      console.log(rel);
      releases = rel;
      showReleases(rel);
    });
  });
</script>
