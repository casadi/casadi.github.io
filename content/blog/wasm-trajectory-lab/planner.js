// Minimum-time trajectory planning for a thrust-limited glider,
// formulated with CasADi SX and solved with fatrop -- inside WebAssembly.
//
// The same file runs in a browser Web Worker and in Node (for testing).

export const W = 16, H = 9;     // arena [m]
export const N = 50;            // control intervals
export const M = 8;             // obstacle slots
export const BODY = 0.25;       // glider radius [m]
export const STEP = 0.55;       // max distance per interval [m]: no tunnelling through obstacles

// Parameter vector layout
export const P_START = 0, P_GOAL = 2, P_OBS = 4, P_LIM = P_OBS + 3 * M,
  P_TGT = P_LIM + 3, P_WGT = P_TGT + 2, NP = P_WGT + N + 1;

export const LIMITS = [
  { name: 'v_max', label: 'speed limit', unit: 'm/s', min: 1, max: 12, val: 6 },
  { name: 'a_max', label: 'thrust limit', unit: 'm/s²', min: 1, max: 15, val: 6 },
  { name: 'δ', label: 'safety margin', unit: 'm', min: 0, max: 1, val: 0.1 },
];

export function makePlanner(ca) {
  const nx = 5, nu = 2;                     // state (px, py, vx, vy, T), control (ax, ay)
  const sym = (n, m = 1) => ca.SX.sym(n, m);
  const S = (v) => ca.vertsplit(v, 1);      // scalars of a column
  const add = ca.plus, sub = ca.minus, mul = ca.times, div = ca.rdivide;
  const sq = (a) => mul(a, a);

  // Decision variables in OCP stage order x0 u0 x1 u1 ... x_N:
  // the layout a structure-exploiting solver like fatrop wants.
  // The final time T rides along as a constant state.
  const X = [], U = [], w = [];
  for (let k = 0; k <= N; k++) {
    X.push(sym('x' + k, nx)); w.push(X[k]);
    if (k < N) { U.push(sym('u' + k, nu)); w.push(U[k]); }
  }
  const nw = nx * (N + 1) + nu * N;
  const iX = (k, i) => (nx + nu) * k + i;
  const iU = (k, i) => (nx + nu) * k + nx + i;

  const P = sym('p', NP), p = S(P);
  const [sx, sy] = p.slice(P_START, P_START + 2), [gx, gy] = p.slice(P_GOAL, P_GOAL + 2);
  const [vmax, amax, margin] = p.slice(P_LIM, P_LIM + 3);
  const tgt = p.slice(P_TGT, P_TGT + 2), wgt = p.slice(P_WGT, P_WGT + N + 1);

  // Dynamics: a point mass pushed by a thrust vector, integrated with RK4
  const x = sym('x', nx), u = sym('u', nu), h = sym('h');
  const [, , vx, vy, T] = S(x), [ax, ay] = S(u);
  const f = ca.Function('f', [x, u], [ca.vcat([vx, vy, ax, ay, ca.SX(0)])]);
  const dt = mul(div(T, N), h);             // step over a fraction h of an interval
  const k1 = f.call([x, u])[0];
  const k2 = f.call([add(x, mul(div(dt, 2), k1)), u])[0];
  const k3 = f.call([add(x, mul(div(dt, 2), k2)), u])[0];
  const k4 = f.call([add(x, mul(dt, k3)), u])[0];
  const F = ca.Function('F', [x, u, h],
    [add(x, mul(div(dt, 6), add(add(k1, mul(2, k2)), add(mul(2, k3), k4))))]);

  // Constraints, stage by stage, in named groups so the UI can read their duals
  const g = [], lbg = [], ubg = [], groups = {};
  const push = (grp, e, lb, ub) => {
    (groups[grp] = groups[grp] || []).push(g.length);
    g.push(e); lbg.push(lb); ubg.push(ub);
  };
  const obstacles = (grp, px, py) => {
    for (let j = 0; j < M; j++) {
      const [ox, oy, r] = p.slice(P_OBS + 3 * j, P_OBS + 3 * j + 3);
      const dist = ca.sqrt(add(add(sq(sub(px, ox)), sq(sub(py, oy))), 1e-6));
      push(grp, sub(dist, add(add(r, BODY), margin)), 0, Infinity);   // clearance >= 0
    }
  };

  let J = ca.SX(0);
  for (let k = 0; k <= N; k++) {
    const [px, py, vxk, vyk, Tk] = S(X[k]);
    if (k < N) {
      // gap closing x_{k+1} = F(x_k, u_k) (fatrop wants these first in each stage)
      S(sub(X[k + 1], F.call([X[k], U[k], 1])[0])).forEach((e) => push('dyn', e, 0, 0));
    }
    push('speed', sub(sq(vmax), add(sq(vxk), sq(vyk))), 0, Infinity);
    obstacles('obs', px, py);
    if (k < N) {
      const [axk, ayk] = S(U[k]);
      push('thrust', sub(sq(amax), add(sq(axk), sq(ayk))), 0, Infinity);
      // obstacles are also checked half-way through each interval ...
      const [mx, my] = S(F.call([X[k], U[k], 0.5])[0]);
      obstacles('obsmid', mx, my);
      // ... and an interval may not be long enough to jump over one
      const [nx_, ny_] = S(F.call([X[k], U[k], 1])[0]);
      push('step', sub(STEP * STEP, add(sq(sub(nx_, px)), sq(sub(ny_, py)))), 0, Infinity);
      // a whiff of control regularisation
      J = add(J, mul(0.002, div(add(sq(axk), sq(ayk)), sq(amax))));
    }
    if (k === 0) [sub(px, sx), sub(py, sy), vxk, vyk].forEach((e) => push('bc', e, 0, 0));
    if (k === N) {
      [sub(px, gx), sub(py, gy), vxk, vyk].forEach((e) => push('bc', e, 0, 0));
      J = add(J, Tk);                        // minimum time
    }
    // the "pull": a spring from node k to a grabbed target (weight 0 unless dragging)
    J = add(J, mul(wgt[k], add(sq(sub(px, tgt[0])), sq(sub(py, tgt[1])))));
  }

  const solver = ca.nlpsol('planner', 'fatrop', { x: ca.vcat(w), p: P, f: J, g: ca.vcat(g) }, {
    structure_detection: 'auto',
    equality: lbg.map((l, i) => l === ubg[i]),
    print_time: false, error_on_fail: false,
    fatrop: { print_level: 0, max_iter: 300, tol: 1e-6, tol_acceptable: 1e-3, acceptable_iter: 4 },
  });

  // Simple bounds: stay inside the arena, 0.3 s <= T <= 60 s
  const lbx = new Array(nw).fill(-Infinity), ubx = new Array(nw).fill(Infinity);
  for (let k = 0; k <= N; k++) {
    lbx[iX(k, 0)] = BODY; ubx[iX(k, 0)] = W - BODY;
    lbx[iX(k, 1)] = BODY; ubx[iX(k, 1)] = H - BODY;
    lbx[iX(k, 4)] = 0.3; ubx[iX(k, 4)] = 60;
  }
  const bounds = { lbx: ca.DM(lbx), ubx: ca.DM(ubx), lbg: ca.DM(lbg), ubg: ca.DM(ubg) };

  // Initial guess: collision-free polyline (A* + string pulling), timed with
  // a smooth accelerate/decelerate profile.
  function guess(par) {
    const [vm, am] = par.slice(P_LIM, P_LIM + 2);
    const path = roughPath(par);
    const cum = [0];
    for (let i = 1; i < path.length; i++) cum.push(cum[i - 1] + Math.hypot(path[i][0] - path[i - 1][0], path[i][1] - path[i - 1][1]));
    const len = Math.max(cum[cum.length - 1], 1e-3);
    const at = (d) => {
      let i = 1;
      while (i < cum.length - 1 && cum[i] < d) i++;
      const t = (d - cum[i - 1]) / Math.max(cum[i] - cum[i - 1], 1e-9);
      const dir = Math.atan2(path[i][1] - path[i - 1][1], path[i][0] - path[i - 1][0]);
      return [path[i - 1][0] + t * (path[i][0] - path[i - 1][0]), path[i - 1][1] + t * (path[i][1] - path[i - 1][1]), dir];
    };
    const Tg = Math.max(len / vm * 1.6, 2.4 * Math.sqrt(len / am), 1);
    const w0 = new Array(nw).fill(0);
    for (let k = 0; k <= N; k++) {
      const t = k / N, s = t * t * (3 - 2 * t), v = 6 * t * (1 - t) * len / Tg;
      const [px, py, dir] = at(s * len);
      w0.splice(iX(k, 0), nx, px, py, v * Math.cos(dir), v * Math.sin(dir), Tg);
    }
    return w0;
  }

  let last = null;   // previous solution, reused as initial guess

  // x0: optional initial guess, e.g. a trajectory flown by a human
  function solve(par, { fresh = false, x0 = null } = {}) {
    const t0 = performance.now();
    x0 = x0 || (!fresh && last ? last : guess(par));
    let r;
    try {
      r = solver.call({ x0: ca.DM(x0), p: ca.DM(par), ...bounds });
    } catch (e) {
      last = null;
      const msg = e && e.message ? [].concat(e.message).join(': ') : String(e);
      return { ok: false, status: 'exception', error: msg, ms: performance.now() - t0 };
    }
    const st = solver.stats();
    const out = {
      x: r.x.nonzeros(), g: r.g.nonzeros(), lam_g: r.lam_g.nonzeros(),
      lam_p: r.lam_p.nonzeros(), f: r.f.nonzeros()[0],
    };
    // fatrop reports success (0) or anything else (1): judge the rest by feasibility,
    // including the simple bounds -- without T >= 0.3, time can run backwards (T < 0)
    let viol = 0;
    for (let i = 0; i < out.g.length; i++) viol = Math.max(viol, lbg[i] - out.g[i], out.g[i] - ubg[i]);
    for (let i = 0; i < nw; i++) viol = Math.max(viol, lbx[i] - out.x[i], out.x[i] - ubx[i]);
    if (!out.x.every(Number.isFinite)) viol = Infinity;
    const ok = viol < 1e-4 && Number.isFinite(out.f);
    if (ok) last = out.x;
    return {
      ok, viol, status: st.success ? 'optimal' : ok ? 'feasible' : 'failed',
      iter: Number(st.iter_count), ms: performance.now() - t0, T: out.x[iX(N, 4)], ...out,
    };
  }

  return { nx, nu, nw, ng: g.length, groups, solve, iX, iU, reset() { last = null; } };
}

// Default scene: a slalom
export function defaultParams() {
  const par = new Array(NP).fill(0);
  par.splice(P_START, 2, 1.2, 4.5);
  par.splice(P_GOAL, 2, 14.8, 4.5);
  const obs = [[4.4, 5.3, 1.3], [8, 3.5, 1.4], [11.6, 5.5, 1.3], [8, 7.7, 0.8], [4.2, 1.3, 0.7], [12, 1.4, 0.8]];
  for (let j = 0; j < M; j++) par.splice(P_OBS + 3 * j, 3, ...(obs[j] || [-100 - 10 * j, -100, 0]));
  LIMITS.forEach((l, i) => { par[P_LIM + i] = l.val; });
  return par;
}

// Coarse geometric path from A to B around the obstacles (A* on a grid + string pulling).
export function roughPath(par) {
  const h = 0.2, nxg = Math.round(W / h), nyg = Math.round(H / h);
  const margin = par[P_LIM + 2], body = BODY + margin;
  const obs = [];
  for (let j = 0; j < M; j++) {
    const o = par.slice(P_OBS + 3 * j, P_OBS + 3 * j + 3);
    if (o[2] > 0) obs.push(o);
  }
  const A = [par[P_START], par[P_START + 1]], B = [par[P_GOAL], par[P_GOAL + 1]];
  const clear = (x, y) => {
    let c = Math.min(x - BODY, W - BODY - x, y - BODY, H - BODY - y) + 0.3;
    for (const [ox, oy, r] of obs) c = Math.min(c, Math.hypot(x - ox, y - oy) - r - body);
    return c;
  };
  const cell = (x, y) => [Math.max(0, Math.min(nxg - 1, Math.round(x / h))), Math.max(0, Math.min(nyg - 1, Math.round(y / h)))];
  const free = new Uint8Array(nxg * nyg), pen = new Float32Array(nxg * nyg);
  for (let i = 0; i < nxg; i++) for (let j = 0; j < nyg; j++) {
    const c = clear(i * h, j * h);
    free[i * nyg + j] = c > 0.1 ? 1 : 0;
    pen[i * nyg + j] = c < 0.6 ? (0.6 - c) * 2 : 0;
  }
  const [si, sj] = cell(...A), [ti, tj] = cell(...B);
  const s0 = si * nyg + sj, t0 = ti * nyg + tj;
  free[s0] = 1; free[t0] = 1;
  const cost = new Float32Array(nxg * nyg).fill(Infinity), from = new Int32Array(nxg * nyg).fill(-1);
  const heap = [];   // binary min-heap of [f, id]
  const hpush = (id, fv) => {
    heap.push([fv, id]);
    for (let i = heap.length - 1; i > 0;) {
      const q = (i - 1) >> 1;
      if (heap[q][0] <= heap[i][0]) break;
      [heap[q], heap[i]] = [heap[i], heap[q]]; i = q;
    }
  };
  const hpop = () => {
    const top = heap[0], end = heap.pop();
    if (heap.length) {
      heap[0] = end;
      for (let i = 0; ;) {
        const l = 2 * i + 1, r = l + 1;
        let m = i;
        if (l < heap.length && heap[l][0] < heap[m][0]) m = l;
        if (r < heap.length && heap[r][0] < heap[m][0]) m = r;
        if (m === i) break;
        [heap[m], heap[i]] = [heap[i], heap[m]]; i = m;
      }
    }
    return top;
  };
  cost[s0] = 0; hpush(s0, 0);
  let found = false;
  while (heap.length) {
    const [, id] = hpop();
    if (id === t0) { found = true; break; }
    const i = Math.floor(id / nyg), j = id % nyg;
    for (let di = -1; di <= 1; di++) for (let dj = -1; dj <= 1; dj++) {
      const a = i + di, b = j + dj;
      if ((!di && !dj) || a < 0 || b < 0 || a >= nxg || b >= nyg) continue;
      const nid = a * nyg + b;
      if (!free[nid]) continue;
      const c = cost[id] + Math.hypot(di, dj) * h * (1 + pen[nid]);
      if (c < cost[nid]) { cost[nid] = c; from[nid] = id; hpush(nid, c + Math.hypot(a - ti, b - tj) * h); }
    }
  }
  if (!found) return [A, B];
  const pts = [];
  for (let id = t0; id !== -1; id = from[id]) pts.push([Math.floor(id / nyg) * h, (id % nyg) * h]);
  pts.reverse();
  pts[0] = A; pts[pts.length - 1] = B;
  // string pulling: skip ahead while the straight segment keeps its clearance
  const visible = (a, b) => {
    const n = Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1]) / 0.05);
    for (let i = 0; i <= n; i++) if (clear(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) < 0.15) return false;
    return true;
  };
  const out = [pts[0]];
  for (let i = 0; i < pts.length - 1;) {
    let j = pts.length - 1;
    while (j > i + 1 && !visible(pts[i], pts[j])) j--;
    out.push(pts[j]); i = j;
  }
  return out;
}
