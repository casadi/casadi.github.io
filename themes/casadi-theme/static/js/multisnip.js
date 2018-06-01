/* This is multisnip */

$(document).ready(function() {
  $('div.multisnip').each(function(i, block) {
    $(block).prepend("<ul class='nav nav-fill nav-tabs-multisnip'></ul>");
    var allHighlights = $(block).children();
    $(allHighlights).each(function(ii, highlight) {
      if(ii == 0) {
        $(highlight).addClass("isshown");
        console.log(highlight);
      }
      if($(highlight).is("div.highlight")) {
        $(highlight).children().each(function(iii, pre) {
          if($(pre).is("pre")) {
            $(pre).children().each(function(iv, code) {
              var lang = $(code).attr("data-lang");
              if(iv == 0) {
                var li = $("<li>", {"class": "nav-item isshown"});
              } else {
                $(code).hide();
                var li = $("<li>", {"class": "nav-item"});
              }
              li.append("<a>" + lang + "</a>");
              li.click(function(){ makeActive(highlight) });
              $(block).find("ul.nav-tabs-multisnip").append(li);
            });
          }
        });
      }
    });
    $(block).css("visibility", "visible");
  });
});

function makeActive(hl) {
  $(hl).parent().children().each(function(i, el) { $(el).removeClass("isshown"); });
  $(hl).addClass("isshown");
}
