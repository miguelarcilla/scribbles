import './style.css';
import {
  MICROSOFT_CERTIFICATIONS_SOURCE_URL,
  MICROSOFT_CERTIFICATIONS_SOURCE_DATE,
  microsoftCertifications,
  type MicrosoftCertification,
} from './data/microsoftCertifications';
import {
  downloadPoster,
  renderPosterImage,
} from './poster';

const PREVIEW_SCALE = 0.7;
const EXPORT_SCALE = 2.4;

function initializeMicrosoftClarity(): void {
  const projectId = import.meta.env.VITE_CLARITY_PROJECT_ID?.trim();
  if (!projectId || document.getElementById('microsoft-clarity')) {
    return;
  }

  type ClarityWindow = Window & {
    clarity?: (...args: unknown[]) => void;
  };

  const clarityWindow = window as ClarityWindow;

  ((clarityApiWindow: ClarityWindow, documentRef: Document, tagName: 'script', scriptId: string) => {
    clarityApiWindow.clarity = clarityApiWindow.clarity ?? function (...args: unknown[]) {
      (clarityApiWindow.clarity as ((...innerArgs: unknown[]) => void) & { q?: unknown[][] }).q =
        (clarityApiWindow.clarity as ((...innerArgs: unknown[]) => void) & { q?: unknown[][] }).q ?? [];
      (clarityApiWindow.clarity as ((...innerArgs: unknown[]) => void) & { q?: unknown[][] }).q?.push(args);
    };

    const script = documentRef.createElement(tagName);
    script.async = true;
    script.id = scriptId;
    script.src = `https://www.clarity.ms/tag/${projectId}`;

    const firstScript = documentRef.getElementsByTagName(tagName)[0];
    if (firstScript?.parentNode) {
      firstScript.parentNode.insertBefore(script, firstScript);
      return;
    }

    documentRef.head.appendChild(script);
  })(clarityWindow, document, 'script', 'microsoft-clarity');
}

interface AppState {
  certifications: MicrosoftCertification[];
  selectedIds: Set<string>;
  filter: string;
  name: string;
  busy: boolean;
  dirty: boolean;
  error: string;
  generatedCanvas: HTMLCanvasElement | null;
}

const state: AppState = {
  certifications: [],
  selectedIds: new Set<string>(),
  filter: '',
  name: '',
  busy: false,
  dirty: true,
  error: '',
  generatedCanvas: null,
};

const root = document.querySelector<HTMLDivElement>('#app');

if (!root) {
  throw new Error('The app root element could not be found.');
}

function queryRequired<ElementType extends Element>(selector: string): ElementType {
  const element = document.querySelector<ElementType>(selector);
  if (!element) {
    throw new Error(`The required UI element was not found: ${selector}`);
  }

  return element;
}

root.innerHTML = `
  <div class="page-shell">
    <section class="hero-card">
      <div>
        <p class="eyebrow">v1.0.0</p>
        <h1>Microsoft Certification Poster Generator</h1>
        <p class="hero-copy">
          Pick the certifications you have earned, add your name or handle, and export a custom image that matches the visual language of the certification poster without including unearned certifications.
        </p>
      </div>
      <div class="hero-metrics">
        <div>
          <span class="metric-label">Reference certifications</span>
          <strong id="cert-count">0</strong>
        </div>
        <div>
          <span class="metric-label">Selected</span>
          <strong id="selected-count">0</strong>
        </div>
      </div>
    </section>

    <main class="workspace-grid">
      <section class="panel controls-panel">
        <div class="panel-heading">
          <div>
            <p class="section-kicker">Setup</p>
            <h2>Your snapshot</h2>
          </div>
          <span class="status-pill" id="status-pill">Ready</span>
        </div>

        <label class="field">
          <span>Name or handle</span>
          <input id="name-input" type="text" maxlength="60" placeholder="e.g. Ada Lovelace or @ada" />
        </label>

        <div class="field-group">
          <label class="field grow">
            <span>Find a certification</span>
            <input id="filter-input" type="search" placeholder="Search..." />
          </label>
          <div class="bulk-actions">
            <button id="select-all-button" class="ghost-button" type="button">Select all</button>
            <button id="clear-button" class="ghost-button" type="button">Clear</button>
          </div>
        </div>

        <div class="checklist-shell">
          <div class="checklist-header">
            <p>Available certifications</p>
            <span id="filtered-count">0 shown</span>
          </div>
          <div id="checklist" class="checklist"></div>
        </div>

        <div class="action-row">
          <button id="generate-button" class="primary-button" type="button" disabled>Generate image</button>
          <button id="download-button" class="secondary-button" type="button" disabled>Download PNG</button>
        </div>

        <p id="helper-text" class="helper-text">Select the certifications you have earned and generate a poster-style image from the saved reference list.</p>
        <p id="error-text" class="error-text" hidden></p>
      </section>

      <section class="panel preview-panel">
        <div class="panel-heading">
          <div>
            <p class="section-kicker">Preview</p>
            <h2>Generated image</h2>
          </div>
        </div>

        <div class="preview-stage">
          <div id="preview-placeholder" class="preview-placeholder">
            The generated image preview will appear here.
          </div>
          <canvas id="preview-canvas" hidden></canvas>
        </div>

        <div class="preview-notes">
          <p>The export uses a higher render scale than the on-page preview.</p>
          <p id="source-note">Reference snapshot: ${MICROSOFT_CERTIFICATIONS_SOURCE_DATE}</p>
        </div>
      </section>
    </main>
  </div>
`;

const certCount = queryRequired<HTMLElement>('#cert-count');
const selectedCount = queryRequired<HTMLElement>('#selected-count');
const filteredCount = queryRequired<HTMLElement>('#filtered-count');
const statusPill = queryRequired<HTMLElement>('#status-pill');
const helperText = queryRequired<HTMLElement>('#helper-text');
const errorText = queryRequired<HTMLElement>('#error-text');
const sourceNote = queryRequired<HTMLElement>('#source-note');
const nameInput = queryRequired<HTMLInputElement>('#name-input');
const filterInput = queryRequired<HTMLInputElement>('#filter-input');
const selectAllButton = queryRequired<HTMLButtonElement>('#select-all-button');
const clearButton = queryRequired<HTMLButtonElement>('#clear-button');
const generateButton = queryRequired<HTMLButtonElement>('#generate-button');
const downloadButton = queryRequired<HTMLButtonElement>('#download-button');
const checklist = queryRequired<HTMLDivElement>('#checklist');
const previewPlaceholder = queryRequired<HTMLDivElement>('#preview-placeholder');
const previewCanvas = queryRequired<HTMLCanvasElement>('#preview-canvas');

function filteredCertifications(): MicrosoftCertification[] {
  const query = state.filter.trim().toLowerCase();
  if (!query) {
    return state.certifications;
  }

  return state.certifications.filter((certification) => certification.searchKey.includes(query));
}

function markDirty(): void {
  state.dirty = true;
  if (state.generatedCanvas) {
    helperText.textContent = 'Selections changed. Generate again to refresh the preview and download.';
  }
}

function selectedCertifications(): MicrosoftCertification[] {
  return state.certifications.filter((certification) => state.selectedIds.has(certification.id));
}

function renderChecklist(): void {
  const visibleCertifications = filteredCertifications();

  if (visibleCertifications.length === 0) {
    checklist.innerHTML = '<p class="empty-state">No certifications matched your search.</p>';
    filteredCount.textContent = '0 shown';
    return;
  }

  filteredCount.textContent = `${visibleCertifications.length} shown`;
  checklist.innerHTML = visibleCertifications
    .map((certification) => {
      const checked = state.selectedIds.has(certification.id) ? 'checked' : '';
      return `
        <label class="checklist-item">
          <input data-certification-id="${certification.id}" type="checkbox" ${checked} />
          <span>${certification.title}</span>
        </label>
      `;
    })
    .join('');

  checklist.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((checkbox) => {
    checkbox.addEventListener('change', () => {
      const identifier = checkbox.dataset.certificationId;
      if (!identifier) {
        return;
      }

      if (checkbox.checked) {
        state.selectedIds.add(identifier);
      } else {
        state.selectedIds.delete(identifier);
      }

      markDirty();
      syncUi();
    });
  });
}

function syncUi(): void {
  certCount.textContent = `${state.certifications.length}`;
  selectedCount.textContent = `${state.selectedIds.size}`;
  renderChecklist();

  statusPill.textContent = state.busy ? 'Generating image' : state.dirty ? 'Ready to generate' : 'Image ready';
  helperText.textContent = state.error
    ? 'Review the error details below.'
    : state.busy
      ? 'Rendering the poster preview and high-quality export.'
      : state.generatedCanvas && !state.dirty
        ? 'Download the PNG when you are happy with the result.'
        : 'Select the certifications you have earned, then generate the image.';

  errorText.hidden = state.error.length === 0;
  errorText.textContent = state.error;

  sourceNote.textContent = `Reference snapshot: ${MICROSOFT_CERTIFICATIONS_SOURCE_DATE} • Source: Microsoft Learn API`;

  generateButton.disabled = state.busy || state.selectedIds.size === 0;
  downloadButton.disabled = state.busy || !state.generatedCanvas || state.dirty;
}

async function copyCanvasToPreview(sourceCanvas: HTMLCanvasElement): Promise<void> {
  const context = previewCanvas.getContext('2d');
  if (!context) {
    throw new Error('Preview rendering is not available in this browser.');
  }

  previewCanvas.width = sourceCanvas.width;
  previewCanvas.height = sourceCanvas.height;
  context.clearRect(0, 0, previewCanvas.width, previewCanvas.height);
  context.drawImage(sourceCanvas, 0, 0);
  previewCanvas.hidden = false;
  previewPlaceholder.hidden = true;
}

async function generatePoster(): Promise<void> {
  const selected = selectedCertifications();
  if (selected.length === 0) {
    return;
  }

  state.busy = true;
  state.error = '';
  syncUi();

  try {
    const [preview, exportCanvas] = await Promise.all([
      renderPosterImage({
        name: state.name,
        certifications: selected,
        scale: PREVIEW_SCALE,
      }),
      renderPosterImage({
        name: state.name,
        certifications: selected,
        scale: EXPORT_SCALE,
      }),
    ]);

    await copyCanvasToPreview(preview);
    state.generatedCanvas = exportCanvas;
    state.dirty = false;
  } catch (error) {
    state.error = error instanceof Error ? error.message : 'The image could not be generated.';
  } finally {
    state.busy = false;
    syncUi();
  }
}

nameInput.addEventListener('input', () => {
  state.name = nameInput.value;
  markDirty();
  syncUi();
});

filterInput.addEventListener('input', () => {
  state.filter = filterInput.value;
  renderChecklist();
});

selectAllButton.addEventListener('click', () => {
  for (const certification of filteredCertifications()) {
    state.selectedIds.add(certification.id);
  }

  markDirty();
  syncUi();
});

clearButton.addEventListener('click', () => {
  if (state.filter.trim().length > 0) {
    for (const certification of filteredCertifications()) {
      state.selectedIds.delete(certification.id);
    }
  } else {
    state.selectedIds.clear();
  }

  markDirty();
  syncUi();
});

generateButton.addEventListener('click', async () => {
  await generatePoster();
});

downloadButton.addEventListener('click', async () => {
  if (!state.generatedCanvas) {
    return;
  }

  try {
    await downloadPoster(state.generatedCanvas, state.name);
  } catch (error) {
    state.error = error instanceof Error ? error.message : 'The image could not be downloaded.';
    syncUi();
  }
});

async function initialize(): Promise<void> {
  initializeMicrosoftClarity();
  state.certifications = microsoftCertifications;
  syncUi();
  sourceNote.textContent = `Reference snapshot: ${MICROSOFT_CERTIFICATIONS_SOURCE_DATE} • ${MICROSOFT_CERTIFICATIONS_SOURCE_URL}`;
}

void initialize();