'use strict';

const { h, render } = window.preact || {};
const { useCallback, useEffect, useMemo, useRef, useState } = window.preactHooks || {};

const FRAME_MS = 125;
const DEFAULT_ANIMATION = 'idle';

if (!h || !render || !useState) {
  document.getElementById('app').textContent = 'Nie udalo sie zaladowac Preact.';
} else {
  window.addEventListener('DOMContentLoaded', () => {
    render(h(App), document.getElementById('app'));
  });
}

function App() {
  const [schema, setSchema] = useState(null);
  const [request, setRequest] = useState(null);
  const [response, setResponse] = useState(null);
  const [bundle, setBundle] = useState(null);
  const [bundleAvatarKey, setBundleAvatarKey] = useState(null);
  const [selectedAnimationId, setSelectedAnimationId] = useState(DEFAULT_ANIMATION);
  const [playing, setPlaying] = useState(true);
  const [variantIndex, setVariantIndex] = useState(0);
  const [frameIndex, setFrameIndex] = useState(0);
  const [bundleLoading, setBundleLoading] = useState(false);
  const [connection, setConnection] = useState({ text: 'Laczenie...', tone: '' });
  const [activeGroup, setActiveGroup] = useState('all');
  const [search, setSearch] = useState('');
  const [changedOnly, setChangedOnly] = useState(false);
  const [rendering, setRendering] = useState(false);
  const [toast, setToast] = useState(null);

  const requestRef = useRef(null);
  const responseRef = useRef(null);
  const bundleRef = useRef(null);
  const bundleAvatarKeyRef = useRef(null);
  const selectedAnimationIdRef = useRef(DEFAULT_ANIMATION);
  const renderingRef = useRef(false);
  const pendingActionsRef = useRef([]);
  const renderTimerRef = useRef(null);
  const bundleControllerRef = useRef(null);
  const bundleRequestTokenRef = useRef(0);
  const clipCacheRef = useRef(new Map());
  const toastTimerRef = useRef(null);

  useEffect(() => { requestRef.current = request; }, [request]);
  useEffect(() => { responseRef.current = response; }, [response]);
  useEffect(() => { bundleRef.current = bundle; }, [bundle]);
  useEffect(() => { bundleAvatarKeyRef.current = bundleAvatarKey; }, [bundleAvatarKey]);
  useEffect(() => { selectedAnimationIdRef.current = selectedAnimationId; }, [selectedAnimationId]);
  useEffect(() => { renderingRef.current = rendering; }, [rendering]);

  const showToast = useCallback((message, error = false) => {
    clearTimeout(toastTimerRef.current);
    setToast({ message, error });
    toastTimerRef.current = setTimeout(() => setToast(null), 4200);
  }, []);

  const loadBundle = useCallback(async (nextRequest, avatarKey, animationId) => {
    if (!nextRequest || !avatarKey || !animationId) return;
    bundleControllerRef.current?.abort();
    const requestToken = bundleRequestTokenRef.current + 1;
    bundleRequestTokenRef.current = requestToken;
    const cacheKey = `${avatarKey}:${animationId}`;
    const cachedBundle = clipCacheRef.current.get(cacheKey);
    if (cachedBundle) {
      setBundle(cachedBundle);
      setBundleAvatarKey(avatarKey);
      setBundleLoading(false);
      setVariantIndex(0);
      setFrameIndex(0);
      return;
    }
    const controller = new AbortController();
    bundleControllerRef.current = controller;
    setBundle(null);
    setBundleAvatarKey(null);
    setBundleLoading(true);
    try {
      const nextBundle = await apiJson('/api/avatar-clip', {
        method: 'POST',
        body: JSON.stringify({
          request: nextRequest,
          animationId,
          svgScale: 8,
        }),
        signal: controller.signal,
      });
      const responseKey = responseRef.current?.imageHash || null;
      if (
        bundleControllerRef.current !== controller ||
        bundleRequestTokenRef.current !== requestToken ||
        responseKey !== avatarKey
      ) {
        return;
      }
      clipCacheRef.current.set(cacheKey, nextBundle);
      if (clipCacheRef.current.size > 32) {
        clipCacheRef.current.delete(clipCacheRef.current.keys().next().value);
      }
      setBundle(nextBundle);
      setBundleAvatarKey(avatarKey);
      setVariantIndex(0);
      setFrameIndex(0);
    } catch (error) {
      if (error.name !== 'AbortError') {
        setBundle(null);
        setBundleAvatarKey(null);
        showToast(`Bundle animacji: ${error.message}`, true);
      }
    } finally {
      if (bundleControllerRef.current === controller) {
        bundleControllerRef.current = null;
        setBundleLoading(false);
      }
    }
  }, [showToast]);

  const flushRender = useCallback(async () => {
    if (!requestRef.current || renderingRef.current) {
      if (renderingRef.current) {
        clearTimeout(renderTimerRef.current);
        renderTimerRef.current = setTimeout(() => { void flushRender(); }, 60);
      }
      return;
    }

    const actions = pendingActionsRef.current.splice(0);
    renderingRef.current = true;
    setRendering(true);
    setConnection({ text: 'Generowanie...', tone: '' });
    bundleControllerRef.current?.abort();
    setBundle(null);
    setBundleAvatarKey(null);
    setFrameIndex(0);
    setVariantIndex(0);

    try {
      const avatarResponse = await apiJson('/api/avatar', {
        method: 'POST',
        body: JSON.stringify({
          request: requestRef.current,
          actions,
          includePixels: false,
          svgScale: 8,
        }),
      });
      requestRef.current = avatarResponse.request;
      responseRef.current = avatarResponse;
      setRequest(avatarResponse.request);
      setResponse(avatarResponse);
      setConnection({ text: 'Polaczono', tone: 'online' });
      void loadBundle(
        avatarResponse.request,
        avatarResponse.imageHash,
        selectedAnimationIdRef.current || DEFAULT_ANIMATION,
      );
    } catch (error) {
      setConnection({ text: 'Blad', tone: 'error' });
      showToast(error.message, true);
    } finally {
      renderingRef.current = false;
      setRendering(false);
      if (pendingActionsRef.current.length) {
        clearTimeout(renderTimerRef.current);
        renderTimerRef.current = setTimeout(() => { void flushRender(); }, 20);
      }
    }
  }, [loadBundle, showToast]);

  const queueRender = useCallback((actions = [], immediate = false) => {
    for (const action of actions) enqueueAction(pendingActionsRef.current, action);
    clearTimeout(renderTimerRef.current);
    if (immediate) {
      void flushRender();
    } else {
      renderTimerRef.current = setTimeout(() => { void flushRender(); }, 180);
    }
  }, [flushRender]);

  const ensureIdle = useCallback(async () => {
    clearTimeout(renderTimerRef.current);
    if (pendingActionsRef.current.length && !renderingRef.current) await flushRender();
    while (renderingRef.current || pendingActionsRef.current.length) {
      await sleep(30);
      if (pendingActionsRef.current.length && !renderingRef.current) await flushRender();
    }
  }, [flushRender]);

  useEffect(() => {
    let cancelled = false;
    async function bootstrap() {
      try {
        const [catalog, defaultRequest] = await Promise.all([
          apiJson('/api/catalog'),
          apiJson('/api/default-request'),
        ]);
        if (cancelled) return;
        setSchema(catalog);
        requestRef.current = defaultRequest;
        setRequest(defaultRequest);
        setConnection({ text: 'Polaczono', tone: 'online' });
        pendingActionsRef.current = [];
        setTimeout(() => { if (!cancelled) void flushRender(); }, 0);
      } catch (error) {
        if (!cancelled) {
          setConnection({ text: 'Blad polaczenia', tone: 'error' });
          showToast(error.message, true);
        }
      }
    }
    void bootstrap();
    return () => {
      cancelled = true;
      clearTimeout(renderTimerRef.current);
      clearTimeout(toastTimerRef.current);
      bundleControllerRef.current?.abort();
    };
  }, [flushRender, showToast]);

  const activeAvatarKey = response?.imageHash || null;
  const activeBundle = bundleAvatarKey === activeAvatarKey ? bundle : null;
  const animationClips = activeBundle?.clips || [];
  const selectedClip = animationClips.find(clip => clip.id === selectedAnimationId) || animationClips[0] || null;
  const selectedVariant = selectedClip?.variants?.[variantIndex] || selectedClip?.variants?.[0] || null;
  const currentFrame = selectedVariant?.frames?.[frameIndex] || null;
  const availableAnimationOptions = useMemo(() => {
    const fields = (schema?.categories || []).flatMap(category => category.fields || []);
    const animationField = fields.find(field => field.id === 'v4.animation');
    return (animationField?.options || [])
      .filter(option => option.value !== 'none')
      .map(option => ({ value: option.value, label: option.label }));
  }, [schema]);

  useEffect(() => {
    if (!playing || !selectedVariant?.frames?.length) return undefined;
    const delay = selectedClip?.frameDurationMs || FRAME_MS;
    const timer = setTimeout(() => {
      setFrameIndex(previous => {
        const next = previous + 1;
        if (next < selectedVariant.frames.length) return next;
        if ((selectedClip?.variants?.length || 0) > 1) {
          setVariantIndex(previousVariant =>
            (previousVariant + 1) % selectedClip.variants.length);
        }
        return 0;
      });
    }, delay);
    return () => clearTimeout(timer);
  }, [playing, selectedClip, selectedVariant, frameIndex]);

  useEffect(() => {
    setFrameIndex(0);
    setVariantIndex(previous => {
      const max = selectedClip?.variants?.length || 0;
      return max === 0 ? 0 : Math.min(previous, max - 1);
    });
  }, [selectedAnimationId, selectedClip?.id]);

  const groups = useMemo(() => [
    { id: 'all', label: 'Wszystkie' },
    ...((schema?.groups || []).filter(group => group.id !== 'global')),
  ], [schema]);

  const filteredCategories = useMemo(() => {
    const term = search.trim().toLocaleLowerCase('pl');
    return (schema?.categories || []).map(category => {
      const fields = (category.fields || [])
        .filter(field => field.id !== 'v4.animation')
        .filter(field => {
          const property = response?.properties?.[field.id];
          const groupMatches = activeGroup === 'all' || category.group === activeGroup;
          const text = `${field.id} ${field.label} ${category.id} ${category.label}`.toLocaleLowerCase('pl');
          const searchMatches = !term || text.includes(term);
          const changedMatches = !changedOnly || property?.isOverridden || property?.isLocked;
          return groupMatches && searchMatches && changedMatches;
        });
      const categoryText = `${category.id} ${category.label}`.toLocaleLowerCase('pl');
      const showByCategory = !changedOnly && (!term || categoryText.includes(term));
      const groupMatches = activeGroup === 'all' || category.group === activeGroup;
      return {
        ...category,
        visibleFields: fields,
        hidden: !groupMatches || (fields.length === 0 && !showByCategory),
      };
    }).filter(category => !category.hidden);
  }, [activeGroup, changedOnly, response, schema, search]);

  if (!schema || !request) {
    return h('div', { class: 'boot-screen' }, 'Ladowanie edytora...');
  }

  return h('div', null, [
    h('header', { class: 'topbar' }, [
      h('div', null, [
        h('p', { class: 'eyebrow' }, 'avatar genome'),
        h('h1', null, 'Edytor awatara'),
      ]),
      h('div', { class: `connection-status ${connection.tone}`.trim(), 'aria-live': 'polite' }, connection.text),
    ]),
    h('main', { class: 'workspace' }, [
      h('aside', { class: 'preview-panel panel' }, [
        h(AvatarPlayer, {
          baseSvg: response?.svg || activeBundle?.baseSvg || '',
          bundle: activeBundle,
          clip: selectedClip,
          variant: selectedVariant,
          frame: currentFrame,
          selectedAnimationId,
          options: availableAnimationOptions,
          playing,
          loading: bundleLoading,
          onSelect: value => {
            selectedAnimationIdRef.current = value;
            setSelectedAnimationId(value);
            setFrameIndex(0);
            setVariantIndex(0);
            void loadBundle(requestRef.current, activeAvatarKey, value);
          },
          onPlay: () => setPlaying(true),
          onStop: () => setPlaying(false),
          onNext: () => {
            const values = availableAnimationOptions.map(option => option.value);
            if (!values.length) return;
            const index = values.indexOf(selectedAnimationId);
            const next = values[(index + 1 + values.length) % values.length];
            selectedAnimationIdRef.current = next;
            setSelectedAnimationId(next);
            setVariantIndex(0);
            setFrameIndex(0);
            setPlaying(true);
            void loadBundle(requestRef.current, activeAvatarKey, next);
          },
          onVariant: () => {
            const count = selectedClip?.variants?.length || 0;
            if (count < 2) return;
            setVariantIndex(previous => (previous + 1) % count);
            setFrameIndex(0);
          },
          profile: activeBundle?.profile,
          response,
        }),
        h(ActionPanel, {
          rendering,
          request,
          response,
          selectedAnimationId,
          schema,
          ensureIdle,
          queueRender,
          onImportRequest: nextRequest => {
            pendingActionsRef.current = [];
            requestRef.current = nextRequest;
            responseRef.current = null;
            setRequest(nextRequest);
            setResponse(null);
            setBundle(null);
            setBundleAvatarKey(null);
            setSelectedAnimationId(DEFAULT_ANIMATION);
            setVariantIndex(0);
            setFrameIndex(0);
            setTimeout(() => queueRender([], true), 0);
          },
          showToast,
        }),
        h(JsonInspector, { request }),
      ]),
      h('section', { class: 'editor-panel panel' }, [
        h(GlobalFields, {
          fields: (schema.requestFields || []).filter(field => field.id !== 'v4.animation'),
          response,
          queueRender,
        }),
        h('section', { class: 'section-block parameter-section' }, [
          h('div', { class: 'section-heading sticky-heading' }, [
            h('div', null, [
              h('p', { class: 'eyebrow' }, 'Parametry'),
              h('h2', null, 'Wlasciwosci awatara'),
            ]),
            h('div', { class: 'filters' }, [
              h('label', { class: 'search-field' }, [
                h('span', null, 'Szukaj'),
                h('input', {
                  type: 'search',
                  value: search,
                  placeholder: 'np. hair, oczy, armor',
                  onInput: event => setSearch(event.currentTarget.value),
                }),
              ]),
              h('label', { class: 'check-field' }, [
                h('input', {
                  type: 'checkbox',
                  checked: changedOnly,
                  onChange: event => setChangedOnly(event.currentTarget.checked),
                }),
                h('span', null, 'Tylko zmienione'),
              ]),
            ]),
          ]),
          h(GroupTabs, { groups, activeGroup, setActiveGroup }),
          h('div', { class: 'categories' }, filteredCategories.map(category => h(CategoryCard, {
            key: category.id,
            category,
            totalCount: (category.fields || []).filter(field => field.id !== 'v4.animation').length,
            response,
            request,
            queueRender,
          }))),
        ]),
      ]),
    ]),
    toast && h('div', { class: `toast visible${toast.error ? ' error' : ''}`, role: 'status', 'aria-live': 'polite' }, toast.message),
  ]);
}

function AvatarPlayer({
  baseSvg,
  bundle,
  clip,
  variant,
  frame,
  selectedAnimationId,
  options,
  playing,
  loading,
  onSelect,
  onPlay,
  onStop,
  onNext,
  onVariant,
  profile,
  response,
}) {
  const markup = frame?.svg || baseSvg;
  const status = response
    ? `${response.validation?.isValid ? 'Guard OK' : `Guard ${response.validation?.hardViolationCount || 0}`} / ${response.result?.metrics?.usedColorCount || 0} kolorow / ${response.result?.metrics?.layerCount || 0} warstw`
    : 'Generowanie...';
  const clipLabel = clip?.label || 'Animacja';
  const frameCount = variant?.frames?.length || 0;
  const variantCount = clip?.variants?.length || 0;
  const currentPhase = frame?.phase ?? requestPhase(response?.request);

  return h('section', { class: 'avatar-player', 'aria-label': 'Odtwarzacz awatara' }, [
    h('div', { class: 'animation-heading' }, [
      h('div', null, [
        h('p', { class: 'eyebrow' }, 'Player'),
        h('h2', null, 'Awatar'),
      ]),
      h('div', { class: `animation-indicator ${loading ? 'paused' : playing ? 'playing' : ''}`.trim() },
        loading ? 'Ladowanie' : playing ? 'Odtwarzanie' : 'Stop'),
    ]),
    h('div', { class: 'animation-player-screen' }, [
      h('div', { class: `avatar-preview animation-preview ${loading ? 'loading' : ''}`.trim(), 'aria-label': 'Podglad awatara' }, [
        markup
          ? h('div', { class: 'svg-stage', dangerouslySetInnerHTML: { __html: markup } })
          : h('span', null, 'Generowanie...'),
      ]),
    ]),
    h('div', { class: 'player-toolbar' }, [
      h('button', { type: 'button', disabled: loading || !clip, onClick: onPlay, title: 'Play' }, 'Play'),
      h('button', { type: 'button', disabled: loading || !clip, onClick: onStop, title: 'Stop' }, 'Stop'),
      h('button', { type: 'button', disabled: loading || !clip, onClick: onNext, title: 'Next' }, 'Next'),
      h('label', { class: 'animation-select-field' }, [
        h('span', null, 'Playlista'),
        h('select', {
          value: selectedAnimationId,
          onChange: event => onSelect(event.currentTarget.value),
        }, options.map(option => h('option', { key: option.value, value: option.value }, option.label))),
      ]),
    ]),
    h('div', { class: 'avatar-status' }, response
      ? [
          h('strong', null, response.imageHash),
          h('br'),
          status,
        ]
      : status),
    h('div', { class: 'animation-meta' }, [
      h('span', null, `Tryb: ${clipLabel}`),
      h('span', null, `Klatki: ${frameCount}`),
      h('span', null, `Faza: ${currentPhase}`),
      h('span', null, `${Math.round(1000 / (clip?.frameDurationMs || FRAME_MS))} FPS`),
      variantCount > 1 && h('button', { type: 'button', disabled: loading, onClick: onVariant }, `Wariant ${variantCount}`),
    ]),
    h('div', { class: 'player-hints' }, [
      bundle?.profile?.faceMostlyOccluded && h('span', { class: 'chip warning' }, 'adaptacja przy zaslonietej twarzy'),
      profile?.eyewearVisible && h('span', { class: 'chip' }, 'okulary aktywne'),
      profile?.faceMaskVisible && h('span', { class: 'chip' }, 'maska aktywna'),
      profile?.shoulderPropVisible && h('span', { class: 'chip' }, 'companion aktywny'),
      clip?.fallbackReason && h(
        'span',
        { class: 'chip info' },
        clip.fallbackReason.includes('Enhanced')
          ? 'emocja wzmocniona'
          : `adaptacja: ${clip.fallbackReason}`,
      ),
    ]),
  ]);
}

function ActionPanel({ rendering, request, response, selectedAnimationId, schema, ensureIdle, queueRender, onImportRequest, showToast }) {
  const [preset, setPreset] = useState('');
  const importRef = useRef(null);

  async function downloadExport(path, extension) {
    if (!request) return;
    try {
      await ensureIdle();
      const exportRequest = path.endsWith('/gif')
        ? {
            ...request,
            overrides: { ...(request.overrides || {}), 'v4.animation': selectedAnimationId || DEFAULT_ANIMATION },
          }
        : request;
      const exportResponse = await fetch(path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ request: exportRequest, scale: 8 }),
      });
      if (!exportResponse.ok) throw new Error(await responseError(exportResponse));
      downloadBlob(`avatar-${response?.imageHash || 'genome'}.${extension}`, await exportResponse.blob());
    } catch (error) {
      showToast(error.message, true);
    }
  }

  async function saveOnServer() {
    try {
      await ensureIdle();
      const result = await apiJson('/api/save', {
        method: 'POST',
        body: JSON.stringify({
          request,
          scale: 8,
          animationId: selectedAnimationId || DEFAULT_ANIMATION,
        }),
      });
      showToast(`Zapisano: ${result.directory}`);
    } catch (error) {
      showToast(error.message, true);
    }
  }

  async function importRequest(event) {
    const [file] = event.currentTarget.files;
    event.currentTarget.value = '';
    if (!file) return;
    try {
      const parsed = JSON.parse(await file.text());
      onImportRequest(parsed.request || parsed);
    } catch (error) {
      showToast(`Nie udalo sie zaimportowac JSON: ${error.message}`, true);
    }
  }

  return h('section', { class: 'actions-stack', 'aria-label': 'Akcje awatara' }, [
    h('div', { class: 'toolbar' }, [
      h('button', { type: 'button', class: 'primary', disabled: rendering, onClick: () => queueRender([], true) }, 'Generuj'),
      h('button', { type: 'button', disabled: rendering, onClick: () => queueRender([{ op: 'set', id: 'request.seed', value: randomSeed() }], true) }, 'Nowy seed'),
      h('button', { type: 'button', disabled: rendering, onClick: () => queueRender([{ op: 'resetOverrides' }], true) }, 'Reset nadpisan'),
      h('button', { type: 'button', disabled: rendering, onClick: () => queueRender([{ op: 'resetLocks' }], true) }, 'Reset blokad'),
    ]),
    h('div', { class: 'export-grid' }, [
      h('button', { type: 'button', onClick: () => downloadText('request.json', JSON.stringify(request, null, 2), 'application/json') }, 'Request JSON'),
      h('button', { type: 'button', disabled: !response, onClick: () => downloadText('avatar.json', JSON.stringify(response?.result, null, 2), 'application/json') }, 'Result JSON'),
      h('button', { type: 'button', onClick: () => { void downloadExport('/api/export/svg', 'svg'); } }, 'SVG'),
      h('button', { type: 'button', onClick: () => { void downloadExport('/api/export/png', 'png'); } }, 'PNG'),
      h('button', { type: 'button', onClick: () => { void downloadExport('/api/export/gif', 'gif'); } }, 'GIF'),
      h('button', { type: 'button', onClick: () => { void saveOnServer(); } }, 'Zapisz'),
      h('button', { type: 'button', onClick: () => importRef.current?.click() }, 'Import'),
      h('input', { ref: importRef, type: 'file', accept: 'application/json,.json', hidden: true, onChange: importRequest }),
    ]),
    h('div', { class: 'preset-card' }, [
      h('label', null, 'Preset postaci'),
      h('div', { class: 'inline-action' }, [
        h('select', { value: preset, onChange: event => setPreset(event.currentTarget.value) }, [
          h('option', { value: '' }, 'Wybierz preset...'),
          ...Object.entries(schema.wholePresets || {}).map(([id, item]) => h('option', { key: id, value: id }, item.label || id)),
        ]),
        h('button', { type: 'button', disabled: !preset, onClick: () => queueRender([{ op: 'wholePreset', preset }], true) }, 'Zastosuj'),
      ]),
    ]),
  ]);
}

function JsonInspector({ request }) {
  return h('details', { class: 'json-inspector' }, [
    h('summary', null, 'Aktualny AvatarRequest'),
    h('pre', null, JSON.stringify(request, null, 2)),
  ]);
}

function GlobalFields({ fields, response, queueRender }) {
  return h('section', { class: 'section-block' }, [
    h('div', { class: 'section-heading' }, [
      h('div', null, [
        h('p', { class: 'eyebrow' }, 'Binding requestu'),
        h('h2', null, 'Ustawienia globalne'),
      ]),
    ]),
    h('div', { class: 'field-grid' }, fields.map(binding => {
      const property = response?.properties?.[binding.id];
      return h('label', { key: binding.id, class: 'global-field' }, [
        h('span', { class: 'field-label' }, displayLabel(binding.label)),
        h(FieldControl, {
          binding,
          value: property?.value,
          onAction: action => queueRender([action]),
        }),
      ]);
    })),
  ]);
}

function GroupTabs({ groups, activeGroup, setActiveGroup }) {
  return h('nav', { class: 'group-tabs', 'aria-label': 'Grupy parametrow' },
    groups.map(group => h('button', {
      key: group.id,
      type: 'button',
      class: group.id === activeGroup ? 'active' : '',
      onClick: () => setActiveGroup(group.id),
    }, group.label)));
}

function CategoryCard({ category, totalCount, response, request, queueRender }) {
  const [preset, setPreset] = useState('');
  const locked = Boolean(request?.lockedCategories?.[category.id]);
  return h('details', { class: 'category-card', open: false }, [
    h('summary', null, [
      h('div', { class: 'category-summary' }, [
        h('strong', null, displayLabel(category.label)),
        h('span', { class: 'category-count' }, `${category.visibleFields.length}/${totalCount} pol`),
      ]),
    ]),
    h('div', { class: 'category-actions' }, [
      h('select', { value: preset, onChange: event => setPreset(event.currentTarget.value) }, [
        h('option', { value: '' }, 'Preset kategorii...'),
        ...Object.keys(category.presets || {}).map(id => h('option', { key: id, value: id }, id)),
      ]),
      h('button', { type: 'button', disabled: !preset, onClick: () => queueRender([{ op: 'categoryPreset', category: category.id, preset }], true) }, 'Preset'),
      h('button', { type: 'button', onClick: () => queueRender([{ op: 'rerollCategory', category: category.id }], true) }, 'Reroll'),
      h('button', { type: 'button', onClick: () => queueRender([{ op: 'resetCategory', category: category.id }], true) }, 'Auto'),
      h('button', { type: 'button', onClick: () => queueRender([{ op: locked ? 'unlockCategory' : 'lockCategory', category: category.id }], true) }, locked ? 'Odblokuj' : 'Zablokuj'),
    ]),
    h('div', { class: 'category-fields' }, category.visibleFields.map(binding => h(PropertyRow, {
      key: binding.id,
      binding,
      property: response?.properties?.[binding.id],
      queueRender,
    }))),
  ]);
}

function PropertyRow({ binding, property, queueRender }) {
  const overridden = Boolean(property?.isOverridden);
  const locked = Boolean(property?.isLocked);
  const sourceClass = locked ? 'locked-label' : overridden ? 'manual' : 'auto';
  const sourceText = locked
    ? `blokada: ${property?.lockSource || ''}`
    : overridden
      ? 'reczne nadpisanie'
      : `auto: ${property?.source || ''}`;
  return h('div', { class: `property-row ${overridden ? 'overridden' : ''} ${locked ? 'locked' : ''}`.trim() }, [
    h('div', { class: 'property-meta' }, [
      h('span', { class: 'property-name' }, displayLabel(binding.label)),
      h('span', { class: 'property-source' }, [
        h('span', { class: sourceClass }, sourceText),
        ` / wynik: ${String(property?.resolvedValue ?? '')}`,
      ]),
    ]),
    h('div', { class: 'property-controls' }, h(FieldControl, {
      binding,
      value: property?.value,
      onAction: action => queueRender([action]),
    })),
    h('div', { class: 'property-buttons' }, [
      h('button', { type: 'button', disabled: !overridden, onClick: () => queueRender([{ op: 'reset', id: binding.id }]) }, 'Auto'),
      h('button', {
        type: 'button',
        onClick: () => queueRender([{ op: locked ? 'unlock' : 'lock', id: binding.id }], true),
      }, locked ? 'Odblokuj' : 'Zablokuj'),
    ]),
  ]);
}

function FieldControl({ binding, value, onAction }) {
  if (binding.kind === 'select') {
    return h('select', {
      value: value == null ? '' : String(value),
      onChange: event => onAction({ op: 'set', id: binding.id, value: event.currentTarget.value }),
    }, (binding.options || []).map(option => h('option', {
      key: String(option.value),
      value: String(option.value),
    }, option.label)));
  }

  if (binding.kind === 'boolean') {
    return h('input', {
      type: 'checkbox',
      checked: Boolean(value),
      onChange: event => onAction({ op: 'set', id: binding.id, value: event.currentTarget.checked }),
    });
  }

  if (binding.kind === 'range') {
    const current = value ?? binding.min ?? 0;
    return h('div', { class: 'control-pair' }, [
      h('input', {
        type: 'range',
        min: binding.min,
        max: binding.max,
        step: binding.step || 1,
        value: current,
        onInput: event => onAction({ op: 'set', id: binding.id, value: Number(event.currentTarget.value) }),
      }),
      h('input', {
        type: 'number',
        min: binding.min,
        max: binding.max,
        step: binding.step || 1,
        value: current,
        onChange: event => onAction({ op: 'set', id: binding.id, value: clampNumber(Number(event.currentTarget.value), binding.min, binding.max) }),
      }),
    ]);
  }

  return h('input', {
    type: binding.kind === 'integer' ? 'number' : 'text',
    min: binding.min,
    max: binding.max,
    step: binding.step || 1,
    value: value ?? '',
    onInput: event => {
      const nextValue = binding.kind === 'integer'
        ? clampNumber(Number(event.currentTarget.value), binding.min, binding.max)
        : event.currentTarget.value;
      onAction({ op: 'set', id: binding.id, value: nextValue });
    },
  });
}

function enqueueAction(queue, action) {
  if ((action.op === 'set' || action.op === 'reset') && action.id) {
    for (let index = queue.length - 1; index >= 0; index--) {
      const existing = queue[index];
      if ((existing.op === 'set' || existing.op === 'reset') && existing.id === action.id) {
        queue.splice(index, 1);
      }
    }
  }
  queue.push(action);
}

function displayLabel(label) {
  return String(label)
    .replace(/^V4\s*[.\-·]\s*/i, '')
    .replace(/^V4\s+/i, '')
    .replace(/^Animacja deterministyczna$/i, 'Animacje');
}

function requestPhase(request) {
  return Number(request?.phase || 0);
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
    return `${body.error || 'Blad'}${field}: ${body.message || response.statusText}`;
  } catch (_) {
    return `${response.status} ${response.statusText}`;
  }
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

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
