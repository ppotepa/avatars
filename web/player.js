'use strict';

window.addEventListener('DOMContentLoaded', () => {
  const preview = document.getElementById('avatar-preview');
  const playButton = document.getElementById('animate-button');
  const trackSelect = document.getElementById('animation-track');
  const frameCountSelect = document.getElementById('animation-frames');
  const speedSelect = document.getElementById('playback-speed');
  const loopInput = document.getElementById('animation-loop');
  const scrubber = document.getElementById('animation-scrubber');
  const positionOutput = document.getElementById('animation-position');
  const timeOutput = document.getElementById('animation-time');
  const playerTitle = document.getElementById('animation-player-title');
  const resolutionOutput = document.getElementById('resolution-value');
  const resolutionSelect = document.getElementById('quick-resolution');
  const resolutionButtons = [...document.querySelectorAll('[data-resolution]')];
  const zoomSelect = document.getElementById('preview-zoom');

  const player = {
    status: 'stopped',
    timer: null,
    frames: [],
    index: 0,
    cacheKey: '',
    loadToken: 0,
  };

  function frameCount() {
    return Math.max(1, Number(frameCountSelect.value || 16));
  }

  function frameDuration() {
    return Math.max(16, Number(speedSelect.value || 140));
  }

  function formatTime(milliseconds) {
    const totalHundredths = Math.floor(milliseconds / 10);
    const minutes = Math.floor(totalHundredths / 6000);
    const seconds = Math.floor(totalHundredths / 100) % 60;
    const hundredths = totalHundredths % 100;
    return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(hundredths).padStart(2, '0')}`;
  }

  function updateReadout() {
    const count = frameCount();
    player.index = Math.max(0, Math.min(count - 1, player.index));
    scrubber.max = String(count - 1);
    scrubber.value = String(player.index);
    positionOutput.textContent = `${String(player.index + 1).padStart(2, '0')}/${String(count).padStart(2, '0')}`;
    timeOutput.textContent = formatTime(player.index * frameDuration());
    playerTitle.textContent = player.status === 'loading' ? 'LOADING' : 'PLAYER';
  }

  function updatePlayButton() {
    const playing = player.status === 'playing';
    playButton.setAttribute('aria-pressed', String(playing));
    playButton.setAttribute('aria-label', playing ? 'Wstrzymaj' : 'Odtwórz');
    playButton.title = playing ? 'Wstrzymaj' : 'Odtwórz';
    playButton.disabled = player.status === 'loading';
  }

  function setStatus(status) {
    player.status = status;
    updatePlayButton();
    updateReadout();
  }

  function clearTimer() {
    if (player.timer) clearInterval(player.timer);
    player.timer = null;
    if (state.animationTimer) clearInterval(state.animationTimer);
    state.animationTimer = null;
  }

  function pause() {
    clearTimer();
    if (player.status !== 'loading') setStatus('paused');
  }

  function invalidate() {
    clearTimer();
    player.frames = [];
    player.cacheKey = '';
    player.loadToken++;
    if (player.status !== 'loading') setStatus('stopped');
  }

  function cloneRequest() {
    return typeof structuredClone === 'function'
      ? structuredClone(state.request)
      : JSON.parse(JSON.stringify(state.request));
  }

  function requestForTrack() {
    const request = cloneRequest();
    request.overrides = { ...(request.overrides || {}) };
    request.rendering = { ...(request.rendering || {}) };
    const track = trackSelect.value;
    if (track === 'idle') {
      Object.assign(request.overrides, {
        'v4.animation': 'idle',
        'v4.faceAnimation': 'none',
      });
    } else if (track === 'talk') {
      Object.assign(request.overrides, {
        'v4.faceAnimation': 'talk',
        'v4.mouthMotionStyle': 'talkNormal',
      });
    } else if (track === 'laugh') {
      Object.assign(request.overrides, {
        'v4.expression': 'laugh',
        'v4.eyeExpression': 'laughing',
        'v4.mouthExpression': 'laughOpen',
        'v4.faceAnimation': 'laughing',
      });
    } else if (track === 'storm') {
      Object.assign(request.overrides, {
        'v4.weather': 'heavyRain',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 2,
        'v4.ambientOverlay': 'stormClouds',
        'v4.backgroundEvent': 'lightningBranch',
        'v4.eventFrequency': 2,
        'v4.eventIntensity': 5,
      });
      request.rendering.animateBackground = true;
    } else if (track === 'fire') {
      Object.assign(request.overrides, {
        'v4.backFlames': 'hellfire',
        'v4.flameHeight': 7,
        'v4.flameIntensity': 6,
        'v4.flameFlicker': 5,
        'v4.backgroundEvent': 'fireBurst',
        'v4.eventFrequency': 2,
        'v4.eventIntensity': 5,
      });
      request.rendering.animateBackground = true;
    }
    return request;
  }

  function clipKey(request) {
    return JSON.stringify({
      request,
      track: trackSelect.value,
      frameCount: frameCount(),
    });
  }

  async function mapLimit(count, limit, task) {
    const output = new Array(count);
    let cursor = 0;
    async function worker() {
      while (cursor < count) {
        const index = cursor++;
        output[index] = await task(index);
      }
    }
    await Promise.all(Array.from({ length: Math.min(limit, count) }, worker));
    return output;
  }

  async function ensureClip() {
    if (!state.request) return false;
    const baseRequest = requestForTrack();
    const key = clipKey(baseRequest);
    if (player.frames.length === frameCount() && player.cacheKey === key) return true;

    const token = ++player.loadToken;
    clearTimer();
    setStatus('loading');
    try {
      const frames = await mapLimit(frameCount(), 4, async index => {
        const request = typeof structuredClone === 'function'
          ? structuredClone(baseRequest)
          : JSON.parse(JSON.stringify(baseRequest));
        request.phase = index;
        return apiJson('/api/avatar', {
          method: 'POST',
          body: JSON.stringify({ request, includePixels: false, svgScale: 1 }),
        });
      });
      if (token !== player.loadToken) return false;
      player.frames = frames;
      player.cacheKey = key;
      player.index = Math.min(player.index, frames.length - 1);
      setStatus('paused');
      renderFrame(player.index);
      return true;
    } catch (error) {
      if (token === player.loadToken) {
        player.frames = [];
        player.cacheKey = '';
        setStatus('error');
        showToast(`Nie udało się przygotować klipu: ${error.message}`, true);
      }
      return false;
    }
  }

  function renderFrame(index) {
    const count = frameCount();
    player.index = Math.max(0, Math.min(count - 1, Number(index)));
    const frame = player.frames[player.index];
    if (frame?.svg) preview.innerHTML = frame.svg;
    updateReadout();
  }

  async function seek(index) {
    pause();
    if (await ensureClip()) renderFrame(index);
  }

  async function play() {
    if (player.status === 'playing') {
      pause();
      return;
    }
    if (!(await ensureClip())) return;
    clearTimer();
    setStatus('playing');
    player.timer = setInterval(() => {
      const last = frameCount() - 1;
      if (player.index >= last) {
        if (loopInput.checked) {
          renderFrame(0);
        } else {
          clearTimer();
          setStatus('paused');
        }
        return;
      }
      renderFrame(player.index + 1);
    }, frameDuration());
  }

  function stop() {
    clearTimer();
    player.index = 0;
    setStatus('stopped');
    if (player.frames.length) renderFrame(0);
    else if (state.response?.svg) preview.innerHTML = state.response.svg;
  }

  function syncResolution() {
    const resolution = Number(state.request?.rendering?.size || resolutionSelect.value || 48);
    resolutionSelect.value = String(resolution);
    resolutionOutput.textContent = `${resolution} × ${resolution}`;
    for (const button of resolutionButtons) {
      button.setAttribute('aria-pressed', String(Number(button.dataset.resolution) === resolution));
    }
    applyZoom();
  }

  function applyZoom() {
    const zoom = zoomSelect.value;
    const resolution = Number(state.request?.rendering?.size || resolutionSelect.value || 48);
    preview.dataset.previewZoom = zoom;
    if (zoom === 'fit') {
      preview.style.removeProperty('--preview-native-size');
    } else {
      preview.style.setProperty('--preview-native-size', `${resolution * Number(zoom)}px`);
    }
  }

  playButton.addEventListener('click', event => {
    event.preventDefault();
    event.stopImmediatePropagation();
    void play();
  }, { capture: true });

  document.getElementById('animation-stop-button').addEventListener('click', stop);
  document.getElementById('frame-start-button').addEventListener('click', () => void seek(0));
  document.getElementById('frame-rewind-button').addEventListener('click', () => void seek(player.index - 4));
  document.getElementById('frame-previous-button').addEventListener('click', () => void seek(player.index - 1));
  document.getElementById('frame-next-button').addEventListener('click', () => void seek(player.index + 1));
  document.getElementById('frame-forward-button').addEventListener('click', () => void seek(player.index + 4));
  document.getElementById('frame-end-button').addEventListener('click', () => void seek(frameCount() - 1));

  scrubber.addEventListener('input', () => {
    pause();
    player.index = Number(scrubber.value);
    if (player.frames.length) renderFrame(player.index);
    else updateReadout();
  });
  scrubber.addEventListener('change', () => void seek(Number(scrubber.value)));

  frameCountSelect.addEventListener('change', () => {
    invalidate();
    player.index = 0;
    updateReadout();
  });
  trackSelect.addEventListener('change', () => {
    invalidate();
    player.index = 0;
    updateReadout();
  });
  speedSelect.addEventListener('change', () => {
    const wasPlaying = player.status === 'playing';
    pause();
    updateReadout();
    if (wasPlaying) void play();
  });
  zoomSelect.addEventListener('change', applyZoom);

  for (const button of resolutionButtons) {
    button.addEventListener('click', () => {
      const resolution = Number(button.dataset.resolution);
      stop();
      invalidate();
      resolutionSelect.value = String(resolution);
      resolutionOutput.textContent = `${resolution} × ${resolution}`;
      for (const candidate of resolutionButtons) {
        candidate.setAttribute('aria-pressed', String(candidate === button));
      }
      applyZoom();
      queueRender([{ op: 'set', id: 'rendering.size', value: resolution }], true);
    });
  }

  document.addEventListener('keydown', event => {
    const tag = document.activeElement?.tagName;
    if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') return;
    if (event.code === 'Space') {
      event.preventDefault();
      void play();
    } else if (event.code === 'ArrowLeft') {
      event.preventDefault();
      void seek(player.index - (event.shiftKey ? 4 : 1));
    } else if (event.code === 'ArrowRight') {
      event.preventDefault();
      void seek(player.index + (event.shiftKey ? 4 : 1));
    } else if (event.code === 'Home') {
      event.preventDefault();
      void seek(0);
    } else if (event.code === 'End') {
      event.preventDefault();
      void seek(frameCount() - 1);
    }
  });

  for (const eventName of ['change', 'input']) {
    document.addEventListener(eventName, event => {
      if (event.target.closest('.media-deck') || event.target.closest('.preview-controls')) return;
      if (player.status === 'playing') pause();
      player.cacheKey = '';
    }, { capture: true });
  }

  function waitForInitialRequest() {
    if (state.request) {
      syncResolution();
      updateReadout();
      updatePlayButton();
      return;
    }
    setTimeout(waitForInitialRequest, 30);
  }

  window.avatarPlayer = { play, pause, stop, seek, invalidate, syncResolution };
  waitForInitialRequest();
});
