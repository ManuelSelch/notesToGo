const $ = id => document.getElementById(id);
const states = ['clean', 'dirty', 'saving', 'error', 'loading'];
let state = new URLSearchParams(location.search).get('state') || 'clean';
if (!states.includes(state)) state = 'clean';
let timer;
let pages = 1;
let strokes = 0;
let focus = false;
let readOnly = false;
const originalStrokes = $('strokes').innerHTML;

function render() {
  const busy = state === 'loading' || state === 'saving';
  $('state').value = state;
  $('save').disabled = state !== 'dirty' && state !== 'error';
  $('save').innerHTML = state === 'saving'
    ? '<span class="spinner" aria-hidden="true"></span>'
    : '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 9v11h14V9M12 3v12m-4-4 4 4 4-4"/></svg>';
  $('save').setAttribute('aria-label', state === 'saving' ? 'Saving' : 'Save');
  $('save').setAttribute('aria-busy', String(state === 'saving'));
  $('save').title = state === 'saving' ? 'Saving' : 'Save';
  $('loading').hidden = state !== 'loading';
  $('paper').disabled = busy || readOnly;
  document.querySelectorAll('.pens button, .edit-tools button').forEach(button => button.disabled = busy);
  $('back').disabled = busy;
  $('failure').hidden = state !== 'error';
  document.querySelector('.toolbar').classList.toggle('focus', focus);
  $('exit-focus').hidden = !focus;
  $('exit-focus').disabled = busy;
  $('page-number').textContent = `1 / ${pages}`;
}
function setState(next) {
  clearTimeout(timer);
  state = next;
  const url = new URL(location.href);
  url.searchParams.set('state', state);
  history.replaceState(null, '', url);
  render();
  if (state === 'error') $('retry').focus();
}
function markDirty() {
  if (state === 'saving' || state === 'loading' || readOnly) return;
  setState('dirty');
}
function save() {
  if (state !== 'dirty' && state !== 'error') return;
  const fails = $('outcome').value === 'failure';
  setState('saving');
  timer = setTimeout(() => {
    setState(fails ? 'error' : 'clean');
    if (!fails) $('paper').focus();
  }, 1500);
}
$('state').addEventListener('change', event => setState(event.target.value));
$('save').addEventListener('click', save);
$('retry').addEventListener('click', save);
$('keep').addEventListener('click', () => { setState('dirty'); $('save').focus(); });
$('paper').addEventListener('click', () => {
  if ($('paper').disabled) return;
  strokes++;
  const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  const y = 200 + ((strokes - 1) % 15) * 35;
  path.setAttribute('d', `M95 ${y} Q130 ${y - 20} 165 ${y} T235 ${y - 5} L310 ${y}`);
  $('strokes').append(path);
  markDirty();
});
for (const id of ['add', 'grid']) $(id).addEventListener('click', () => { pages++; markDirty(); });
$('focus').addEventListener('click', () => { focus = true; render(); });
$('exit-focus').addEventListener('click', () => { focus = false; render(); });
$('read').addEventListener('click', () => { readOnly = !readOnly; $('read').textContent = readOnly ? '✎' : '✓'; render(); });
document.querySelectorAll('.pens button').forEach(button => button.addEventListener('click', () => {
  document.querySelectorAll('.pens button').forEach(item => item.classList.remove('selected'));
  button.classList.add('selected');
}));
$('back').addEventListener('click', () => window.alert('Back/close behavior belongs to slice 4. This mockup only reviews manual Save.'));
$('reset').addEventListener('click', () => {
  pages = 1; strokes = 0; focus = false; readOnly = false;
  $('read').textContent = '✓';
  $('strokes').innerHTML = originalStrokes;
  setState('clean');
});
render();
if (state === 'error') $('retry').focus();
