// Web Worker: loads CasADi (WebAssembly) straight from unpkg and solves
// trajectory optimisation problems on request.
import { makePlanner, N, M, NP } from './planner.js';

const CASADI = 'https://unpkg.com/@casadi/casadi-wasm@3.8.1/';

const say = (msg) => postMessage({ type: 'log', msg });

// casadi.js is a CommonJS module written for Node; evaluate it in a tiny sandbox
async function evalCjs(file, requireFn) {
  const src = await (await fetch(CASADI + file)).text();
  const factory = new Function('module', 'exports', 'require', '__dirname', '__filename',
    src + '\n;return module.exports;');
  const module = { exports: {} };
  return factory(module, module.exports, requireFn, CASADI.replace(/\/$/, ''), CASADI + file);
}

let ca = null;
let planner_ = null;

async function boot() {
  const t0 = performance.now();
  say('fetching @casadi/casadi-wasm@3.8.1 from unpkg');
  const echo = (s) => { if (!/getrusage/.test(s)) say(s); };
  const createWasm = await evalCjs('casadi_wasm.js', () => { throw new Error('no require'); });
  const createcasadi = await evalCjs('casadi.js', (p) => {
    if (p.endsWith('casadi_wasm.js')) return (opts) => createWasm({ ...opts, print: echo, printErr: echo });
    if (p === 'path') return { join: (...a) => a.filter(Boolean).join('/').replace(/([^:])\/{2,}/g, '$1/') };
    throw new Error('unexpected require ' + p);
  });
  ca = await createcasadi();
  say(`casadi runtime up (${(performance.now() - t0).toFixed(0)} ms)`);
  const t1 = performance.now();
  await ca.load_nlpsol('fatrop');
  say(`plugin nlpsol/fatrop loaded (${(performance.now() - t1).toFixed(0)} ms)`);
}

function planner() {
  if (!planner_) {
    const t0 = performance.now();
    const pl = planner_ = makePlanner(ca);
    say(`NLP: ${pl.nw} variables, ${pl.ng} constraints, built in ${(performance.now() - t0).toFixed(0)} ms`);
  }
  return planner_;
}

const ready = boot().then(() => postMessage({ type: 'ready', N, M, NP }))
  .catch((e) => postMessage({ type: 'fatal', msg: String(e && e.message || e) }));

onmessage = async (ev) => {
  const { id, par, fresh } = ev.data;
  await ready;
  const pl = planner();
  let r = pl.solve(par, { fresh });
  let retried = false;
  if (!r.ok && !fresh) {                       // fall back to a fresh A* guess
    const r2 = pl.solve(par, { fresh: true });
    retried = true;
    if (r2.ok || !r.x) r = { ...r2, ms: r.ms + r2.ms, iter: r.iter + r2.iter };
  }
  postMessage({
    type: 'result', id, retried,
    meta: { nx: pl.nx, nu: pl.nu, nw: pl.nw, ng: pl.ng, groups: pl.groups },
    ...r,
  });
};
