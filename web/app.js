'use strict';

const state = {
  schema: null,
  request: null,
  response: null,
  pendingActions: [],
  rendering: false,
  renderTimer: null,
  activeGroup: 'all',
  search: '',
  changedOnly: false,
};

const fieldViews = new Map();
const globalViews = new Map();
const categoryViews = new Map();

const elements = {};

window.addEventListener('DOMContentLoaded', bootstrap);

async function bootstrap() {
  bindElements();
  bindStaticActions();
  try {
    const [schema, defaultRequest] = await Promise.all([
      apiJson('/api/catalog'),
      apiJson('/api/default-request'),
    ]);
    state.schema = schema;
    state.request = defaultRequest;
    renderWholePresets();
    renderGlobalFields();
    renderGroupTabs();
    renderParameterCategories();
    setConnection('Połączono', 'online');
    queueRender([], true);
  } catch (error) {
    setConnection('Błąd połączenia', 'error');
    showToast(error.message, true);
  }
}

function bindElements() {
  const ids = [
    'connection-status', 'avatar-preview', 'avatar-status', 'request-json',
    'generate-button', 'new-seed-button', 'reset-overrides-button',
    'reset-locks-button', 'export-request-button', 'export-result-button',
    'download-svg-button', 'download-png-button', 'save-server-button',
    'import-request-button', 'import-request-file', 'whole-preset',
    'apply-whole-preset-button', 'global-fields', 'property-search',
    'changed-only', 'group-tabs', 'parameter-categories', 'toast',
  ];
  for (const id of ids) elements[id] = document.getElementById(id);
}

function bindStaticActions() {
  elements['generate-button'].addEventListener('click', () => queueRender([], true));
  elements['new-seed-button'].addEventListener('click', () => {
    queueRender([{ op: 'set', id: 'request.seed', value: randomSeed() }], true);
  });
  elements['reset-overrides-button'].addEventListener('click', () => {
    queueRender([{ op: 'resetOverrides' }], true);
  });
  elements['reset-locks-button'].addEventListener('click', () => {
    queueRender([{ op: 'resetLocks' }], true);
  });
  elements['apply-whole-preset-button'].addEventListener('click', () => {
    const preset = elements['whole-preset'].value;
    if (preset) queueRender([{ op: 'wholePreset', preset }], true);
  });
  elements['property-search'].addEventListener('input', event => {
    state.search = event.target.value.trim().toLocaleLowerCase('pl');
    applyFilters();
  });
  elements['changed-only'].addEventListener('change', event => {
    state.changedOnly = event.target.checked;
    applyFilters();
  });
  elements['export-request-button'].addEventListener('click', async () => {
    await ensureIdle();
    downloadText('request.json', JSON.stringify(state.request, null, 2), 'application/json');
  });
  elements['export-result-button'].addEventListener('click', async () => {
    await ensureIdle();
    if (!state.response) return;
    downloadText('avatar.json', JSON.stringify(state.response.result, null, 2), 'application/json');
  });
  elements['download-svg-button'].addEventListener('click', () => downloadExport('/api/export/svg', 'svg'));
  elements['download-png-button'].addEventListener('click', () => downloadExport('/api/export/png', 'png'));
  elements['save-server-button'].addEventListener('click', saveOnServer);
  elements['import-request-button'].addEventListener('click', () => elements['import-request-file'].click());
  elements['import-request-file'].addEventListener('change', importRequest);
}

function renderWholePresets() {
  const select = elements['whole-preset'];
  select.replaceChildren(new Option('Wybierz preset…', ''));
  for (const [id, preset] of Object.entries(state.schema.wholePresets || {})) {
    select.add(new Option(preset.label || id, id));
  }
}

function renderGlobalFields() {
  const container = elements['global-fields'];
  container.replaceChildren();
  globalViews.clear();
  for (const binding of state.schema.requestFields) {
    const card = document.createElement('label');
    card.className = 'global-field';
    card.dataset.fieldId = binding.id;

    const heading = document.createElement('span');
    heading.className = 'field-label';
    heading.innerHTML = `<span>${escapeHtml(binding.label)}</span><span class="field-id">${escapeHtml(binding.id)}</span>`;
    card.append(heading);

    const control = createControl(binding, action => queueRender([action]));
    card.append(control.root);
    container.append(card);
    globalViews.set(binding.id, { card, ...control, binding });
  }
}

function renderGroupTabs() {
  const tabs = elements['group-tabs'];
  tabs.replaceChildren();
  const groups = [{ id: 'all', label: 'Wszystkie' }, ...(state.schema.groups || []).filter(group => group.id !== 'global')];
  for (const group of groups) {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = group.label;
    button.dataset.group = group.id;
    button.classList.toggle('active', group.id === state.activeGroup);
    button.addEventListener('click', () => {
      state.activeGroup = group.id;
      for (const tab of tabs.querySelectorAll('button')) {
        tab.classList.toggle('active', tab.dataset.group === group.id);
      }
      applyFilters();
    });
    tabs.append(button);
  }
}

function renderParameterCategories() {
  const container = elements['parameter-categories'];
  container.replaceChildren();
  fieldViews.clear();
  categoryViews.clear();

  for (const category of state.schema.categories) {
    const details = document.createElement('details');
    details.className = 'category-card';
    details.dataset.category = category.id;
    details.dataset.group = category.group;

    const summary = document.createElement('summary');
    const summaryContent = document.createElement('div');
    summaryContent.className = 'category-summary';
    summaryContent.innerHTML = `
      <span class="category-title">
        <strong>${escapeHtml(category.label)}</strong>
        <span class="field-id">${escapeHtml(category.id)}</span>
      </span>
      <span class="category-count">${category.fields.length} pól</span>`;
    summary.append(summaryContent);
    details.append(summary);

    const actions = document.createElement('div');
    actions.className = 'category-actions';
    const presetSelect = document.createElement('select');
    presetSelect.append(new Option('Preset kategorii…', ''));
    for (const presetId of Object.keys(category.presets || {})) {
      presetSelect.add(new Option(presetId, presetId));
    }
    const applyPreset = smallButton('Zastosuj', () => {
      if (!presetSelect.value) return;
      queueRender([{ op: 'categoryPreset', category: category.id, preset: presetSelect.value }], true);
    });
    const reroll = smallButton('Reroll', () => {
      queueRender([{ op: 'rerollCategory', category: category.id }], true);
    });
    const reset = smallButton('Auto całość', () => {
      queueRender([{ op: 'resetCategory', category: category.id }], true);
    });
    const lock = smallButton('Zablokuj kategorię', () => {
      const locked = Boolean(state.request?.lockedCategories?.[category.id]);
      queueRender([{ op: locked ? 'unlockCategory' : 'lockCategory', category: category.id }], true);
    });
    actions.append(presetSelect, applyPreset, reroll, reset, lock);
    details.append(actions);

    const fields = document.createElement('div');
    fields.className = 'category-fields';
    for (const binding of category.fields) {
      const row = document.createElement('div');
      row.className = 'property-row';
      row.dataset.fieldId = binding.id;
      row.dataset.search = `${binding.id} ${binding.label} ${category.id} ${category.label}`.toLocaleLowerCase('pl');

      const meta = document.createElement('div');
      meta.className = 'property-meta';
      meta.innerHTML = `
        <span class="property-name">${escapeHtml(binding.label)}</span>
        <span class="field-id">${escapeHtml(binding.id)}</span>
        <span class="property-source"></span>`;

      const controls = document.createElement('div');
      controls.className = 'property-controls';
      const control = createControl(binding, action => queueRender([action]));
      controls.append(control.root);

      const buttons = document.createElement('div');
      buttons.className = 'property-buttons';
      const resetButton = smallButton('Auto', () => queueRender([{ op: 'reset', id: binding.id }]));
      const lockButton = smallButton('Zablokuj', () => {
        const property = state.response?.properties?.[binding.id];
        const op = property?.isLocked ? 'unlock' : 'lock';
        queueRender([{ op, id: binding.id }], true);
      });
      buttons.append(resetButton, lockButton);

      row.append(meta, controls, buttons);
      fields.append(row);
      fieldViews.set(binding.id, {
        row,
        meta,
        source: meta.querySelector('.property-source'),
        resetButton,
        lockButton,
        binding,
        category,
        ...control,
      });
    }
    details.append(fields);
    container.append(details);
    categoryViews.set(category.id, { details, actions, lock, category });
  }
}

function createControl(binding, onAction) {
  const root = document.createElement('div');
  let primary;
  let secondary = null;

  if (binding.kind === 'select') {
    primary = document.createElement('select');
    for (const option of binding.options || []) {
      primary.add(new Option(option.label, String(option.value)));
    }
    primary.addEventListener('change', () => onAction({ op: 'set', id: binding.id, value: primary.value }));
    root.append(primary);
  } else if (binding.kind === 'boolean') {
    primary = document.createElement('input');
    primary.type = 'checkbox';
    primary.addEventListener('change', () => onAction({ op: 'set', id: binding.id, value: primary.checked }));
    root.append(primary);
  } else if (binding.kind === 'range') {
    root.className = 'control-pair';
    primary = document.createElement('input');
    primary.type = 'range';
    primary.min = binding.min;
    primary.max = binding.max;
    primary.step = binding.step || 1;
    secondary = document.createElement('input');
    secondary.type = 'number';
    secondary.min = binding.min;
    secondary.max = binding.max;
    secondary.step = binding.step || 1;
    primary.addEventListener('input', () => {
      secondary.value = primary.value;
      onAction({ op: 'set', id: binding.id, value: Number(primary.value) });
    });
    secondary.addEventListener('change', () => {
      const value = clampNumber(Number(secondary.value), binding.min, binding.max);
      secondary.value = String(value);
      primary.value = String(value);
      onAction({ op: 'set', id: binding.id, value });
    });
    root.append(primary, secondary);
  } else {
    primary = document.createElement('input');
    primary.type = binding.kind === 'integer' ? 'number' : 'text';
    if (binding.min !== undefined) primary.min = binding.min;
    if (binding.max !== undefined) primary.max = binding.max;
    primary.step = binding.step || 1;
    const eventName = binding.kind === 'text' ? 'input' : 'change';
    primary.addEventListener(eventName, () => {
      const value = binding.kind === 'integer'
        ? clampNumber(Number(primary.value), binding.min, binding.max)
        : primary.value;
      onAction({ op: 'set', id: binding.id, value });
    });
    root.append(primary);
  }

  return { root, primary, secondary };
}

function syncUi() {
  if (!state.response) return;
  elements['avatar-preview'].innerHTML = state.response.svg;
  const validation = state.response.validation;
  const metrics = state.response.result.metrics;
  elements['avatar-status'].innerHTML = `
    <strong>${escapeHtml(state.response.imageHash)}</strong><br>
    ${validation.isValid ? 'Guard: OK' : `Guard: ${validation.hardViolationCount} błędów`} ·
    ${metrics.usedColorCount} kolorów · ${metrics.layerCount} warstw`;
  elements['request-json'].textContent = JSON.stringify(state.request, null, 2);

  for (const [id, view] of globalViews) {
    const property = state.response.properties[id];
    syncControl(view, property?.value);
  }

  for (const [id, view] of fieldViews) {
    const property = state.response.properties[id];
    if (!property) continue;
    syncControl(view, property.value);
    view.row.classList.toggle('overridden', property.isOverridden);
    view.row.classList.toggle('locked', property.isLocked);
    view.resetButton.disabled = !property.isOverridden;
    view.lockButton.textContent = property.isLocked ? 'Odblokuj' : 'Zablokuj';
    const sourceClass = property.isLocked ? 'locked-label' : property.isOverridden ? 'manual' : 'auto';
    const sourceText = property.isLocked
      ? `blokada: ${property.lockSource}`
      : property.isOverridden
        ? 'ręczne nadpisanie'
        : `auto: ${property.source}`;
    view.source.innerHTML = `<span class="${sourceClass}">${escapeHtml(sourceText)}</span> · wynik: ${escapeHtml(String(property.resolvedValue))}`;
  }

  for (const [id, view] of categoryViews) {
    const locked = Boolean(state.request.lockedCategories?.[id]);
    view.lock.textContent = locked ? 'Odblokuj kategorię' : 'Zablokuj kategorię';
  }
  applyFilters();
}

function syncControl(view, value) {
  if (value === undefined || value === null) return;
  const active = document.activeElement;
  if (view.primary.type === 'checkbox') {
    view.primary.checked = Boolean(value);
    return;
  }
  if (active !== view.primary) view.primary.value = String(value);
  if (view.secondary && active !== view.secondary) view.secondary.value = String(value);
}

function applyFilters() {
  if (!state.schema) return;
  for (const [categoryId, categoryView] of categoryViews) {
    const groupMatches = state.activeGroup === 'all' || categoryView.category.group === state.activeGroup;
    let visibleCount = 0;
    for (const field of categoryView.category.fields) {
      const view = fieldViews.get(field.id);
      const property = state.response?.properties?.[field.id];
      const searchMatches = !state.search || view.row.dataset.search.includes(state.search);
      const changedMatches = !state.changedOnly || property?.isOverridden || property?.isLocked;
      const visible = groupMatches && searchMatches && changedMatches;
      view.row.hidden = !visible;
      if (visible) visibleCount++;
    }
    const categoryTextMatches = !state.search || `${categoryId} ${categoryView.category.label}`.toLocaleLowerCase('pl').includes(state.search);
    const showCategory = groupMatches && (visibleCount > 0 || (categoryTextMatches && !state.changedOnly));
    categoryView.details.hidden = !showCategory;
    const count = categoryView.details.querySelector('.category-count');
    count.textContent = `${visibleCount}/${categoryView.category.fields.length} pól`;
    if (state.search && showCategory) categoryView.details.open = true;
  }
}

function queueRender(actions, immediate = false) {
  for (const action of actions) enqueueAction(action);
  clearTimeout(state.renderTimer);
  if (immediate) {
    void flushRender();
  } else {
    state.renderTimer = setTimeout(() => void flushRender(), 220);
  }
}

function enqueueAction(action) {
  if ((action.op === 'set' || action.op === 'reset') && action.id) {
    state.pendingActions = state.pendingActions.filter(existing => !(
      (existing.op === 'set' || existing.op === 'reset') && existing.id === action.id
    ));
  }
  state.pendingActions.push(action);
}

async function flushRender() {
  if (!state.request || state.rendering) {
    if (state.rendering) state.renderTimer = setTimeout(() => void flushRender(), 60);
    return;
  }
  const actions = state.pendingActions.splice(0);
  state.rendering = true;
  setConnection('Generowanie…', '');
  setButtonsDisabled(true);
  try {
    const response = await apiJson('/api/avatar', {
      method: 'POST',
      body: JSON.stringify({
        request: state.request,
        actions,
        includePixels: false,
        svgScale: 8,
      }),
    });
    state.request = response.request;
    state.response = response;
    syncUi();
    setConnection('Połączono', 'online');
  } catch (error) {
    setConnection('Błąd', 'error');
    showToast(error.message, true);
  } finally {
    state.rendering = false;
    setButtonsDisabled(false);
    if (state.pendingActions.length) state.renderTimer = setTimeout(() => void flushRender(), 20);
  }
}


async function ensureIdle() {
  clearTimeout(state.renderTimer);
  if (state.pendingActions.length && !state.rendering) await flushRender();
  while (state.rendering || state.pendingActions.length) {
    await new Promise(resolve => setTimeout(resolve, 30));
    if (state.pendingActions.length && !state.rendering) await flushRender();
  }
}

async function downloadExport(path, extension) {
  if (!state.request) return;
  try {
    await ensureIdle();
    const response = await fetch(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ request: state.request, scale: 8 }),
    });
    if (!response.ok) throw new Error(await responseError(response));
    const blob = await response.blob();
    downloadBlob(`avatar-${state.response?.imageHash || 'genome'}.${extension}`, blob);
  } catch (error) {
    showToast(error.message, true);
  }
}

async function saveOnServer() {
  if (!state.request) return;
  try {
    await ensureIdle();
    const result = await apiJson('/api/save', {
      method: 'POST',
      body: JSON.stringify({ request: state.request, scale: 8 }),
    });
    showToast(`Zapisano: ${result.directory}`);
  } catch (error) {
    showToast(error.message, true);
  }
}

async function importRequest(event) {
  const [file] = event.target.files;
  event.target.value = '';
  if (!file) return;
  try {
    const parsed = JSON.parse(await file.text());
    state.request = parsed.request || parsed;
    state.pendingActions = [];
    queueRender([], true);
  } catch (error) {
    showToast(`Nie udało się zaimportować JSON: ${error.message}`, true);
  }
}

async function apiJson(path, options = {}) {
  const response = await fetch(path, {
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
    ...options,
  });
  if (!response.ok) throw new Error(await responseError(response));
  return response.json();
}

async function responseError(response) {
  try {
    const body = await response.json();
    const field = body.field ? ` (${body.field})` : '';
    return `${body.error || 'Błąd'}${field}: ${body.message || response.statusText}`;
  } catch (_) {
    return `${response.status} ${response.statusText}`;
  }
}

function smallButton(label, onClick) {
  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = label;
  button.addEventListener('click', onClick);
  return button;
}

function randomSeed() {
  const values = new Uint32Array(3);
  crypto.getRandomValues(values);
  return `avatar-${Array.from(values, value => value.toString(36)).join('-')}`;
}

function clampNumber(value, min, max) {
  if (!Number.isFinite(value)) return Number(min ?? 0);
  if (min !== undefined) value = Math.max(Number(min), value);
  if (max !== undefined) value = Math.min(Number(max), value);
  return Math.trunc(value);
}

function downloadText(name, text, type) {
  downloadBlob(name, new Blob([text], { type }));
}

function downloadBlob(name, blob) {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = name;
  document.body.append(anchor);
  anchor.click();
  anchor.remove();
  setTimeout(() => URL.revokeObjectURL(url), 500);
}

function setConnection(text, className) {
  elements['connection-status'].textContent = text;
  elements['connection-status'].className = `connection-status ${className}`.trim();
}

function setButtonsDisabled(disabled) {
  elements['generate-button'].disabled = disabled;
}

let toastTimer;
function showToast(message, error = false) {
  clearTimeout(toastTimer);
  elements.toast.textContent = message;
  elements.toast.className = `toast visible${error ? ' error' : ''}`;
  toastTimer = setTimeout(() => { elements.toast.className = 'toast'; }, 4200);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
