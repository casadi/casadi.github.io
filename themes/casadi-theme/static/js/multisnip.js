$(document).ready(function() {
  $('code').each(function(i, block) {
    hljs.highlightBlock(block);
  });

  // $('multisnip').wrap("<multisnip></multisnip>");
  $('multisnip').each(function(i, block) {
    $(block).prepend("<ul class='nav nav-tabs nav-tabs-multisnip'></ul>");
    $(block).children().each(function(ii, pre) {
      if($(pre).is("pre")) {
        $(pre).children().each(function(iii, code) {
          if(iii == 0) {
            var $li = $("<li>", {"class": "active"});
          } else {
            $(code).hide();
            var $li = $("<li>");
          }
          console.log(code);
          $li.append("<a>" + $(code).attr("language") + "</a>");
          $li.click(function(){ makeActive($(this)) });
          $(block).find("ul.nav-tabs-multisnip").append($li);
        });
      }
    });
    $(block).css("visibility", "visible");
  });
});

function makeActive(el) {
  // console.log(el);
  $(el).parent().children().each(function(i, chel) {
    $(chel).removeClass("active");
  });
  $(el).addClass("active");
  $(el).parent().parent().find("code").hide();
  $(el).parent().parent().find("code[language="+$(el).text()+"]").show();
}
