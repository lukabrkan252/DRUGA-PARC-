const $app = document.getElementById('app');
let token = localStorage.getItem('token'), me = null, machines = [], cur = null, timer = null, week = null;
function isoWeek(d) { d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate())); const day = d.getUTCDay() || 7; d.setUTCDate(d.getUTCDate() + 4 - day);
  const y = d.getUTCFullYear(), w = Math.ceil(((d - Date.UTC(y, 0, 1)) / 864e5 + 1) / 7); return `${y}-W${String(w).padStart(2, '0')}`; }
function shiftWeek(wk, n) { const [y, w] = wk.split('-W').map(Number); const j4 = new Date(Date.UTC(y, 0, 4)); const mon = new Date(j4); mon.setUTCDate(j4.getUTCDate() - ((j4.getUTCDay() || 7) - 1) + (w - 1 + n) * 7);
  return isoWeek(new Date(mon.getUTCFullYear(), mon.getUTCMonth(), mon.getUTCDate())); }
const fmtW = wk => 'KW ' + wk.slice(6) + '/' + wk.slice(0, 4);
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const fmtD = s => s ? s.slice(8,10)+'.'+s.slice(5,7)+'.'+s.slice(0,4) : '–';
const fmtH = m => (m/60).toLocaleString('bs',{maximumFractionDigits:1})+' h';
const fmtN = n => (+n).toLocaleString('bs',{maximumFractionDigits:2});
const fmtT = s => s ? new Date(s).toLocaleString('bs',{dateStyle:'short',timeStyle:'short'}) : '–';

async function api(path, opts = {}) {
  const r = await fetch('/api' + path, {...opts, headers: {'Content-Type':'application/json', Authorization: 'Bearer ' + token, ...(opts.headers||{})},
    body: opts.body && typeof opts.body !== 'string' && !(opts.body instanceof Blob) ? JSON.stringify(opts.body) : opts.body});
  if (r.status === 401) { logout(); throw new Error('401'); }
  const j = await r.json().catch(() => ({}));
  if (!r.ok) { alert(j.detail || 'Greška'); throw new Error(j.detail); }
  return j;
}
const post = (p, b) => api(p, {method: 'POST', body: b});
const patch = (p, b) => api(p, {method: 'PATCH', body: b});

function logout() { localStorage.removeItem('token'); token = null; clearInterval(timer); loginView(); }

function loginView() {
  $app.innerHTML = `<form class="login"><h2 style="margin:0">MO planiranje</h2><input id="pin" type="password" inputmode="numeric" placeholder="PIN" autofocus><button class="pri">Prijava</button></form>`;
  $app.querySelector('form').onsubmit = async e => {
    e.preventDefault();
    const r = await fetch('/api/login', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({pin: pin.value})});
    if (!r.ok) { alert('Pogrešan PIN'); return; }
    const j = await r.json(); token = j.token; localStorage.setItem('token', token); start();
  };
}

async function start() {
  try { me = await api('/me'); } catch { return loginView(); }
  week = week || isoWeek(new Date());
  machines = await api('/machines?week=' + week);
  cur = me.role === 'boss' ? (cur && machines.find(m => m.id === cur) ? cur : machines[0]?.id) : me.machine_id;
  render();
  clearInterval(timer); timer = setInterval(() => { if (!document.activeElement || document.activeElement.tagName !== 'INPUT') render(true); }, 30000);
}

async function render() {
  if (!me) return;
  week = week || isoWeek(new Date());
  machines = await api('/machines?week=' + week);
  return me.role === 'boss' ? bossView() : operatorView();
}

/* ---------------- POSLOVODJA ---------------- */
async function bossView() {
  const [plan, alerts, st] = await Promise.all([api(`/plan/${cur}?week=${week}`), api('/alerts'), api('/status')]);
  const m = plan.machine, S = plan.summary;
  const overdue = alerts.filter(a => a.overdue);
  const tabs = machines.map(x => `<div class="tab ${x.id===cur?'on':''}" data-m="${x.id}">${esc(x.label)}${x.pending?`<span class="badge">${x.pending}</span>`:''}</div>`).join('');
  const pct = S.capacity_min ? Math.min(100, S.green_min / S.capacity_min * 100) : 0;
  $app.innerHTML = `
  <header><h1>MO – poslovođa</h1>
    <span class="mut">SAP osvježeno: ${fmtT(st.last_sync)} (auto svakih ${Math.round(st.interval_sec/60)} min)</span>
    <button id="sync">Osvježi iz SAP-a</button><button id="adm">Postavke</button><button id="out">Odjava</button></header>
  ${st.last_error ? `<main style="padding-bottom:0"><div class="alert err">Greška sinhronizacije: ${esc(st.last_error)}</div></main>` : ''}
  <div class="tabs">${tabs}</div>
  <main>
   ${alerts.length ? `<div class="alert"><b>${overdue.length ? '⚠ Operater je čekirao, a u SAP-u nije proknjiženo:' : 'Čeka potvrdu iz SAP-a:'}</b><br>` +
     alerts.map(a => `<span class="${a.overdue?'err':'mut'}">${esc(a.operator)} · ${esc(a.machine)} · RN ${a.rn}/${a.linija} · ${fmtN(a.qty)} kom · prije ${a.age_min} min${a.overdue?' – NIJE U SAP-u':''}</span>`).join('<br>') + '</div>' : ''}
   <div class="bar">
     <span><button class="sm" id="wp">◀</button> <b>${fmtW(week)}</b> <button class="sm" id="wn">▶</button></span>
     <label>Kapacitet ${esc(m.label)} u ${fmtW(week)} (h) <input id="cap" type="number" min="0" step="0.5" value="${m.capacity_h||''}" style="width:90px"></label>
     <div class="meter"><i style="width:${pct}%"></i></div>
     <b>${fmtH(S.green_min)} / ${S.capacity_min ? fmtH(S.capacity_min) : '—'}</b>
     <span class="mut">ukupno na mašini: ${fmtH(S.total_min)}</span>
     <button class="pri" id="pub">Objavi plan operateru</button>
     <span class="mut">${plan.published_at ? 'objavljeno ' + fmtT(plan.published_at) + (plan.published_week ? ' za ' + fmtW(plan.published_week) : '') : 'nije objavljeno'}</span>
   </div>
   <div class="tw"><table><thead><tr><th>#</th><th>RN pozicije</th><th>RN KPL</th><th>Naziv</th><th>Projekt</th><th>Datum heftanja</th><th>Datum isporuke</th><th class="num">Kom</th><th class="num">Norma</th><th>Akcije</th></tr></thead>
   <tbody id="rows">${plan.rows.map((r,i) => rowHtml(r,i)).join('') || '<tr><td colspan="10" class="mut">Nema aktivnih linija za ovu mašinu.</td></tr>'}</tbody></table></div>
  </main>`;
  document.querySelectorAll('.tab').forEach(t => t.onclick = () => { cur = +t.dataset.m; render(); });
  out.onclick = logout; sync.onclick = async () => { sync.disabled = true; sync.textContent = 'Osvježavam…'; try { await post('/sync'); } finally { render(); } };
  adm.onclick = adminView;
  wp.onclick = () => { week = shiftWeek(week, -1); render(); }; wn.onclick = () => { week = shiftWeek(week, 1); render(); };
  cap.onchange = async () => { await api(`/machines/${cur}/capacity`, {method: 'PUT', body: {week, hours: +cap.value || 0}}); render(); };
  pub.onclick = async () => { const r = await post(`/plan/${cur}/publish?week=${week}`); alert(`Objavljeno ${r.published} linija operateru.`); render(); };
  wireRows(plan);
}

function rowHtml(r, i) {
  const other = machines.filter(x => x.id !== cur);
  const key = `${r.rn},${r.linija}`;
  const sapNote = r.qty_pending ? `<div class="pend">${fmtN(r.qty_pending)} kom prijavljeno, čeka SAP</div>` : '';
  let extra = '', act = '';
  if (r.part === 'B') act = `<span class="mut">ostatak nakon podjele</span>`;
  else {
    act = `<button class="sm" data-act="top" data-k="${key}" title="Na vrh">⤒</button><button class="sm" data-act="up" data-k="${key}">▲</button><button class="sm" data-act="down" data-k="${key}">▼</button>
      <select data-act="move" data-k="${key}"><option value="">Prebaci na…</option>${other.map(x => `<option value="${x.id}">${esc(x.label)}</option>`).join('')}</select>`;
    if (r.part === 'A') act += `<button class="sm" data-act="unsplit" data-k="${key}">Vrati u jednu liniju (${fmtN(r.qty)} kom)</button>`;
  }
  if (r.status === 'partial') extra = `<div class="note">Ne ulazi cijela: u kapacitet staje <b>${r.fit_qty}</b> od ${fmtN(r.part_qty)} kom.
      <button class="sm" data-act="split" data-k="${key}" data-q="${r.fit_qty}">Podijeli (${r.fit_qty} + ${fmtN(r.part_qty - r.fit_qty)})</button></div>`;
  const label = r.part ? ` <span class="mut">(dio ${r.part})</span>` : '';
  return `<tr class="${r.status}" draggable="${r.part !== 'B'}" data-k="${key}"><td>${i+1}</td><td><b>${r.rn}</b><span class="mut"> /${r.linija}</span></td><td>${esc(r.kpl)}</td>
    <td>${esc(r.naziv)}${label}${extra}${sapNote}</td><td>${esc(r.projekt)}</td><td>${fmtD(r.datum_heftanja)}</td><td>${fmtD(r.datum_isporuke)}</td>
    <td class="num">${fmtN(r.part_qty)}</td><td class="num">${fmtH(r.part_norm)}<div class="mut">${fmtN(r.part_norm)} min</div></td><td>${act}</td></tr>`;
}

function wireRows(plan) {
  const keys = () => [...document.querySelectorAll('#rows tr[data-k]')].map(t => t.dataset.k).filter((k, i, a) => a.indexOf(k) === i).map(k => k.split(',').map(Number));
  const save = async () => { await post(`/plan/${cur}/order`, {keys: keys()}); render(); };
  const rows = document.getElementById('rows');
  let dragK = null;
  rows.querySelectorAll('tr[draggable=true]').forEach(tr => {
    tr.ondragstart = () => dragK = tr.dataset.k;
    tr.ondragover = e => { e.preventDefault(); tr.classList.add('drag-over'); };
    tr.ondragleave = () => tr.classList.remove('drag-over');
    tr.ondrop = e => { e.preventDefault(); const src = rows.querySelector(`tr[data-k="${dragK}"]`); if (src && src !== tr) { tr.before(src); save(); } };
  });
  rows.querySelectorAll('[data-act]').forEach(el => {
    const h = async () => {
      const [rn, linija] = el.dataset.k.split(',').map(Number), a = el.dataset.act;
      const tr = el.closest('tr');
      if (a === 'top') { rows.prepend(tr); save(); }
      else if (a === 'up') { let p = tr.previousElementSibling; while (p && p.dataset.k === tr.dataset.k) p = p.previousElementSibling; if (p) { p.before(tr); save(); } }
      else if (a === 'down') { let n = tr.nextElementSibling; while (n && n.dataset.k === tr.dataset.k) n = n.nextElementSibling; if (n) { n.after(tr); save(); } }
      else if (a === 'move') { if (el.value) { await post('/plan/move', {rn, linija, machine_id: +el.value}); render(); } }
      else if (a === 'split') { await post('/plan/split', {rn, linija, qty: +el.dataset.q}); render(); }
      else if (a === 'unsplit') { await post('/plan/split', {rn, linija, qty: null}); render(); }
    };
    if (el.tagName === 'SELECT') el.onchange = h; else el.onclick = h;
  });
}

async function adminView() {
  const [users, sapM] = await Promise.all([api('/users'), api('/sap-machines')]);
  const have = new Set(machines.map(m => m.label));
  $app.innerHTML = `<header><h1>Postavke</h1><button id="back">← Nazad na plan</button></header><main>
   <h3>Mašine u aplikaciji</h3>
   <div class="grid">${machines.map(m => `<div class="card" style="grid-template-columns:1fr auto"><div><b>${esc(m.label)}</b><div class="mut">${esc(m.sap_name)}</div></div><button class="sm" data-off="${m.id}">Ukloni</button></div>`).join('')}</div>
   <p><select id="addm"><option value="">Dodaj mašinu iz SAP-a…</option>${sapM.map(n => `<option>${esc(n)}</option>`).join('')}</select> <button id="addb">Dodaj</button></p>
   <h3>PIN-ovi</h3>
   <div class="tw"><table style="min-width:400px"><tr><th>Korisnik</th><th>Mašina</th><th>PIN</th></tr>${users.map(u => `<tr><td>${esc(u.name)}</td><td>${esc(u.machine||'poslovođa')}</td><td><input value="${esc(u.pin)}" data-u="${u.id}" style="width:100px"></td></tr>`).join('')}</table></div>
   <h3>Ručni upload Excela (dok SAP nije direktno spojen)</h3>
   <p>Nalozi: <input type="file" id="fo" accept=".xlsx"> Preostala norma: <input type="file" id="fn" accept=".xlsx"></p></main>`;
  back.onclick = render;
  addb.onclick = async () => { if (addm.value) { await post('/machines', {sap_name: addm.value}); await start(); adminView(); } };
  document.querySelectorAll('[data-off]').forEach(b => b.onclick = async () => { if (confirm('Ukloniti mašinu iz aplikacije?')) { await patch('/machines/' + b.dataset.off, {enabled: false}); cur = null; await start(); adminView(); } });
  document.querySelectorAll('[data-u]').forEach(i => i.onchange = () => patch('/users/' + i.dataset.u, {pin: i.value}).then(() => alert('PIN spremljen')));
  const up = (inp, kind) => inp.onchange = async () => { await api('/upload/' + kind, {method: 'POST', body: inp.files[0], headers: {'Content-Type': 'application/octet-stream'}}); alert('Učitano, osvježite iz SAP-a/Excela.'); };
  up(fo, 'orders'); up(fn, 'norms');
}

/* ---------------- OPERATER ---------------- */
async function operatorView() {
  const d = await api('/operator/plan');
  const stIcon = s => s === 'confirmed' ? '<span class="ok">✔ u SAP-u</span>' : '<span class="pend">⏳ čeka SAP</span>';
  $app.innerHTML = `<header><h1>${esc(d.machine.label)} – ${esc(me.name)}</h1><span class="mut">plan ${d.week ? fmtW(d.week) + ' · ' : ''}objavljen: ${fmtT(d.published_at)}</span><button id="out">Odjava</button></header><main>
   ${d.published_at ? '' : '<p class="mut">Poslovođa još nije objavio plan.</p>'}
   ${d.rows.map((r, i) => `<div class="card ${r.left <= 0 ? 'done' : ''}">
      <div style="font-size:22px;font-weight:700">${i+1}</div>
      <div><div class="t">RN ${r.rn}/${r.linija} · ${esc(r.naziv)}</div>
        <div class="mut">KPL ${esc(r.kpl)} · ${esc(r.projekt)} · isporuka ${fmtD(r.datum_isporuke)} · norma ${fmtN(r.norm_per_unit)} min/kom</div>
        <div>Planirano <b>${fmtN(r.qty_planned)}</b> · završeno <b>${fmtN(r.done)}</b> · ostaje <b>${fmtN(r.left)}</b> kom ${r.pending ? '<span class="pend">(čeka SAP)</span>' : ''}</div></div>
      <div>${r.left > 0 ? `<label><input type="checkbox" data-full="${r.rn},${r.linija}"> sve</label>
        <input type="number" min="1" max="${r.left}" step="1" placeholder="kom" data-q="${r.rn},${r.linija}" data-left="${r.left}">
        <button class="pri" data-ok="${r.rn},${r.linija}">Potvrdi</button>` : '<b class="ok">✔ završeno</b>'}</div></div>`).join('')}
   ${d.history.length ? `<h3>Moji zadnji unosi</h3><div class="tw"><table style="min-width:500px">${d.history.map(h => `<tr><td>${fmtT(h.ts)}</td><td>RN ${h.rn}/${h.linija}</td><td>${esc(h.naziv||'')}</td><td class="num">${fmtN(h.qty)} kom</td><td>${stIcon(h.status)}</td></tr>`).join('')}</table></div>` : ''}</main>`;
  out.onclick = logout;
  document.querySelectorAll('[data-full]').forEach(c => c.onchange = () => { const i = document.querySelector(`[data-q="${c.dataset.full}"]`); i.value = c.checked ? i.dataset.left : ''; });
  document.querySelectorAll('[data-ok]').forEach(b => b.onclick = async () => {
    const [rn, linija] = b.dataset.ok.split(',').map(Number), q = +document.querySelector(`[data-q="${b.dataset.ok}"]`).value;
    if (!q) return alert('Upišite količinu ili čekirajte "sve".');
    if (!confirm(`Potvrditi ${q} kom na RN ${rn}/${linija}?`)) return;
    await post('/operator/report', {rn, linija, qty: q}); render();
  });
}

token ? start() : loginView();
