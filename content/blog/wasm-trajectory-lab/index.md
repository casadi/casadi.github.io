---
title: "Constrained optimization, live in your browser"
author: jg
tags: wasm javascript OCP fatrop
date: 2026-09-29
image: lab.png
---

For many years, we've entertained the idea to make CasADi accessible for web development technology: perform optimization live in your browser without any backend server.
The biggest hurdle was always Ipopt with its Fortran dependencies.

In CasADi 3.8, this finally landed: an npm package was born [`@casadi/casadi-wasm`](https://www.npmjs.com/package/@casadi/casadi-wasm).
It contains the full CasADi core compiled to WebAssembly: symbolics, algorithmic differentiation and the `nlpsol` plugins, including Ipopt and [fatrop](https://github.com/meco-group/fatrop).

# A demo

Let's put it to use. Below is a glider in a room full of obstacles, flying from A to B as fast as possible.
Thrust is limited, speed is limited, and it must keep its distance from every obstacle.
Drag an obstacle, move A or B, change a limit, or grab the trajectory and pull it.
Every change triggers a fresh nonlinear program, solved inside your browser.

<iframe id="lab" src="lab.html" style="width:100%;height:1150px;border:0;border-radius:6px;background:#03050b" allow="fullscreen" title="CasADi WebAssembly constrained trajectory lab"></iframe>
<script>
window.addEventListener('message', function (e) {
  if (e.data && e.data.type === 'casadi-lab-height') document.getElementById('lab').style.height = e.data.h + 'px';
});
</script>

<p style="text-align:right"><a href="lab.html">open full screen</a></p>

## The problem

The optimal control problem being solved is

$$
\begin{align}
  \displaystyle \underset{T,\\,p(\cdot),\\,v(\cdot),\\,a(\cdot)}
  {\text{minimize}}\quad & T \newline
  \text{subject to} \\, \quad
  & \dot{p} = v, \quad \dot{v} = a \newline
  & \\|v(t)\\| \leq v\_{\max}, \quad \\|a(t)\\| \leq a\_{\max} \newline
  & \\|p(t) - o\_j\\| \geq r\_j + \delta, \quad j=1,\ldots,8 \newline
  & p(t) \in \text{arena} \newline
  & p(0) = A,\quad p(T) = B, \quad v(0) = v(T) = 0
\end{align}
$$

It is discretized with multiple shooting over $N=50$ intervals (RK4), giving 355 variables and 1217 constraints.
Nothing about it is exotic, but it is nonconvex: every obstacle can be passed on either side.

Minimum-time solutions are bang-bang: at almost every instant *some* constraint is active, and the trajectory is squeezed against its limits.
The *constraint activity* timeline under the arena shows this, with magenta wherever speed, thrust or clearance sits exactly on its bound.

## What you are looking at

* **Drag**: move obstacles, A and B, or the limit sliders. Each change triggers a new solve that starts from the previous solution, typically in 20 to 70 ms.
* **The problem, live**: the formulation card lights up each constraint family that is active at the optimum, with a count.
* **Multipliers as forces**: the Lagrange multipliers of the obstacle constraints are drawn as what they physically are, forces with which the obstacles push the trajectory away.
* **Shadow prices**: next to every limit slider you get $\partial T^\star / \partial v\_{\max}$, $\partial T^\star / \partial a\_{\max}$ and $\partial T^\star / \partial \delta$. The green arrows on the obstacles show which way to move each obstacle to buy the most time. None of this uses finite differences or extra solves.
* **Grab the path and pull**: this attaches a spring to the trajectory (an extra objective term with parametric weights). You can drag the solution around while the dynamics and constraints push back. When you let go, the solver snaps to whatever local optimum is nearest; pull it over an obstacle and it settles on the other side.

# Using CasADi from javascript

The npm package is written for Node: `casadi.js` is a CommonJS module that `require`s its emscripten runtime.
A browser can still run it unmodified, as long as you give it a ten-line CommonJS sandbox.
The demo does this in a Web Worker, so solving never blocks the user interface:

```js
const CASADI = 'https://unpkg.com/@casadi/casadi-wasm@3.8.1/';

// casadi.js is a CommonJS module written for Node; evaluate it in a tiny sandbox
async function evalCjs(file, requireFn) {
  const src = await (await fetch(CASADI + file)).text();
  const factory = new Function('module', 'exports', 'require', '__dirname', '__filename',
    src + '\n;return module.exports;');
  const module = { exports: {} };
  return factory(module, module.exports, requireFn, CASADI.replace(/\/$/, ''), CASADI + file);
}

const createWasm = await evalCjs('casadi_wasm.js', () => { throw new Error('no require'); });
const createcasadi = await evalCjs('casadi.js', (p) => {
  if (p.endsWith('casadi_wasm.js')) return createWasm;
  if (p === 'path') return { join: (...a) => a.filter(Boolean).join('/').replace(/([^:])\/{2,}/g, '$1/') };
});
const ca = await createcasadi();
await ca.load_nlpsol('fatrop');   // plugins are fetched on demand
```

The wire payload is about 3.5 MB gzipped: the WebAssembly binary (2.2 MB), its JavaScript runtime (0.9 MB) and the fatrop plugin (0.3 MB).
unpkg serves everything with permissive CORS headers, so this works from any page.
After that, it's the CasADi API you know, with JavaScript syntax:

```js
const x = ca.SX.sym('x', 5);
const u = ca.SX.sym('u', 2)
const h = ca.SX.sym('h');
const [, , vx, vy, T] = ca.vertsplit(x, 1);
const [ax, ay] = ca.vertsplit(u, 1);
const f = ca.Function('f', [x, u], [ca.vcat([vx, vy, ax, ay, ca.SX(0)])]);
// ... RK4 into F(x, u, h), loop over the stages to collect constraints g ...
const solver = ca.nlpsol('planner', 'fatrop', { x: w, p: P, f: J, g: ca.vcat(g) }, {
  structure_detection: 'auto',
  fatrop: { print_level: 0, tol: 1e-6 },
});
const sol = solver.call({ x0, p, lbx, ubx, lbg, ubg });
```

The complete formulation is about 170 lines, plus an A\* initial guess: [planner.js](planner.js). The same file runs in Node for testing.

# Try it yourself

The amount of control engineers comfortable with web technology is probably quite small.
But with a little AI assistance, it shouldn't be hard to create your technology demonstrators.

There are many readable examples available in the [example pack](https://github.com/casadi/casadi/releases/download/3.8.1/casadi-example_pack-v3.8.1.zip).

The demo above is three static files next to this post: [lab.html](lab.html), [worker.js](worker.js) and [planner.js](planner.js).
Save them, serve the folder with `python3 -m http.server`, and you have a CasADi playground with no build step.
