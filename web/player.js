'use strict';

window.addEventListener('DOMContentLoaded', () => {
  const resolutionSelect = document.getElementById('quick-resolution');
  const resolutionOutput = document.getElementById('resolution-value');
  const resolutionButtons = [...document.querySelectorAll('[data-resolution]')];
  const frameCountSelect = document.getElementById('animation-frames');
  const positionOutput = document.getElementById('animation-position');
  const playButton = document.getElementById('animate-button');
  const transport = document.querySelector('.player-transport');

  const stopButton = document.createElement('button');
  stopButton.id = 'animation-stop-button';
  stopButton.className = 'player-button';
  stopButton.type = 'button';
  stopButton.title = 'Zatrzymaj i wróć do pierwszej klatki';
  stopButton.setAttribute('aria-label', stopButton.title);
  stopButton.innerHTML = '<span aria-hidden="true">■</span>';
  transport.insertBefore(stopButton, document.getElementById('frame-next-button'));

  function frameCount() {
    return Math.max(1, Number(frameCountSelect.value || 16));
  }

  function currentPhase() {
    return Math.max(0, Math.min(frameCount() - 1, Number(state.request?.phase || 0)));
  }

  function stopPlayback(reset = false) {
    if (state.animationTimer) {
      clearInterval(state.animationTimer);
      state.animationTimer = null;
    }
    updatePlayButton();
    if (reset) setPhase(0);
  }

  function setPhase(phase) {
    const nextPhase = Math.max(0, Math.min(frameCount() - 1, Number(phase)));
    queueRender([{ op: 'set', id: 'request.phase', value: nextPhase }], true);
    updatePosition(nextPhase);
  }

  function updatePlayButton() {
    const playing = Boolean(state.animationTimer);
    playButton.innerHTML = `<span aria-hidden="true">${playing ? 'Ⅱ' : '▶'}</span>`;
    playButton.title = playing ? 'Wstrzymaj animację' : 'Odtwórz animację';
    playButton.setAttribute('aria-label', playButton.title);
    playButton.setAttribute('aria-pressed', String(playing));
  }

  function updatePosition(phase = currentPhase()) {
    positionOutput.textContent = `${phase + 1} / ${frameCount()}`;
  }

  function updateResolution() {
    const resolution = Number(state.request?.rendering?.size || resolutionSelect.value || 48);
    resolutionOutput.textContent = `${resolution} × ${resolution}`;
    for (const button of resolutionButtons) {
      button.setAttribute('aria-pressed', String(Number(button.dataset.resolution) === resolution));
    }
  }

  for (const button of resolutionButtons) {
    button.addEventListener('click', () => {
      const resolution = Number(button.dataset.resolution);
      resolutionSelect.value = String(resolution);
      resolutionSelect.dispatchEvent(new Event('change', { bubbles: true }));
      updateResolution();
    });
  }

  document.getElementById('frame-start-button').addEventListener('click', () => {
    stopPlayback();
    setPhase(0);
  });
  document.getElementById('frame-previous-button').addEventListener('click', () => {
    stopPlayback();
    setPhase(currentPhase() - 1);
  });
  document.getElementById('frame-next-button').addEventListener('click', () => {
    stopPlayback();
    setPhase(currentPhase() + 1);
  });
  document.getElementById('frame-end-button').addEventListener('click', () => {
    stopPlayback();
    setPhase(frameCount() - 1);
  });
  stopButton.addEventListener('click', () => stopPlayback(true));

  playButton.addEventListener('click', () => queueMicrotask(updatePlayButton));
  frameCountSelect.addEventListener('change', () => {
    if (currentPhase() >= frameCount()) setPhase(frameCount() - 1);
    updatePosition();
  });

  const statusObserver = new MutationObserver(() => {
    updateResolution();
    updatePosition();
    updatePlayButton();
  });
  statusObserver.observe(document.getElementById('avatar-status'), {
    childList: true,
    subtree: true,
    characterData: true,
  });

  const playObserver = new MutationObserver(updatePlayButton);
  playObserver.observe(playButton, { childList: true, subtree: true, characterData: true });

  updateResolution();
  updatePosition();
  updatePlayButton();
});
