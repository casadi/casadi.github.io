$(document).ready(function() {
  $('a.reference.internal').each(function(i, k) {
    var id = $(k).attr('href').replace('index.html','');
    $(k).attr('href', id);
  });

  $('div.multisnip').each(function(ib, block) {
    $(block).prepend('<ul class="nav nav-fill nav-tabs-multisnip"></ul>');
    $(block).children('div.highlight').each(function(ih, highlight) {
      if(ih == 0) $(highlight).show();
      else $(highlight).hide();
      $(highlight).children('pre').children('code').each(function(ic, code) {
        var lang = $(code).attr('data-lang');
        if(ih == 0) {
          var li = $('<li>', {'class': 'nav-item isshown'});
        } else {
          var li = $('<li>', {'class': 'nav-item'});
        }
        if (lang=='octave') {
          lang = lang + '/Matlab';
        }
        if (lang=='cpp') {
          lang = 'C++';
        }
        li.append('<a>' + lang + '</a>');

        li.click(function(){ makeActive(highlight, li) });
        $(block).find('ul.nav-tabs-multisnip').append(li);
      });
    });
  });

  function revealHash(hash, animate) {
    if(!hash) return;
    var el = document.getElementById(hash.substr(1));
    if(!el) return;
    var card = $(el).closest('.card')[0];
    if(typeof card === 'undefined') return;

    $(card).find('a.card-header.collapsed').each(function(i, a) {
      $(a).removeClass('collapsed');
      $(a).attr('aria-expanded', 'true');
    });
    $(card).find('div.collapse').each(function(i, d) {
      $(d).addClass('show');
    });

    // if the target is a tab pane, activate its tab
    if($(el).hasClass('tab-pane')) {
      var link = $(card).find('a[data-toggle="tab"]').filter(function() {
        return $(this).attr('href') === hash;
      });
      if(link.length) link.tab('show');
    }

    var top = $(card).offset().top - 70;
    if(animate) $('html,body').animate({scrollTop: top});
    else $('html,body').scrollTop(top);
  }

  revealHash(window.location.hash, true);
  $(window).on('hashchange', function() { revealHash(window.location.hash, true); });

});

(function addAnchorElements() {
  // console.log('running addAnchorElements');
  $('.content [id]').each(function(i, el) {
    $('<div class="anchor" id="' + el.id + '"></div>').insertBefore(el);
    $(el).attr('id', el.id + '-sub');
  });
})();

function makeActive(hl, li) {
  $(hl).parent().children('div.highlight').hide();
  $(hl).show();
  $(li).parent().children().each(function(i, el) { $(el).removeClass('isshown'); });
  $(li).addClass('isshown');
}

let observer = new IntersectionObserver(
  function(a,b) {
    if (a[0].isIntersecting) {
      $('#bottom-banner').fadeTo(250, 0);
    } else {
      $('#bottom-banner').fadeTo(250, 1);
    }
  }
);

let landing_cover = document.getElementById('landing-cover') || null
if (landing_cover) observer.observe(landing_cover);
