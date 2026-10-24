/* Local interactions only. No third-party scripts or tracking. */
(function () {
  'use strict';
  var menu = document.querySelector('.menu-toggle');
  var nav = document.querySelector('#main-nav');
  if (menu && nav) {
    document.documentElement.classList.add('nav-ready');
    menu.hidden = false;
    function closeMenu() {
      menu.setAttribute('aria-expanded', 'false');
      nav.classList.remove('is-open');
    }
    menu.addEventListener('click', function () {
      var open = menu.getAttribute('aria-expanded') !== 'true';
      menu.setAttribute('aria-expanded', String(open));
      nav.classList.toggle('is-open', open);
    });
    nav.addEventListener('click', function (event) {
      if (event.target.closest('a')) closeMenu();
    });
    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape' && menu.getAttribute('aria-expanded') === 'true') {
        closeMenu();
        menu.focus();
      }
    });
  }
  var dialog = document.querySelector('.screenshot-dialog');
  if (!dialog || typeof dialog.showModal !== 'function') return;
  var image = dialog.querySelector('img');
  var caption = dialog.querySelector('#screenshot-caption');
  var trigger;
  document.querySelectorAll('.screen-link, .weather-link').forEach(function (link) {
    link.addEventListener('click', function (event) {
      if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      trigger = link;
      image.src = link.href;
      image.alt = link.querySelector('img').alt;
      caption.textContent = link.dataset.caption;
      dialog.showModal();
      document.body.classList.add('dialog-open');
    });
  });
  dialog.querySelector('.dialog-close').addEventListener('click', function () { dialog.close(); });
  dialog.addEventListener('click', function (event) {
    var box = dialog.getBoundingClientRect();
    if (event.target === dialog && (event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom)) dialog.close();
  });
  dialog.addEventListener('close', function () {
    document.body.classList.remove('dialog-open');
    if (trigger) trigger.focus();
  });
})();

/* Gentle, measured top-to-bottom previews, with accessible motion controls. */
(function () {
  'use strict';
  var cards = Array.from(document.querySelectorAll('.screen-link'));
  var button = document.querySelector('.gallery-motion');
  if (!cards.length || !button || !Element.prototype.animate) return;
  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  var paused = false;
  var states = cards.map(function (card) {
    return { card: card, img: card.querySelector('img'), animation: null, visible: false, held: false };
  });
  function sync(state) {
    if (!state.animation) return;
    if (paused || reduced.matches || document.hidden || !state.visible || state.held || document.body.classList.contains('dialog-open')) state.animation.pause();
    else state.animation.play();
  }
  function measure(state) {
    if (state.animation) { state.animation.cancel(); state.animation = null; }
    if (reduced.matches || !state.img.complete || !state.img.naturalWidth) return;
    var css = getComputedStyle(state.card);
    var viewport = state.card.clientHeight - parseFloat(css.paddingTop) - parseFloat(css.paddingBottom);
    var distance = Math.max(0, state.img.offsetHeight - viewport);
    if (distance < 2) return;
    var bottom = 'translateY(-' + distance + 'px)';
    state.animation = state.img.animate([
      { transform: 'translateY(0)', offset: 0 },
      { transform: 'translateY(0)', offset: .05 },
      { transform: bottom, offset: .45 },
      { transform: bottom, offset: .55 },
      { transform: 'translateY(0)', offset: .95 },
      { transform: 'translateY(0)', offset: 1 }
    ], { duration: Math.max(12000, distance * 50), iterations: Infinity, easing: 'linear' });
    sync(state);
  }
  var observer = 'IntersectionObserver' in window ? new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      var state = states.find(function (s) { return s.card === entry.target; });
      state.visible = entry.isIntersecting;
      sync(state);
    });
  }, { threshold: .05 }) : null;
  var resize = 'ResizeObserver' in window ? new ResizeObserver(function (entries) {
    entries.forEach(function (entry) {
      var state = states.find(function (s) { return s.card === entry.target; });
      measure(state);
    });
  }) : null;
  states.forEach(function (state) {
    state.visible = !observer;
    if (observer) observer.observe(state.card);
    if (resize) resize.observe(state.card);
    state.img.addEventListener('load', function () { measure(state); });
    ['focusin'].forEach(function (event) {
      state.card.addEventListener(event, function () { state.held = true; sync(state); });
    });
    ['focusout'].forEach(function (event) {
      state.card.addEventListener(event, function () {
        state.held = state.card.contains(document.activeElement);
        sync(state);
      });
    });
    measure(state);
  });
  function preference() {
    button.hidden = false;
    states.forEach(measure);
  }
  button.addEventListener('click', function () {
    paused = !paused;
    button.setAttribute('aria-pressed', String(paused));
    button.textContent = window.FjeliaI18n ? window.FjeliaI18n.t(paused ? 'resume' : 't022') : (paused ? 'Resume previews' : 'Pause previews');
    document.dispatchEvent(new CustomEvent('fjelia-preview-pause', { detail: { paused: paused } }));
    states.forEach(sync);
  });
  reduced.addEventListener('change', preference);
  document.addEventListener('visibilitychange', function () { states.forEach(sync); });
  new MutationObserver(function () { states.forEach(sync); }).observe(document.body, { attributes: true, attributeFilter: ['class'] });
  if (!resize) window.addEventListener('resize', function () { states.forEach(measure); });
  preference();
})();

/* Edited screen recordings autoplay only while visible. */
(function () {
  'use strict';
  var paused = false;
  var states = Array.from(document.querySelectorAll('.app-preview')).map(function (video) {
    video.muted = true;
    video.defaultMuted = true;
    video.playsInline = true;
    var state = { video: video, visible: false, failed: false };
    function showFallback() {
      state.failed = true;
      video.pause();
      video.hidden = true;
      var fallback = video.parentElement.querySelector('.video-fallback');
      if (fallback) fallback.hidden = false;
    }
    state.showFallback = showFallback;
    video.addEventListener('error', showFallback);
    var sources = video.querySelectorAll('source');
    if (sources.length) sources[sources.length - 1].addEventListener('error', showFallback);
    return state;
  });
  function sync(state) {
    var allowed = !state.failed && state.visible && !document.hidden && !paused &&
      !document.body.classList.contains('dialog-open');
    state.video.autoplay = allowed;
    if (!allowed) { state.video.pause(); return; }
    if (!state.video.dataset.loaded) {
      state.video.querySelectorAll('source[data-src]').forEach(function (source) { source.src = source.dataset.src; });
      state.video.dataset.loaded = 'true';
      state.video.load();
    }
    var result = state.video.play();
    if (result && result.catch) result.catch(function (error) {
      state.video.dataset.playbackError = error.name;
      // A browser may block autoplay. Keep the poster and offer native play.
      if (error.name === 'NotAllowedError') state.video.controls = true;
      if (error.name === 'NotSupportedError') state.showFallback();
    });
  }
  var observer = 'IntersectionObserver' in window ? new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      var state = states.find(function (s) { return s.video === entry.target; });
      state.visible = entry.isIntersecting && entry.intersectionRatio >= .15;
      sync(state);
    });
  }, { threshold: .15 }) : null;
  states.forEach(function (state) {
    var bounds = state.video.getBoundingClientRect();
    state.visible = bounds.bottom > 0 && bounds.top < window.innerHeight;
    sync(state);
    if (observer) observer.observe(state.video);
  });
  document.addEventListener('fjelia-preview-pause', function (event) {
    paused = event.detail.paused;
    states.forEach(sync);
  });
  document.addEventListener('visibilitychange', function () { states.forEach(sync); });
  new MutationObserver(function () { states.forEach(sync); }).observe(document.body, { attributes: true, attributeFilter: ['class'] });
})();
