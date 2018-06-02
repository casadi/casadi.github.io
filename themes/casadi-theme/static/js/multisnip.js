/* This is multisnip */

$(document).ready(function() {
  $('div.multisnip').each(function(ib, block) {
    $(block).prepend("<ul class='nav nav-fill nav-tabs-multisnip'></ul>");

    $(block).children('div.highlight').each(function(ih, highlight) {
      if(ih == 0) $(highlight).show();
      else $(highlight).hide();

      $(highlight).find('pre code').each(function(ic, code) {
        var lang = $(code).attr("data-lang");
        if(ih == 0) {
          var li = $("<li>", {"class": "nav-item isshown"});
        } else {
          var li = $("<li>", {"class": "nav-item"});
        }
        if (lang=="octave") {
          lang = lang + "/Matlab";
        }
        if (lang=="cpp") {
          lang = "C++";
        }
        li.append("<a>" + lang + "</a>");
    
        li.click(function(){ makeActive(highlight, li) });
        $(block).find("ul.nav-tabs-multisnip").append(li);
      });
    });

    // $(block).css("visibility", "visible");
  });
});

function makeActive(hl, li) {
  // $(hl).parent().children().each(function(i, el) { $(el).removeClass("isshown"); });
  // $(hl).addClass("isshown");
  $(hl).parent().children('div.highlight').hide();
  $(hl).show();

  $(li).parent().children().each(function(i, el) { $(el).removeClass("isshown"); });
  $(li).addClass("isshown");
}
