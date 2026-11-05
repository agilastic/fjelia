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
  document.addEventListener('click', function (event) {
      var link = event.target.closest('.screen-link, .weather-link, .plan-capture-link, .feature-capture, .story-capture');
      if (!link) return;
      if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      trigger = link;
      image.src = link.href;
      image.alt = link.querySelector('img').alt;
      caption.textContent = link.dataset.caption || image.alt;
      dialog.showModal();
      document.body.classList.add('dialog-open');
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

/* Native scrolling drives one stationary device through the product story. */
(function () {
  'use strict';
  var story = document.querySelector('.product-story');
  var stage = document.querySelector('.story-stage');
  var chapters = Array.from(document.querySelectorAll('[data-story-chapter]'));
  if (!story || !stage || !chapters.length || !('IntersectionObserver' in window)) return;
  var capture = stage.querySelector('.story-capture');
  var screen = capture.querySelector('img');
  var links = Array.from(stage.querySelectorAll('[data-story-nav]'));
  var index = stage.querySelector('.story-stage-index');
  var thresholdPicker = document.querySelector('.threshold-view-picker');
  var wide = window.matchMedia('(min-width: 1051px)');
  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  var active = '';
  var thresholdView = 'run';
  var pending = null;

  function sourceLink() {
    if (active === 'ai') return document.querySelector('#ai .feature-capture');
    if (active === 'thresholds') return document.querySelectorAll('#thresholds .feature-capture')[thresholdView === 'bike' ? 1 : 0];
    return document.querySelector('#plan .plan-view:not([hidden]) .plan-capture-link') || document.querySelector('#plan .plan-capture-link');
  }

  function updateScreen() {
    var source = sourceLink();
    if (!source) return;
    var sourceImage = source.querySelector('img');
    var changed = screen.getAttribute('src') !== sourceImage.getAttribute('src');
    capture.href = source.href;
    capture.dataset.caption = source.dataset.caption || sourceImage.alt;
    capture.setAttribute('aria-label', (window.FjeliaI18n ? window.FjeliaI18n.t('enlarge') : 'Enlarge screenshot:') + ' ' + capture.dataset.caption);
    screen.alt = sourceImage.alt;
    screen.src = sourceImage.getAttribute('src');
    var srcset = sourceImage.getAttribute('srcset');
    if (srcset) screen.srcset = srcset;
    else screen.removeAttribute('srcset');
    stage.dataset.storyFrame = active === 'thresholds' ? thresholdView : active;
    if (changed && !reduced.matches && screen.animate) {
      screen.getAnimations().forEach(function (animation) { animation.cancel(); });
      screen.animate([{ opacity: .45, transform: 'translateY(7px)' }, { opacity: 1, transform: 'none' }], { duration: 380, easing: 'cubic-bezier(.2,.7,.2,1)' });
    }
  }

  function choose(name) {
    if (active === name) return;
    active = name;
    stage.dataset.storyActive = name;
    chapters.forEach(function (chapter, chapterIndex) {
      var selected = chapter.dataset.storyChapter === name;
      chapter.classList.toggle('is-story-active', selected);
      if (selected) index.textContent = '0' + (chapterIndex + 1) + ' / 03';
    });
    links.forEach(function (link) {
      if (link.dataset.storyNav === name) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    });
    updateScreen();
  }

  function measure() {
    pending = null;
    var root = document.documentElement;
    var distance = root.scrollHeight - innerHeight;
    root.style.setProperty('--page-progress', distance > 0 ? Math.min(1, scrollY / distance) : 0);
    var hero = document.querySelector('.product-hero');
    if (hero && !reduced.matches) hero.style.setProperty('--hero-progress', Math.min(1, Math.max(0, scrollY / hero.offsetHeight)));
    if (!wide.matches) return;
    var next = chapters[0].dataset.storyChapter;
    var line = innerHeight * .48;
    chapters.forEach(function (chapter) {
      if (chapter.getBoundingClientRect().top <= line) next = chapter.dataset.storyChapter;
    });
    choose(next);
  }
  function schedule() {
    if (pending === null) pending = requestAnimationFrame(measure);
  }

  if (thresholdPicker) {
    thresholdPicker.hidden = false;
    thresholdPicker.addEventListener('click', function (event) {
      var button = event.target.closest('[data-threshold-view]');
      if (!button) return;
      thresholdView = button.dataset.thresholdView;
      thresholdPicker.querySelectorAll('[data-threshold-view]').forEach(function (item) { item.setAttribute('aria-pressed', String(item === button)); });
      choose('thresholds');
      updateScreen();
    });
  }
  var plans = document.querySelector('#plan .plan-captures');
  if (plans) new MutationObserver(function () { if (active === 'plan') updateScreen(); }).observe(plans, { attributes: true, subtree: true, attributeFilter: ['hidden'] });
  document.addEventListener('fjelia-language-change', function () { updateScreen(); schedule(); });
  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', schedule);
  reduced.addEventListener('change', schedule);
  stage.hidden = false;
  document.documentElement.classList.add('story-ready');
  choose('plan');
  schedule();
})();

/* One motion setting controls the previews, including the hero. */
(function () {
  'use strict';
  var buttons = Array.from(document.querySelectorAll('[data-motion-toggle]'));
  var paused = false;
  function update() {
    document.body.classList.toggle('previews-paused', paused);
    buttons.forEach(function (button) {
      var label = button.querySelector('[data-motion-label]') || button;
      var key = paused ? 'resume' : 't022';
      label.dataset.i18n = key;
      label.textContent = window.FjeliaI18n ? window.FjeliaI18n.t(key) : paused ? 'Resume previews' : 'Pause previews';
      button.setAttribute('aria-pressed', String(paused));
      button.setAttribute('aria-label', label.textContent);
      button.title = label.textContent;
    });
  }
  function change(value) {
    paused = value;
    update();
    document.dispatchEvent(new Event('fjelia-motion-change'));
  }
  buttons.forEach(function (button) {
    button.hidden = false;
    button.addEventListener('click', function () { change(!paused); });
  });
  document.addEventListener('fjelia-language-change', update);
  update();
})();

/* Gentle screenshot previews respect the system motion preference. */
(function () {
  'use strict';
  var cards = Array.from(document.querySelectorAll('.screen-link'));
  if (!cards.length || !Element.prototype.animate) return;
  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  var states = cards.map(function (card) {
    return { card: card, img: card.querySelector('img'), animation: null, visible: false, held: false };
  });
  function sync(state) {
    if (!state.animation) return;
    if (reduced.matches || document.hidden || !state.visible || state.held || document.body.classList.contains('dialog-open') || document.body.classList.contains('previews-paused')) state.animation.pause();
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
    state.card.addEventListener('mouseenter', function () { state.held = true; sync(state); });
    state.card.addEventListener('mouseleave', function () { state.held = state.card.contains(document.activeElement); sync(state); });
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
  reduced.addEventListener('change', function () { states.forEach(measure); });
  document.addEventListener('visibilitychange', function () { states.forEach(sync); });
  new MutationObserver(function () { states.forEach(sync); }).observe(document.body, { attributes: true, attributeFilter: ['class'] });
  if (!resize) window.addEventListener('resize', function () { states.forEach(measure); });
})();

/* The hero starts with its section; other recordings play when visible. */
(function () {
  'use strict';
  var states = Array.from(document.querySelectorAll('.app-preview')).map(function (video) {
    video.muted = true;
    video.defaultMuted = true;
    video.playsInline = true;
    video.controls = false;
    var hero = video.classList.contains('hero-preview');
    var state = {
      video: video,
      target: hero ? video.closest('.product-hero') || video : video,
      hero: hero,
      visible: false,
      failed: false
    };
    function showFallback() {
      // Empty lazy sources may emit errors before they have been assigned a URL.
      if (!video.dataset.loaded) return;
      state.failed = true;
      video.pause();
      video.hidden = true;
      var fallback = video.parentElement.querySelector('.video-fallback');
      if (fallback) fallback.hidden = false;
      video.dispatchEvent(new Event('fjelia-preview-fallback'));
    }
    state.showFallback = showFallback;
    video.addEventListener('error', showFallback);
    var sources = video.querySelectorAll('source');
    if (sources.length) sources[sources.length - 1].addEventListener('error', showFallback);
    return state;
  });
  function sync(state) {
    if (state.failed) return;
    if (state.visible && !state.video.dataset.loaded) {
      var lazySources = state.video.querySelectorAll('source[data-src]');
      lazySources.forEach(function (source) { source.src = source.dataset.src; });
      state.video.dataset.loaded = 'true';
      if (lazySources.length) state.video.load();
    }
    var paused = document.body.classList.contains('previews-paused');
    var allowed = state.visible && !document.hidden && !document.body.classList.contains('dialog-open') && !paused;
    state.video.autoplay = allowed;
    state.video.controls = paused || state.video.dataset.playbackError === 'NotAllowedError';
    if (!allowed) { state.video.pause(); return; }
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
      var state = states.find(function (s) { return s.target === entry.target; });
      state.visible = entry.isIntersecting && (state.hero || entry.intersectionRatio >= .15);
      sync(state);
    });
  }, { threshold: [0, .15] }) : null;
  states.forEach(function (state) {
    var bounds = state.target.getBoundingClientRect();
    state.visible = bounds.bottom > 0 && bounds.top < window.innerHeight;
    sync(state);
    if (observer) observer.observe(state.target);
  });
  document.addEventListener('visibilitychange', function () { states.forEach(sync); });
  document.addEventListener('fjelia-motion-change', function () { states.forEach(sync); });
  window.addEventListener('pageshow', function () { states.forEach(sync); });
  new MutationObserver(function () { states.forEach(sync); }).observe(document.body, { attributes: true, attributeFilter: ['class'] });
})();

/* The hero is a short real-app story with seekable chapters. */
(function () {
  'use strict';
  var video = document.querySelector('.hero-preview');
  var nav = document.querySelector('.hero-story-nav');
  if (!video || !nav) return;
  var buttons = Array.from(nav.querySelectorAll('[data-preview-time]'));
  var caption = document.querySelector('#hero-scene-caption');
  var scenes = [
    { start: 0, key: 'scene_goals' },
    { start: 2.333333, key: 'scene_workout' },
    { start: 5.083333, key: 'scene_graphs' },
    { start: 7.666667, key: 'scene_hrv' },
    { start: 10.833333, key: 'scene_coach' }
  ];
  function update() {
    var time = video.currentTime;
    buttons.forEach(function (button) {
      var start = Number(button.dataset.previewTime);
      var end = Number(button.dataset.previewEnd);
      var active = time >= start && time < end;
      if (active) button.setAttribute('aria-current', 'step');
      else button.removeAttribute('aria-current');
      button.style.setProperty('--chapter-progress', active ? String(Math.min(1, (time - start) / (end - start))) : '0');
    });
    if (caption && window.FjeliaI18n) {
      var scene = scenes[0];
      scenes.forEach(function (item) { if (time >= item.start) scene = item; });
      var key = video.hidden ? 'scene_graphs' : scene.key;
      caption.dataset.i18n = key;
      var label = window.FjeliaI18n.t(key);
      if (caption.textContent !== label) caption.textContent = label;
    }
  }
  nav.addEventListener('click', function (event) {
    var button = event.target.closest('[data-preview-time]');
    if (!button || video.hidden || video.error) return;
    video.currentTime = Number(button.dataset.previewTime) + .03;
    update();
  });
  ['timeupdate', 'seeked', 'loadedmetadata'].forEach(function (event) { video.addEventListener(event, update); });
  video.addEventListener('fjelia-preview-fallback', function () { nav.hidden = true; update(); });
  document.addEventListener('fjelia-language-change', update);
  nav.hidden = false;
  update();
})();

/* Plan previews keep rotating; manual choices restart the interval. */
(function () {
  'use strict';
  var showcase = document.querySelector('.season-showcase');
  if (!showcase) return;
  var picker = showcase.querySelector('.plan-view-picker');
  var buttons = Array.from(picker.querySelectorAll('[data-plan-view]'));
  var panels = Array.from(showcase.querySelectorAll('[data-plan-panel]'));
  var timer = null;
  var keyboardActive = false;
  var bounds = showcase.getBoundingClientRect();
  var visible = bounds.bottom > 0 && bounds.top < window.innerHeight;
  function schedule() {
    if (timer !== null) { clearTimeout(timer); timer = null; }
    var active = document.activeElement;
    var keyboardFocus = showcase.contains(active) && (keyboardActive || active.matches(':focus-visible'));
    if (!visible || keyboardFocus || document.hidden ||
      document.body.classList.contains('dialog-open') || document.body.classList.contains('previews-paused')) return;
    timer = setTimeout(function () {
      timer = null;
      var index = buttons.findIndex(function (button) { return button.getAttribute('aria-selected') === 'true'; });
      choose(buttons[(index + 1) % buttons.length].dataset.planView, false);
    }, 6500);
  }
  function choose(view, focus) {
    var selected = buttons.find(function (button) { return button.dataset.planView === view; });
    if (!selected) return;
    buttons.forEach(function (button) {
      var active = button === selected;
      button.setAttribute('aria-selected', String(active));
      button.tabIndex = active ? 0 : -1;
    });
    panels.forEach(function (panel) { panel.hidden = panel.dataset.planPanel !== view; });
    if (focus) selected.focus();
    schedule();
  }
  picker.setAttribute('role', 'tablist');
  buttons.forEach(function (button) { button.setAttribute('role', 'tab'); });
  panels.forEach(function (panel) {
    panel.setAttribute('role', 'tabpanel');
    panel.setAttribute('aria-labelledby', 'plan-tab-' + panel.dataset.planPanel);
  });
  picker.addEventListener('click', function (event) {
    var button = event.target.closest('[data-plan-view]');
    if (button) choose(button.dataset.planView, false);
  });
  picker.addEventListener('keydown', function (event) {
    var button = event.target.closest('[data-plan-view]');
    if (!button || !['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
    event.preventDefault();
    keyboardActive = true;
    var index = buttons.indexOf(button);
    index = event.key === 'Home' ? 0 : event.key === 'End' ? buttons.length - 1 : (index + (event.key === 'ArrowRight' ? 1 : -1) + buttons.length) % buttons.length;
    choose(buttons[index].dataset.planView, true);
  });
  function fragment() {
    var panel = panels.find(function (item) { return '#' + item.id === location.hash; });
    if (panel) choose(panel.dataset.planPanel, false);
  }
  choose('goals', false);
  fragment();
  window.addEventListener('hashchange', fragment);
  document.addEventListener('visibilitychange', schedule);
  function focusChanged() {
    requestAnimationFrame(function () {
      var active = document.activeElement;
      keyboardActive = showcase.contains(active) && (keyboardActive || active.matches(':focus-visible'));
      schedule();
    });
  }
  showcase.addEventListener('focusin', focusChanged);
  showcase.addEventListener('focusout', focusChanged);
  showcase.addEventListener('pointerdown', function () { keyboardActive = false; schedule(); });
  new MutationObserver(schedule).observe(document.body, { attributes: true, attributeFilter: ['class'] });
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (entries) {
      visible = entries[0].isIntersecting && entries[0].intersectionRatio >= .2;
      schedule();
    }, { threshold: .2 }).observe(showcase);
  }
  picker.hidden = false;
})();

/* Reveal small accents once; all content is visible without JavaScript. */
(function () {
  'use strict';
  if (!('IntersectionObserver' in window) || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-visible');
      observer.unobserve(entry.target);
    });
  }, { rootMargin: '0px 0px 40px 0px', threshold: .08 });
  document.querySelectorAll('.benefit-card, .ai-option, .latest-month, .install-steps li').forEach(function (item) {
    item.dataset.reveal = '';
    observer.observe(item);
  });
  document.documentElement.classList.add('reveal-ready');
})();

/* Mobile walkthroughs remain swipeable and readable without JavaScript. */
(function () {
  'use strict';
  var gallery = document.querySelector('.video-gallery');
  var nav = document.querySelector('.walkthrough-nav');
  if (!gallery || !nav) return;
  var cards = Array.from(gallery.querySelectorAll('.video-card'));
  var buttons = Array.from(nav.querySelectorAll('[data-demo-index]'));
  var frame = null;
  function update() {
    frame = null;
    var bounds = gallery.getBoundingClientRect();
    var center = bounds.left + bounds.width / 2;
    var selected = 0;
    var distance = Infinity;
    cards.forEach(function (card, index) {
      var box = card.getBoundingClientRect();
      var next = Math.abs(box.left + box.width / 2 - center);
      if (next < distance) { selected = index; distance = next; }
    });
    buttons.forEach(function (button, index) {
      if (index === selected) button.setAttribute('aria-current', 'true');
      else button.removeAttribute('aria-current');
    });
  }
  function choose(index) {
    var left = gallery.scrollLeft + cards[index].getBoundingClientRect().left - gallery.getBoundingClientRect().left - 2;
    gallery.scrollTo({ left: left, behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
  }
  nav.addEventListener('click', function (event) {
    var button = event.target.closest('[data-demo-index]');
    if (button) choose(Number(button.dataset.demoIndex));
  });
  nav.addEventListener('keydown', function (event) {
    var button = event.target.closest('[data-demo-index]');
    if (!button || !['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
    event.preventDefault();
    var index = Number(button.dataset.demoIndex);
    index = event.key === 'Home' ? 0 : event.key === 'End' ? buttons.length - 1 : (index + (event.key === 'ArrowRight' ? 1 : -1) + buttons.length) % buttons.length;
    buttons[index].focus();
    choose(index);
  });
  gallery.addEventListener('scroll', function () { if (!frame) frame = requestAnimationFrame(update); }, { passive: true });
  window.addEventListener('resize', update);
  document.addEventListener('fjelia-language-change', function () { requestAnimationFrame(update); });
  nav.hidden = false;
  update();
})();

/* Links to optional detail sections open their target before scrolling. */
(function () {
  'use strict';
  function reveal() {
    if (!location.hash) return;
    var target;
    try { target = document.getElementById(decodeURIComponent(location.hash.slice(1))); } catch (_) { return; }
    if (!target) return;
    var details = target.closest('details');
    if (details) details.open = true;
  }
  window.addEventListener('hashchange', reveal);
  reveal();
})();
