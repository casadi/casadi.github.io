$(document).ready(function() {
  // $("#btn-search").click(function() {
  //   $('#field-search').fadeToggle(200);
  // });

  // $('div.highlight-python').each(function(i, block) {
  //   $(block).addClass('hljs').addClass('python');
  //   $(block).find('div.highlight').addClass('hljs');
  //   $(block).find('pre').addClass('hljs');
  //   hljs.highlightBlock(block);
  // });
  // $('div.highlight-octave').each(function(i, block) {
  //   $(block).addClass('hljs').addClass('matlab');
  //   $(block).find('div.highlight').addClass('hljs');
  //   $(block).find('pre').addClass('hljs');
  //   hljs.highlightBlock(block);
  // });
  // $('div.highlight-cpp').each(function(i, block) {
  //   $(block).addClass('hljs').addClass('cpp');
  //   $(block).find('div.highlight').addClass('hljs');
  //   $(block).find('pre').addClass('hljs');
  //   hljs.highlightBlock(block);
  // });

  $("a.reference.internal").each(function(i, k) {
    var id = $(k).attr("href").replace('index.html','');
    // var href = "javascript:scrollTo(\""+id+"\")";
    $(k).attr("href", id);
  });
});

// function scrollTo(id) {
//   console.log(id);
//   $('html,body').animate({scrollTop: $(id).offset().top - 65}, 'slow');
// }
