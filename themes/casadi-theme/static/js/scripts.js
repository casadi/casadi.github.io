$(document).ready(function() {
  $("#btn-search").click(function() {
    $('#field-search').fadeToggle(200);
  });

  // var href = $(this).attr('href');
  $("a.reference.internal").each(function(i, k) {
    var id = $(k).attr("href").replace('index.html','');
    var href = "javascript:scrollTo(\""+id+"\")";
    // $(k).attr("href", "javascript:void(0);");
    // href="javascript:void(0)" onclick="location.href='"
    // $(k).click(function() {
    //   var tag = $(this)[0];
    //   scrollTo($(tag).attr("href").replace('index.html',''));
    //   event.stopPropagation();
    // });
    // $(k).attr("href", "");
    $(k).attr("href", id);
  });
});

function scrollTo(id) {
  console.log(id);
  $('html,body').animate({scrollTop: $(id).offset().top - 65}, 'slow');
}
