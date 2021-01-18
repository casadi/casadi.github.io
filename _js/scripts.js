$(document).ready(function() {
  $("a.reference.internal").each(function(i, k) {
    var id = $(k).attr("href").replace('index.html','');
    $(k).attr("href", id);
  });

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
  });

  var hash = window.location.hash;
  if(hash) {
    var id = hash.substr(1);
    var card = $(".card[id="+id+"]")[0];
    if(typeof card !== "undefined") {
      $(card).find('a.card-header.collapsed').each(function(i, a) {
        $(a).removeClass('collapsed');
        $(a).attr("aria-expanded", "true");
      });
      $(card).find('div.collapse').each(function(i, d) {
        $(d).addClass('show');
      });
      $('html,body').animate({scrollTop: $(card).offset().top - 70});
    }
  }

});

(function addAnchorElements() {
  console.log('running addAnchorElements');
  $('.content [id]').each(function(i, el) {
    $('<div class="anchor" id="' + el.id + '"></div>').insertBefore(el);
    $(el).attr("id", el.id + '-sub');
  });
})();

function makeActive(hl, li) {
  $(hl).parent().children('div.highlight').hide();
  $(hl).show();
  $(li).parent().children().each(function(i, el) { $(el).removeClass("isshown"); });
  $(li).addClass("isshown");
}
