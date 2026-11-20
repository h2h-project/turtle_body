import * as THREE from "three";
import { OrbitControls } from "./vendor/OrbitControls.js";
const $ = (id) => document.getElementById(id);
const state = {
  config: null,
  geometry: null,
  result: null,
  revision: 0,
  busy: false,
  incomplete: new Set(),
  thumbs: {},
};
const number = (v) => (v === "" ? null : Number(v));
// Form sections. Bottles and flatpack slats get their own panels.
const GROUPS = {
  bottles: "group-bottles",
  slats: "group-slats",
  head: "group-head",
};
const SLATS = [
  "frame",
  "front_fin",
  "front_support",
  "rear_fin",
  "rear_support",
  "ballast_frame",
];
const UNIFORM = ["front_fin", "rear_fin", "front_support"];
const VESSELS = /^(bottle_|control_housing$)/;
const shortLabel = (v) => v.replace(/ bottle and closure/g, " bottle");
const groupLabel = (id) =>
  shortLabel(state.geometry?.components?.find((m) => m.id === id)?.label ?? id);
const text = (tag, value) => {
  const e = document.createElement(tag);
  e.textContent = value;
  return e;
};
async function api(path, method = "GET", body) {
  const r = await fetch("/api/" + path, {
    method,
    headers: body ? { "Content-Type": "application/json" } : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  const d = await r.json();
  if (!r.ok)
    throw new Error(
      typeof d.detail === "string" ? d.detail : JSON.stringify(d.detail),
    );
  return d;
}
// mode "working": fuchsia spinner (an export, solve or run is going);
// mode "done": a check mark (it finished successfully).
function status(message, error = false, mode = "") {
  const el = $("status");
  const msg = text("span", message);
  if (mode === "working" || mode === "done") {
    const icon = document.createElement("span");
    icon.className = mode === "working" ? "spinner" : "donemark";
    icon.setAttribute("aria-hidden", "true");
    if (mode === "done")
      icon.innerHTML =
        '<svg viewBox="0 0 16 16"><circle cx="8" cy="8" r="8"/><path d="M4.4 8.3l2.3 2.3 4.9-5"/></svg>';
    el.replaceChildren(icon, msg);
  } else el.replaceChildren(msg);
  el.classList.toggle("error", error);
  el.classList.toggle("working", mode === "working" && !error);
}
// hopeturtles.org ASCII turtle (public/turtles-ascii-logo*.txt on the site).
// Hover/focus animation copied from the site's views/partials/nav.ejs: cycle
// the two alternate frames every 400 ms, back to the base frame on leave.
const LOGO_BASE =
  "  _______    ___\n/         \\ |  0|\n|         |/ __\\|\n|___________/\n |__| |__|";
const LOGO_FRAMES = [
  "  _______   ___\n/         \\|  0|\n|         || __-\n|__________/\n  |__| |__|",
  "  _______    ___\n/         \\ |  0|\n|         |/ ___-\n|___________/\n |__| |__|",
];
{
  const logo = $("logo"),
    link = logo.closest("a");
  let frame = 0,
    timer = null;
  logo.textContent = LOGO_BASE;
  const start = () => {
    if (timer !== null) return;
    frame = 0;
    logo.textContent = LOGO_FRAMES[frame];
    timer = window.setInterval(() => {
      frame = (frame + 1) % LOGO_FRAMES.length;
      logo.textContent = LOGO_FRAMES[frame];
    }, 400);
  };
  const stop = () => {
    if (timer === null) return;
    window.clearInterval(timer);
    timer = null;
    logo.textContent = LOGO_BASE;
  };
  link.addEventListener("mouseenter", start);
  link.addEventListener("mouseleave", stop);
  link.addEventListener("focus", start, true);
  link.addEventListener("blur", stop, true);
  // The turtle spans from the top of the brand text to the title's baseline,
  // so its feet stand on the same line as "Buoyancy workbench". A zero-height
  // inline-block marker in the h1 gives the baseline position.
  const h1 = $("brand_text").querySelector("h1");
  const mark = document.createElement("span");
  mark.style.cssText = "display:inline-block;width:0;height:0";
  mark.setAttribute("aria-hidden", "true");
  h1.append(mark);
  const fit = () => {
    const top = $("brand_text").getBoundingClientRect().top;
    const h = mark.getBoundingClientRect().top - top;
    if (h > 0) logo.style.fontSize = `${(h / (5 * 1.1)).toFixed(2)}px`;
  };
  new ResizeObserver(fit).observe($("brand_text"));
  fit();
}
function field(parent, title, value, change, type = "text") {
  const l = text("label", title),
    i = document.createElement("input");
  i.type = type;
  i.value = value ?? "";
  if (type === "number") i.step = "any";
  i.onchange = () => {
    change(type === "number" ? number(i.value) : i.value);
    changed();
  };
  l.append(i);
  parent.append(l);
  return i;
}
function select(parent, title, value, options, change) {
  const l = text("label", title),
    s = document.createElement("select");
  for (const [v, label] of options) {
    const o = text("option", label);
    o.value = v;
    s.append(o);
  }
  s.value = value;
  s.onchange = () => {
    change(s.value);
    changed();
  };
  l.append(s);
  parent.append(l);
  return s;
}
function check(parent, title, value, change) {
  const l = text("label", ""),
    i = document.createElement("input");
  l.className = "check";
  i.type = "checkbox";
  i.checked = value;
  i.onchange = () => {
    change(i.checked);
    changed();
  };
  l.append(i, document.createTextNode(title));
  parent.append(l);
  return i;
}
// Three-number row. A row only counts once all three boxes hold a number, so a
// half-filled row is marked as an error instead of looking complete.
function vector(parent, title, value, change, onState) {
  const l = text("label", title),
    row = document.createElement("div"),
    warn = text("span", "");
  row.className = "vector";
  warn.className = "rowerror";
  warn.setAttribute("role", "alert");
  const v = value ? [...value] : [null, null, null],
    inputs = [];
  const mark = () => {
    const filled = v.filter((x) => x !== null).length,
      partial = filled > 0 && filled < 3;
    inputs.forEach((i, j) =>
      i.classList.toggle("invalid", partial && v[j] === null),
    );
    warn.textContent = partial
      ? "Incomplete: fill in " +
        ["X", "Y", "Z"].filter((_, j) => v[j] === null).join(" and ") +
        ". Type 0 where the value is zero. Nothing in this row is used until all three are filled."
      : "";
    onState?.(partial ? "partial" : filled ? "complete" : "empty");
  };
  for (let j = 0; j < 3; j++) {
    const i = document.createElement("input");
    i.type = "number";
    i.step = "any";
    i.placeholder = ["X", "Y", "Z"][j];
    i.setAttribute("aria-label", title + " " + ["X", "Y", "Z"][j]);
    i.value = v[j] ?? "";
    i.onchange = () => {
      v[j] = number(i.value);
      change(v.every((x) => x !== null) ? [...v] : null);
      mark();
      changed();
    };
    inputs.push(i);
    row.append(i);
  }
  l.append(row, warn);
  parent.append(l);
  mark();
}
// Unsaved edits make the header Save button flash until they are saved.
function setDirty(dirty) {
  const b = $("save");
  b.classList.toggle("unsaved", dirty);
  b.title = dirty ? "You have unsaved changes" : "";
  state.dirty = dirty;
  gearAttention();
}
// The gear shows a dot when something inside the closed drawer needs you:
// unsaved edits, or measurements still missing.
function gearAttention() {
  const g = $("drawertoggle");
  const reasons = [
    state.dirty && "unsaved changes",
    state.notReady && "measurements missing",
  ].filter(Boolean);
  g.classList.toggle("attention", reasons.length > 0);
  g.title =
    "Components and measurements" +
    (reasons.length ? ` (${reasons.join(", ")})` : "");
}
// Components drawer, opened and closed by the gear in the status bar.
{
  const drawer = $("drawer"),
    gear = $("drawertoggle");
  const place = () =>
    drawer.style.setProperty(
      "--drawer-top",
      `${Math.max(0, document.querySelector(".statusbar").getBoundingClientRect().bottom)}px`,
    );
  const setOpen = (open) => {
    place();
    drawer.classList.toggle("open", open);
    gear.setAttribute("aria-expanded", String(open));
    if (open) drawer.focus({ preventScroll: true });
  };
  drawer.tabIndex = -1;
  gear.onclick = () => setOpen(!drawer.classList.contains("open"));
  $("drawerclose").onclick = () => {
    setOpen(false);
    gear.focus();
  };
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && drawer.classList.contains("open")) {
      setOpen(false);
      gear.focus();
    }
  });
  addEventListener("scroll", place, { passive: true });
  addEventListener("resize", place);
}
function changed() {
  setDirty(true);
  state.revision++;
  clearResult();
  void readiness();
}
let validationSeq = 0;
async function readiness() {
  const seq = ++validationSeq;
  try {
    const { missing } = await api("validate", "POST", state.config);
    if (seq !== validationSeq) return;
    const all = [
      ...[...state.incomplete].map(
        (id) =>
          groupLabel(id) +
          ": centre row is incomplete (fill X, Y and Z; type 0 for zero)",
      ),
      ...missing.map(shortLabel),
    ];
    $("missing").replaceChildren(
      ...(all.length ? all : ["Ready to calculate."]).map((v) => text("li", v)),
    );
    $("solve").disabled = state.busy || all.length > 0;
    $("sailrun").disabled = state.busy || all.length > 0;
    state.notReady = all.length > 0;
    gearAttention();
  } catch (e) {
    $("solve").disabled = true;
    $("sailrun").disabled = true;
    $("missing").replaceChildren(text("li", e.message));
  }
}
function clearResult() {
  state.result = null;
  for (const m of meshGroup.children) {
    const c = state.config?.components.find((c) => c.id === m.userData.id);
    if (c) {
      m.visible = c.installed;
      m.position.fromArray(c.offset_m);
    }
  }
  updatePayloadView();
  bodyGroup.position.z = 0;
  bodyGroup.rotation.set(0, 0, 0);
  water.visible = false;
  waterline.visible = false;
  cg.visible = false;
  cb.visible = false;
  $("legend").hidden = true;
  for (const id of ["front", "rear", "roll", "pitch"]) $(id).textContent = "—";
  for (const id of ["front", "rear", "roll", "pitch"])
    setWaterGauge($(id).parentElement, null);
  $("results").textContent =
    "Measurements changed or no calculation yet. Calculate to show the current equilibrium.";
  dropSailRun();
  $("graphs").replaceChildren();
  $("eqchoice").replaceChildren();
  $("comparisons").replaceChildren();
}
function renderForm() {
  const c = state.config;
  $("name").value = c.name;
  $("density").value = c.density_kg_m3 ?? "";
  $("density_source").value = c.density_kg_m3 === null ? "" : c.density_source;
  $("assembled").value = c.assembled_mass_kg ?? "";
  $("bottle_d").value = c.bottle_dimensions_mm.diameter ?? "";
  $("bottle_h").value = c.bottle_dimensions_mm.length ?? "";
  $("verified").checked = c.dimensions_checked;
  $("notes").value = c.notes;
  for (const g of Object.values(GROUPS)) $(g).replaceChildren();
  state.incomplete.clear();
  for (const p of c.components) {
    const meta = state.geometry?.components?.find((m) => m.id === p.id);
    const uniform = UNIFORM.includes(p.id) || meta?.kind === "uniform",
      vessel = ["bottle", "housing"].includes(meta?.kind) || VESSELS.test(p.id);
    // The centre-of-mass source is no longer a form choice: plain boards use
    // their CAD centre unless a measured centre is entered; every other
    // group needs a measured centre.
    if (!uniform) p.com_source = "measured";
    else if (p.com_source === "cad_uniform") p.com_m = null;
    else if (!p.com_m) p.com_source = "cad_uniform";
    const d = document.createElement("details"),
      s = document.createElement("summary");
    const title = text("span", groupLabel(p.id));
    title.className = "title";
    s.append(title);
    const flag = text("span", "centre incomplete");
    flag.className = "flag";
    s.append(flag);
    if (state.thumbs[p.id]) {
      const img = document.createElement("img");
      img.className = "thumb";
      const { wide, square } = state.thumbs[p.id];
      img.src = wide;
      img.alt = groupLabel(p.id) + " highlighted on the turtle";
      s.append(img);
      // Square picture while open, short strip while closed.
      d.addEventListener("toggle", () => (img.src = d.open ? square : wide));
    }
    d.append(s);
    const b = document.createElement("div");
    d.append(b);
    const mass = text("span", "");
    mass.className = "mass";
    const foot = document.createElement("div");
    foot.className = "groupfoot";
    foot.append(mass);
    const badge = () => {
      flag.hidden = !state.incomplete.has(p.id);
      mass.textContent = !p.installed
        ? "Absent from this build"
        : p.mass_kg === null
          ? "Mass needed"
          : "Mass " + p.mass_kg + " kg";
      mass.classList.toggle("muted", !p.installed || p.mass_kg === null);
    };
    check(b, "Installed in this build", p.installed, (v) => {
      p.installed = v;
      badge();
    });
    const grid = document.createElement("div");
    grid.className = "grid2";
    b.append(grid);
    field(
      grid,
      "Measured mass · kg",
      p.mass_kg,
      (v) => {
        p.mass_kg = v;
        badge();
      },
      "number",
    );
    const treatments = [
      ["unknown", "Choose treatment"],
      ...(vessel
        ? [["sealed", "Sealed and watertight"]]
        : [["solid", "Exposed solid"]]),
      ["contained", "Inside another sealed part"],
    ];
    const legacy = {
      solid: "Exposed solid",
      sealed: "Sealed and watertight",
      flooded: "Flooded hollow vessel",
    };
    if (!treatments.some(([v]) => v === p.displacement))
      treatments.push([
        p.displacement,
        legacy[p.displacement] ?? p.displacement,
      ]);
    select(
      grid,
      "Displacement",
      p.displacement,
      treatments,
      (v) => (p.displacement = v),
    );
    vector(
      b,
      uniform
        ? "Balance point · m (optional: leave all three blank to use the board's CAD centre)"
        : "Measured balance point · m",
      p.com_m,
      (v) => {
        p.com_m = v;
        if (uniform) p.com_source = v ? "measured" : "cad_uniform";
      },
      (rowState) => {
        if (rowState === "partial") state.incomplete.add(p.id);
        else state.incomplete.delete(p.id);
        badge();
      },
    );
    const frame = text(
      "p",
      "X forward · Y port · Z up, in metres from the bottle-axis centre." +
        (meta
          ? " CAD centre of this shape: " +
            meta.centroid_m.map((n) => n.toFixed(3)).join(", ") +
            "."
          : ""),
    );
    frame.className = "hint";
    b.append(frame);
    field(b, "Notes", p.notes, (v) => (p.notes = v));
    check(
      b,
      vessel
        ? "I confirm the real part matches the CAD shape and is sealed as chosen."
        : "I confirm the real part matches the CAD shape.",
      p.geometry_confirmed,
      (v) => (p.geometry_confirmed = v),
    );
    // Settings this form no longer edits can still arrive in a loaded file.
    // They keep affecting the result, so show them and offer to clear them.
    const hidden = [
      p.offset_m.some((n) => n !== 0) &&
        "moved from CAD by " + p.offset_m.join(", ") + " m",
      p.displacement_mesh && "replacement shape " + p.displacement_mesh,
      p.uniform_shell_mm !== null &&
        "shell thickness " + p.uniform_shell_mm + " mm",
    ].filter(Boolean);
    if (hidden.length) {
      const note = text(
        "p",
        "Loaded file settings still in effect: " + hidden.join("; ") + ". ",
      );
      note.className = "rowerror";
      const clear = text("button", "Remove these settings");
      clear.onclick = () => {
        p.offset_m = [0, 0, 0];
        p.displacement_mesh = null;
        p.uniform_shell_mm = null;
        renderForm();
        changed();
      };
      note.append(clear);
      b.append(note);
    }
    b.append(foot);
    badge();
    $(
      GROUPS[
        p.id.startsWith("bottle_")
          ? "bottles"
          : SLATS.includes(p.id)
            ? "slats"
            : "head"
      ],
    ).append(d);
  }
  renderSandBallast();
  renderPayloads();
  renderTrials();
  void readiness();
}
// Printed sand ballast container under the bottom bottle (section 05).
// Mass model lives in turtle_sim/config.py (sand_ballast_loads); this readout
// repeats its arithmetic only to label the slider.
const SAND_DEFAULTS = {
  state: "none",
  fill_percent: 100,
  full_sand_mass_kg: 0.75,
  box_mass_kg: null,
  floods: false,
};
const PLA_DENSITY_KG_M3 = 1240;
function sandBoxEstimateKg() {
  const g = state.geometry?.sand_ballast;
  return g
    ? (g.envelope_volume_m3 - g.fill_volume_m3) * PLA_DENSITY_KG_M3
    : null;
}
function renderSandBallast() {
  const sb = (state.config.sand_ballast = {
    ...SAND_DEFAULTS,
    ...(state.config.sand_ballast ?? {}),
  });
  const b = $("sandballast");
  b.replaceChildren();
  const head = text("h3", "Sand ballast container");
  head.className = "subhead";
  b.append(head);
  select(
    b,
    "Container",
    sb.state,
    [
      ["none", "Not attached"],
      ["empty", "Attached, empty"],
      ["sand", "Attached, filled with sand"],
    ],
    (v) => {
      sb.state = v;
      renderSandBallast();
      updatePayloadView();
    },
  );
  if (sb.state === "none") {
    const h = text(
      "p",
      "The printed U-shaped box that slides under the bottom bottle, either side of the ballast fin.",
    );
    h.className = "hint";
    b.append(h);
    return;
  }
  const readout = text("span", "");
  readout.className = "readout";
  const show = () => {
    const sand =
      sb.state === "sand" ? (sb.fill_percent / 100) * sb.full_sand_mass_kg : 0;
    const box = sb.box_mass_kg ?? sandBoxEstimateKg();
    readout.textContent =
      (sb.state === "sand"
        ? `${Math.round(sb.fill_percent)}% · ${sand.toFixed(3)} kg sand`
        : "No sand") +
      (box === null
        ? ""
        : ` · box ${box.toFixed(3)} kg${sb.box_mass_kg === null ? " (estimated)" : ""}` +
          ` · ${(sand + box).toFixed(3)} kg total`);
  };
  if (sb.state === "sand") {
    const l = text(
      "label",
      "How full · saturated sand, 100% = " + sb.full_sand_mass_kg + " kg",
    );
    l.className = "sandfill";
    const r = document.createElement("input");
    r.type = "range";
    r.min = "0";
    r.max = "100";
    r.step = "1";
    r.value = sb.fill_percent;
    r.setAttribute("aria-label", "Sand ballast fill percentage");
    r.oninput = () => {
      sb.fill_percent = Number(r.value);
      show();
    };
    r.onchange = () => {
      sb.fill_percent = Number(r.value);
      changed();
    };
    l.append(r, readout);
    b.append(l);
  } else b.append(readout);
  field(
    b,
    "Measured empty box mass · kg (tray + lid; blank = CAD estimate)",
    sb.box_mass_kg,
    (v) => {
      sb.box_mass_kg = v;
      show();
    },
    "number",
  );
  check(
    b,
    "The lid leaks: water fills the box around the sand.",
    sb.floods,
    (v) => (sb.floods = v),
  );
  const h = text(
    "p",
    "Sand settles to the floor as a level layer. Sealed, the whole box displaces water and the space above the sand holds air. " +
      (state.geometry?.sand_ballast
        ? ""
        : "Export CAD again to add the box shape."),
  );
  h.className = "hint";
  b.append(h);
  show();
}
function renderPayloads() {
  $("payloads").replaceChildren();
  state.config.payloads.forEach((p, index) => {
    const b = document.createElement("div");
    b.className = "payload";
    field(b, "Unique load ID", p.id, (v) => (p.id = v));
    field(b, "Measured mass · kg", p.mass_kg, (v) => (p.mass_kg = v), "number");
    vector(b, "Centre · m", p.com_m, (v) => (p.com_m = v));
    select(
      b,
      "Displacement",
      p.displacement,
      [
        ["contained", "Contained within an existing envelope"],
        ["box", "Exposed measured box"],
      ],
      (v) => (p.displacement = v),
    );
    vector(
      b,
      "Box dimensions · m (if exposed)",
      p.size_m,
      (v) => (p.size_m = v),
    );
    field(b, "Enclosure / measurement notes", p.notes, (v) => (p.notes = v));
    const remove = text("button", "Remove load");
    remove.onclick = () => {
      state.config.payloads.splice(index, 1);
      renderPayloads();
      changed();
    };
    b.append(remove);
    $("payloads").append(b);
  });
}
function renderTrials() {
  $("trials").replaceChildren();
  state.config.observations.forEach((o, index) => {
    const b = document.createElement("div");
    b.className = "trial";
    field(b, "Trial ID", o.id, (v) => (o.id = v));
    field(
      b,
      "Exact configuration name",
      o.configuration,
      (v) => (o.configuration = v),
    );
    field(b, "Date / time", o.timestamp, (v) => (o.timestamp = v));
    select(
      b,
      "Trial purpose",
      o.purpose,
      [
        ["calibration", "Calibration"],
        ["validation", "Independent validation"],
      ],
      (v) => (o.purpose = v),
    );
    field(
      b,
      "Water density · kg/m³",
      o.water_density_kg_m3,
      (v) => (o.water_density_kg_m3 = v),
      "number",
    );
    const grid = document.createElement("div");
    grid.className = "grid2";
    b.append(grid);
    for (const fin of ["front", "rear"])
      for (const face of ["port", "starboard"]) {
        const key = fin + "_" + face;
        field(
          grid,
          fin + " / " + face + " · signed mm",
          o.readings_mm[key],
          (v) => (o.readings_mm[key] = v),
          "number",
        );
      }
    field(
      grid,
      "Reading uncertainty · mm",
      o.uncertainty_mm,
      (v) => (o.uncertainty_mm = v),
      "number",
    );
    field(
      grid,
      "Measured roll · degrees (optional)",
      o.roll_deg,
      (v) => (o.roll_deg = v),
      "number",
    );
    field(
      b,
      "Added trial mass · kg (optional)",
      o.added_mass_kg,
      (v) => (o.added_mass_kg = v),
      "number",
    );
    vector(
      b,
      "Added mass position · m (optional)",
      o.added_mass_position_m,
      (v) => (o.added_mass_position_m = v),
    );
    field(
      b,
      "Conditions, waterline range, tilt outcome & photo references",
      o.notes,
      (v) => (o.notes = v),
    );
    const remove = text("button", "Remove trial");
    remove.onclick = () => {
      state.config.observations.splice(index, 1);
      renderTrials();
      changed();
    };
    b.append(remove);
    $("trials").append(b);
  });
}
for (const [id, key] of [
  ["name", "name"],
  ["density", "density_kg_m3"],
  ["assembled", "assembled_mass_kg"],
  ["notes", "notes"],
])
  $(id).onchange = () => {
    state.config[key] = ["density", "assembled"].includes(id)
      ? number($(id).value)
      : $(id).value;
    if (id === "density") {
      state.config.density_source = "measured";
      $("density_source").value = "measured";
    }
    changed();
  };
$("density_source").onchange = () => {
  state.config.density_source = $("density_source").value;
  if ($("density_source").value !== "measured") {
    state.config.density_kg_m3 =
      $("density_source").value === "freshwater_reference" ? 1000 : 1025;
    $("density").value = state.config.density_kg_m3;
  }
  changed();
};
$("verified").onchange = () => {
  state.config.dimensions_checked = $("verified").checked;
  changed();
};
for (const [id, key] of [
  ["bottle_d", "diameter"],
  ["bottle_h", "length"],
])
  $(id).onchange = () => {
    state.config.bottle_dimensions_mm[key] = number($(id).value);
    changed();
  };
$("addpayload").onclick = () => {
  state.config.payloads.push({
    id: "load_" + (state.config.payloads.length + 1),
    mass_kg: null,
    com_m: null,
    displacement: "contained",
    size_m: null,
    notes: "",
  });
  renderPayloads();
  changed();
};
$("addtrial").onclick = () => {
  state.config.observations.push({
    id: "trial_" + (state.config.observations.length + 1),
    purpose: "validation",
    configuration: state.config.name,
    timestamp: new Date().toISOString(),
    water_density_kg_m3: state.config.density_kg_m3,
    readings_mm: {},
    uncertainty_mm: 1,
    roll_deg: null,
    added_mass_kg: null,
    added_mass_position_m: null,
    notes: "",
  });
  renderTrials();
  changed();
};
$("save").onclick = async () => {
  try {
    const rev = state.revision;
    await api("config", "PUT", state.config);
    if (rev === state.revision) setDirty(false);
    status(
      "Measurements saved locally. Use Download YAML for a portable copy.",
    );
  } catch (e) {
    status(e.message, true);
  }
};
$("download").onclick = async () => {
  try {
    const rev = state.revision;
    await api("config", "PUT", state.config);
    if (rev === state.revision) setDirty(false);
    location.href = "/api/config.yaml";
  } catch (e) {
    status(e.message, true);
  }
};
$("load").onchange = async () => {
  try {
    const f = $("load").files[0];
    if (!f) return;
    const r = await fetch("/api/import", {
      method: "POST",
      headers: { "Content-Type": "text/plain" },
      body: await f.text(),
    });
    const d = await r.json();
    if (!r.ok) throw new Error(JSON.stringify(d.detail));
    state.config = d;
    renderForm();
    changed();
    status(
      "Configuration loaded. Save measurements to keep it on this laptop.",
    );
  } catch (e) {
    status(e.message, true);
  }
};
async function job(kind) {
  state.busy = true;
  $("export").disabled = true;
  $("solve").disabled = true;
  $("sailrun").disabled = true;
  const rev = state.revision;
  try {
    if (kind === "solve") {
      clearResult();
      await api("config", "PUT", state.config);
      setDirty(false); // the solve saves the measurements it uses
    }
    const { job_id } = await api(
      kind,
      "POST",
      kind === "solve" ? state.config : undefined,
    );
    status(
      kind === "export"
        ? "Exporting installed CAD components. This can take several minutes…"
        : "Solving equilibrium and local stability…",
      false,
      "working",
    );
    let j;
    do {
      await new Promise((r) => setTimeout(r, 1000));
      j = await api("jobs/" + job_id);
    } while (j.status === "running");
    if (j.status === "failed") throw new Error(j.message);
    if (kind === "export") {
      await loadGeometry();
      renderForm();
      status(
        "CAD exported. Enter the physical measurements to unlock calculation.",
        false,
        "done",
      );
    } else if (rev !== state.revision) {
      status("Measurements changed during calculation. Old result discarded.");
    } else {
      showResult(j.result);
      const ok = j.result.status === "equilibrium";
      status(
        ok
          ? "Calculation complete. Compare with independent water trials."
          : (j.result.message ?? j.result.status),
        false,
        ok ? "done" : "",
      );
    }
  } catch (e) {
    status(e.message, true);
  } finally {
    state.busy = false;
    $("export").disabled = false;
    void readiness();
  }
}
$("export").onclick = () => job("export");
$("solve").onclick = () => job("solve");
// Z-up scene, metres throughout. No waterline is drawn until a calculation succeeds.
const viewport = $("viewport"),
  scene = new THREE.Scene();
scene.background = new THREE.Color("#dce8e4");
const camera = new THREE.PerspectiveCamera(40, 1, 0.001, 50);
camera.up.set(0, 0, 1);
camera.position.set(1.3, -1.6, 1.1);
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
viewport.append(renderer.domElement);
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
scene.add(new THREE.HemisphereLight(0xffffff, 0x68786c, 2));
const sun = new THREE.DirectionalLight(0xffffff, 3);
sun.position.set(-2, -3, 5);
scene.add(sun);
const bodyGroup = new THREE.Group();
scene.add(bodyGroup);
const meshGroup = new THREE.Group();
bodyGroup.add(meshGroup);
const DETAIL_COLOURS = { sail: 0xf4f4ef, solar_panel: 0x3a3e43 };
// Bottle-centre reference plane (body Z = 0, the fin rulers' zero). It tilts
// with the turtle; the water surface is the separate lighter plane.
const centre = new THREE.Mesh(
  new THREE.PlaneGeometry(1.3, 0.8),
  new THREE.MeshBasicMaterial({
    color: 0x1d5a78,
    transparent: true,
    opacity: 0.22,
    side: THREE.DoubleSide,
    depthWrite: false,
  }),
);
centre.visible = false; // optional: the "Centre plane" button shows it
bodyGroup.add(centre);
const axes = new THREE.AxesHelper(0.15);
bodyGroup.add(axes);
const water = new THREE.Mesh(
  new THREE.PlaneGeometry(3, 3),
  new THREE.MeshPhongMaterial({
    color: 0x3f86a3,
    transparent: true,
    opacity: 0.45,
    side: THREE.DoubleSide,
    depthWrite: false,
  }),
);
water.visible = false;
scene.add(water);
// The waterline: a fuchsia band (±3 mm) where the water surface cuts every
// visible part, rebuilt after each solve. Drawn over the translucent water so
// it reads from above and below.
const WATERLINE_HALF = 0.003;
const waterline = new THREE.Mesh(
  new THREE.BufferGeometry(),
  new THREE.MeshBasicMaterial({
    color: 0xff00ff,
    side: THREE.DoubleSide,
    polygonOffset: true,
    polygonOffsetFactor: -2,
    polygonOffsetUnits: -2,
  }),
);
waterline.visible = false;
waterline.renderOrder = 5;
scene.add(waterline);
function buildWaterline() {
  scene.updateMatrixWorld(true);
  const out = [],
    a = new THREE.Vector3(),
    b = new THREE.Vector3(),
    c = new THREE.Vector3();
  const h = WATERLINE_HALF;
  for (const part of meshGroup.children) {
    if (!part.visible) continue;
    const pos = part.geometry.attributes.position,
      idx = part.geometry.index.array,
      mw = part.matrixWorld;
    for (let i = 0; i < idx.length; i += 3) {
      a.fromBufferAttribute(pos, idx[i]).applyMatrix4(mw);
      b.fromBufferAttribute(pos, idx[i + 1]).applyMatrix4(mw);
      c.fromBufferAttribute(pos, idx[i + 2]).applyMatrix4(mw);
      // Points where this triangle's edges cross world Z = 0 (the water).
      const hits = [];
      for (const [p, q] of [
        [a, b],
        [b, c],
        [c, a],
      ])
        if (p.z > 0 !== q.z > 0) {
          const t = p.z / (p.z - q.z);
          hits.push([p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t]);
        }
      if (hits.length !== 2) continue;
      const [[x1, y1], [x2, y2]] = hits;
      // A vertical quad on the hull from -h to +h along the cut segment.
      out.push(
        x1,
        y1,
        -h,
        x2,
        y2,
        -h,
        x2,
        y2,
        h,
        x1,
        y1,
        -h,
        x2,
        y2,
        h,
        x1,
        y1,
        h,
      );
    }
  }
  waterline.geometry.dispose();
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(out, 3));
  waterline.geometry = g;
  waterline.visible = out.length > 0;
}
function marker(color) {
  const m = new THREE.Mesh(
    new THREE.SphereGeometry(0.013, 16, 12),
    new THREE.MeshBasicMaterial({ color, depthTest: false }),
  );
  m.visible = false;
  m.renderOrder = 10;
  scene.add(m);
  return m;
}
const cg = marker(0xc9473a),
  cb = marker(0x2252ba);
const payloadGroup = new THREE.Group();
bodyGroup.add(payloadGroup);
let sandMesh = null;
function updatePayloadView() {
  if (sandMesh)
    sandMesh.visible = (state.config?.sand_ballast?.state ?? "none") !== "none";
  for (const m of [...payloadGroup.children]) {
    payloadGroup.remove(m);
    m.geometry.dispose();
    m.material.dispose();
  }
  for (const p of state.config?.payloads ?? []) {
    if (!p.com_m) continue;
    const g =
      p.displacement === "box" && p.size_m && p.size_m.every((n) => n > 0)
        ? new THREE.BoxGeometry(...p.size_m)
        : new THREE.SphereGeometry(0.008, 12, 8);
    const m = new THREE.Mesh(
      g,
      new THREE.MeshPhongMaterial({
        color: 0xa25c4b,
        transparent: true,
        opacity: 0.7,
      }),
    );
    m.position.fromArray(p.com_m);
    payloadGroup.add(m);
  }
}
function axisLabel(label, position) {
  const canvas = document.createElement("canvas");
  canvas.width = 256;
  canvas.height = 64;
  const ctx = canvas.getContext("2d");
  ctx.font = '600 24px Mulish, "Helvetica Neue", Arial, sans-serif';
  ctx.fillStyle = "#244c43";
  ctx.fillText(label, 4, 40);
  const sprite = new THREE.Sprite(
    new THREE.SpriteMaterial({
      map: new THREE.CanvasTexture(canvas),
      depthTest: false,
    }),
  );
  sprite.position.fromArray(position);
  sprite.scale.set(0.18, 0.045, 1);
  bodyGroup.add(sprite);
}
axisLabel("0 · bottle centre", [0, 0, 0.025]);
axisLabel("+X front", [0.22, 0, 0]);
axisLabel("+Y port", [0, 0.22, 0]);
axisLabel("+Z up", [0, 0, 0.22]);
function reset() {
  camera.position.set(1.3, -1.6, 1.1);
  controls.target.set(0, 0, 0);
  controls.update();
}
$("reset").onclick = reset;
$("centre").onclick = () => {
  centre.visible = !centre.visible;
  $("centre").setAttribute("aria-pressed", String(centre.visible));
};
new ResizeObserver(() => {
  const w = viewport.clientWidth,
    h = viewport.clientHeight;
  renderer.setSize(w, h);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}).observe(viewport);
renderer.setAnimationLoop(() => {
  controls.update();
  renderer.render(scene, camera);
});
renderer.domElement.addEventListener("click", (e) => {
  const rect = renderer.domElement.getBoundingClientRect(),
    p = new THREE.Vector2(
      ((e.clientX - rect.left) / rect.width) * 2 - 1,
      (-(e.clientY - rect.top) / rect.height) * 2 + 1,
    ),
    ray = new THREE.Raycaster();
  ray.setFromCamera(p, camera);
  const hit = ray.intersectObjects(meshGroup.children)[0];
  if (hit) {
    $("selection").textContent =
      shortLabel(hit.object.userData.label) + " · double click to focus";
  }
});
renderer.domElement.addEventListener("dblclick", (e) => {
  const rect = renderer.domElement.getBoundingClientRect(),
    ray = new THREE.Raycaster();
  ray.setFromCamera(
    new THREE.Vector2(
      ((e.clientX - rect.left) / rect.width) * 2 - 1,
      (-(e.clientY - rect.top) / rect.height) * 2 + 1,
    ),
    camera,
  );
  const hit = ray.intersectObjects(meshGroup.children)[0];
  if (hit) {
    controls.target.copy(hit.point);
    const d = camera.position.clone().sub(hit.point).normalize();
    camera.position.copy(hit.point).addScaledVector(d, 0.4);
  }
});
async function loadGeometry() {
  state.geometry = await api("geometry");
  if (!state.geometry.ready) {
    status(state.geometry.message);
    return;
  }
  for (const m of [...meshGroup.children]) {
    meshGroup.remove(m);
    m.geometry.dispose();
    [m.material].flat().forEach((x) => x.dispose());
  }
  for (const part of state.geometry.components) {
    const data = await api("mesh/" + part.id),
      g = new THREE.BufferGeometry();
    g.setAttribute(
      "position",
      new THREE.Float32BufferAttribute(data.vertices.flat(), 3),
    );
    const bottle = part.kind === "bottle" || part.kind === "housing";
    const base = new THREE.MeshPhongMaterial({
      color: bottle ? 0x86bfbe : part.id.includes("fin") ? 0x9b9c62 : 0xb79363,
      transparent: bottle,
      opacity: bottle ? 0.4 : 1,
      side: THREE.DoubleSide,
      flatShading: true,
    });
    // The export tags display-only details (sails, solar panel) by face, so
    // they can be drawn in their own colour inside one physics component.
    const tagged = Object.entries(data.highlights ?? {}).filter(
      ([name, faces]) => DETAIL_COLOURS[name] && faces.length,
    );
    let material = base;
    if (tagged.length) {
      const owner = new Int32Array(data.faces.length);
      tagged.forEach(([, faces], k) =>
        faces.forEach((f) => (owner[f] = k + 1)),
      );
      const order = [],
        materials = [base];
      for (let k = 0; k <= tagged.length; k++) {
        const start = order.length;
        data.faces.forEach((f, i) => owner[i] === k && order.push(...f));
        g.addGroup(start, order.length - start, k);
        if (k)
          materials.push(
            new THREE.MeshPhongMaterial({
              color: DETAIL_COLOURS[tagged[k - 1][0]],
              // Sails are thin sheets often lit from behind; a little
              // self-light keeps them reading white from any angle.
              emissive: tagged[k - 1][0] === "sail" ? 0x8c8c88 : 0x000000,
              side: THREE.DoubleSide,
              flatShading: true,
            }),
          );
      }
      g.setIndex(order);
      material = materials;
    } else g.setIndex(data.faces.flat());
    g.computeVertexNormals();
    const m = new THREE.Mesh(g, material);
    m.userData = part;
    meshGroup.add(m);
  }
  if (sandMesh) {
    bodyGroup.remove(sandMesh);
    sandMesh.geometry.dispose();
    sandMesh.material.dispose();
    sandMesh = null;
  }
  if (state.geometry.sand_ballast) {
    const data = await api("mesh/sand_ballast"),
      g = new THREE.BufferGeometry();
    g.setAttribute(
      "position",
      new THREE.Float32BufferAttribute(data.vertices.flat(), 3),
    );
    g.setIndex(data.faces.flat());
    g.computeVertexNormals();
    sandMesh = new THREE.Mesh(
      g,
      new THREE.MeshPhongMaterial({
        color: 0xdcbd7a,
        side: THREE.DoubleSide,
        flatShading: true,
      }),
    );
    sandMesh.userData = { id: "sand_ballast" };
    bodyGroup.add(sandMesh);
    updatePayloadView();
  }
  if (state.config) renderSandBallast(); // box estimate needs the geometry
  renderThumbnails();
  status("CAD ready. Complete the measurement survey to calculate flotation.");
}
// One small picture per group: the whole turtle in pale grey with that group
// highlighted, from the same angle as the main view, so front/rear/port bottles
// are told apart by position rather than shape.
function renderThumbnails() {
  state.thumbs = {};
  // Wide and short, framed on the highlighted part (the rest of the turtle
  // stays faint behind it for context).
  const W = 150,
    H = 60,
    SQ = 150; // square version, shown while a panel is open
  let r;
  try {
    r = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  } catch {
    return; // no WebGL: groups simply show no picture
  }
  r.setPixelRatio(2);
  r.setSize(W, H);
  const sc = new THREE.Scene();
  sc.add(new THREE.HemisphereLight(0xffffff, 0x68786c, 2.2));
  const light = new THREE.DirectionalLight(0xffffff, 2.4);
  light.position.set(1, -1.5, 2);
  sc.add(light);
  const ghost = new THREE.MeshLambertMaterial({
      color: 0xb9c6bf,
      transparent: true,
      opacity: 0.35,
      depthWrite: false,
    }),
    hot = new THREE.MeshLambertMaterial({ color: 0xd9822b }),
    copies = meshGroup.children.map((m) => {
      const c = new THREE.Mesh(m.geometry, ghost);
      c.userData = m.userData;
      sc.add(c);
      return c;
    });
  const whole = new THREE.Box3();
  copies.forEach((c) => whole.expandByObject(c));
  const wholeR = whole.getBoundingSphere(new THREE.Sphere()).radius;
  const cam = new THREE.PerspectiveCamera(30, W / H, 0.01, 20);
  cam.up.set(0, 0, 1);
  const dir = new THREE.Vector3(1.3, -1.6, 1.1).normalize();
  // Fit a sphere of radius rad into the (short) vertical field of view.
  const frame = (centre, rad) => {
    const dist = (rad / Math.sin(THREE.MathUtils.degToRad(15))) * 1.05;
    cam.position.copy(centre).addScaledVector(dir, dist);
    cam.lookAt(centre);
  };
  for (const target of copies) {
    const s = new THREE.Box3()
      .setFromObject(target)
      .getBoundingSphere(new THREE.Sphere());
    // Small parts keep a little surrounding context: never zoom past ~1/6
    // of the whole turtle.
    frame(s.center, Math.max(s.radius, wholeR / 6));
    for (const c of copies) {
      c.material = c === target ? hot : ghost;
      c.renderOrder = c === target ? 1 : 0;
    }
    r.setSize(W, H);
    cam.aspect = W / H;
    cam.updateProjectionMatrix();
    r.render(sc, cam);
    const wide = r.domElement.toDataURL("image/png");
    r.setSize(SQ, SQ);
    cam.aspect = 1;
    cam.updateProjectionMatrix();
    r.render(sc, cam);
    state.thumbs[target.userData.id] = {
      wide,
      square: r.domElement.toDataURL("image/png"),
    };
  }
  ghost.dispose();
  hot.dispose();
  r.dispose();
  r.forceContextLoss();
}
// One stability graph. x = extra tilt away from the resting pose, y = the
// twist (moment) the water puts on the turtle there. Sim conventions: roll +
// raises port, pitch + lowers the bow; a positive moment turns the same way.
function stabilityFigure(curve, pose) {
  const roll = curve.axis === "roll";
  const words = roll
    ? { plus: "port side up", minus: "port side down", verb: "rolls" }
    : { plus: "bow down", minus: "bow up", verb: "pitches" };
  const rest = roll ? pose.roll_deg : pose.pitch_deg;
  const vals = curve.samples;
  const limit = Math.max(...vals.map((s) => Math.abs(s.moment_nm)), 1e-6);
  // Plot box inside a 340 x 230 viewBox.
  const L = 64,
    R = 326,
    T = 24,
    B = 176,
    X0 = (L + R) / 2,
    Y0 = (T + B) / 2;
  const sx = (deg) => X0 + (deg / 5) * ((R - L) / 2);
  const sy = (m) => Y0 - (m / (limit * 1.15)) * ((B - T) / 2);
  const fmt = (m) => (Math.abs(m) >= 10 ? m.toFixed(0) : m.toPrecision(2));
  const pts = vals.map((v) => `${sx(v.offset_deg)},${sy(v.moment_nm)}`);
  const dots = vals
    .map(
      (v) =>
        `<circle cx="${sx(v.offset_deg)}" cy="${sy(v.moment_nm)}" r="${v.offset_deg === 0 ? 4.5 : 2.6}" fill="${v.offset_deg === 0 ? "#c000c0" : "#315d4c"}"/>`,
    )
    .join("");
  const t = (x, y, str, extra = "") =>
    `<text x="${x}" y="${y}" font-size="10" fill="#456555" ${extra}>${str}</text>`;
  const svg =
    `<svg viewBox="0 0 340 230" role="img" aria-label="${curve.axis}: twist from the water versus extra tilt">` +
    // push-back (green) and tip-over (red) quadrants
    `<rect x="${L}" y="${T}" width="${X0 - L}" height="${Y0 - T}" fill="#dcefe0"/>` +
    `<rect x="${X0}" y="${Y0}" width="${R - X0}" height="${B - Y0}" fill="#dcefe0"/>` +
    `<rect x="${X0}" y="${T}" width="${R - X0}" height="${Y0 - T}" fill="#f6e4df"/>` +
    `<rect x="${L}" y="${Y0}" width="${X0 - L}" height="${B - Y0}" fill="#f6e4df"/>` +
    t(L + 5, Y0 - 6, "twists it back", 'fill="#2e7a4a" font-weight="600"') +
    t(
      R - 5,
      Y0 + 14,
      "twists it back",
      'fill="#2e7a4a" font-weight="600" text-anchor="end"',
    ) +
    t(R - 5, T + 13, "tips it further", 'fill="#a0473a" text-anchor="end"') +
    t(L + 5, B - 6, "tips it further", 'fill="#a0473a"') +
    // axes
    `<path d="M${L} ${Y0}H${R}M${X0} ${T}V${B}" stroke="#7f9a86" stroke-width="1"/>` +
    `<rect x="${L}" y="${T}" width="${R - L}" height="${B - T}" fill="none" stroke="#b8c9bb"/>` +
    // x ticks + title
    [-5, 0, 5]
      .map((d) =>
        t(
          sx(d),
          B + 13,
          d === 0 ? "0" : `${d > 0 ? "+" : "−"}5°`,
          'text-anchor="middle"',
        ),
      )
      .join("") +
    t(L, B + 28, `◀ more ${words.minus}`) +
    t(R, B + 28, `more ${words.plus} ▶`, 'text-anchor="end"') +
    t(
      X0,
      B + 44,
      `Extra ${curve.axis} away from the resting pose`,
      'text-anchor="middle" font-weight="600"',
    ) +
    // y ticks + title
    t(L - 5, sy(limit) + 3, `+${fmt(limit)}`, 'text-anchor="end"') +
    t(L - 5, Y0 + 3, "0", 'text-anchor="end"') +
    t(L - 5, sy(-limit) + 3, `−${fmt(limit)}`, 'text-anchor="end"') +
    `<path d="M${L - 3} ${sy(limit)}h3M${L - 3} ${sy(-limit)}h3" stroke="#7f9a86"/>` +
    t(L - 5, T - 8, "N·m", 'text-anchor="end"') +
    t(
      14,
      Y0,
      `Twist from the water`,
      `text-anchor="middle" font-weight="600" transform="rotate(-90 14 ${Y0})"`,
    ) +
    t(
      28,
      (T + Y0) / 2,
      `▲ ${words.plus}`,
      `text-anchor="middle" transform="rotate(-90 28 ${(T + Y0) / 2})"`,
    ) +
    t(
      28,
      (Y0 + B) / 2,
      `${words.minus} ▼`,
      `text-anchor="middle" transform="rotate(-90 28 ${(Y0 + B) / 2})"`,
    ) +
    // the curve
    `<polyline points="${pts.join(" ")}" stroke="#315d4c" fill="none" stroke-width="2"/>` +
    dots +
    `</svg>`;
  const f = document.createElement("figure");
  const verdict =
    curve.classification === "restoring"
      ? "self-righting"
      : curve.classification === "overturning"
        ? "tips over"
        : "neutral";
  f.append(
    text(
      "figcaption",
      `${roll ? "Roll" : "Pitch"} (${roll ? "side to side" : "bow to stern"}) · ${verdict}`,
    ),
  );
  f.insertAdjacentHTML("beforeend", svg);
  // A worked example from the +5° sample, in everyday units:
  // 1 N·m is about the twist of a 1 kg weight hung 10 cm off-centre.
  const m5 = vals.find((v) => v.offset_deg === 5)?.moment_nm ?? 0;
  const grams = Math.round(Math.abs(m5) / (9.81 * 0.1) / 0.01) * 10;
  const turnsBack = m5 < 0;
  const restTxt = `${rest > 0 ? "+" : ""}${rest.toFixed(1)}°`;
  f.append(
    text(
      "p",
      `The magenta dot is the resting pose (${curve.axis} ${restTxt}). Example: if a wave ${words.verb} it 5° more ${words.plus}, the water twists it ${turnsBack ? words.minus : words.plus} with ${Math.abs(m5).toPrecision(2)} N·m, about the twist of a ${grams} g weight hung 10 cm out from the centre. ${turnsBack ? `Let go and it ${words.verb} back to ${restTxt}.` : "Let go and it keeps going over."}`,
    ),
  );
  return f;
}
// Waterline gauge behind a fin card. The card is three bottle diameters
// tall: the grey lines at 1/3 and 2/3 are the bottle's bottom and top, the
// dotted line the bottle centre (ruler zero). The light blue water rises from
// the bottom to the predicted level. `diameters` = reading / bottle diameter
// (null = no prediction, no water).
// Roll/pitch cards also tilt the three lines by the angle (tiltDeg, CSS
// clockwise); the water always stays level.
function setWaterGauge(card, diameters, tiltDeg = 0) {
  const water = card.querySelector(".wlgauge .water");
  if (!water) return;
  const tilt = card.querySelector(".wlgauge .tilt");
  if (tilt)
    tilt.style.transform = `rotate(${diameters == null ? 0 : tiltDeg}deg)`;
  const pct =
    diameters == null
      ? 0
      : Math.min(100, Math.max(0, 50 + (diameters / 3) * 100));
  water.style.height = pct + "%";
  water.classList.toggle("dry", diameters == null);
}
function showResult(result) {
  state.result = result;
  if (result.status !== "equilibrium") {
    $("graphs").replaceChildren();
    $("eqchoice").replaceChildren();
    $("results").textContent =
      result.message ??
      "Status: " +
        result.status +
        (result.capacity_kg
          ? " · maximum displacement " + result.capacity_kg.toFixed(3) + " kg"
          : "");
    return;
  }
  const e = result.equilibria[result.selected];
  bodyGroup.rotation.setFromRotationMatrix(
    new THREE.Matrix4().set(
      ...e.rotation[0],
      0,
      ...e.rotation[1],
      0,
      ...e.rotation[2],
      0,
      0,
      0,
      0,
      1,
    ),
  );
  bodyGroup.position.z = e.heave_m;
  water.visible = true;
  cg.position.fromArray(e.centre_mass_m);
  cb.position.fromArray(e.centre_buoyancy_m);
  cg.visible = cb.visible = true;
  $("legend").hidden = false;
  for (const part of meshGroup.children) {
    const config = state.config.components.find(
      (c) => c.id === part.userData.id,
    );
    part.visible = config.installed;
    part.position.fromArray(config.offset_m);
  }
  buildWaterline();
  // Waterline per fin: one number at the middle of the fin (the
  // mean of its port and starboard face rulers, which is exact because the
  // water plane is flat). Red when the water is beyond the bottle radius
  // there (bottle under water, or clear of it).
  const radiusMm = (state.geometry?.bottle_diameter_m ?? 0) * 500;
  const finMm = {};
  for (const fin of ["front", "rear"]) {
    const rr = e.rulers.filter(
      (r) => r.id.startsWith(fin) && r.reading_mm != null,
    );
    const card = $(fin).parentElement,
      note = card.querySelector("span");
    if (!rr.length) {
      $(fin).textContent = "—";
      setWaterGauge(card, null);
      card.classList.remove("submerged");
      note.textContent = "no ruler on this fin";
      continue;
    }
    const mm = rr.reduce((a, r) => a + r.reading_mm, 0) / rr.length;
    finMm[fin] = mm;
    // Shown in centimetres to one decimal, e.g. "+2.9cm".
    const cm = Math.round(mm) / 10;
    $(fin).textContent = `${cm > 0 ? "+" : ""}${cm.toFixed(1)}cm`;
    setWaterGauge(card, radiusMm > 0 ? mm / (2 * radiusMm) : null);
    const over = radiusMm > 0 && Math.abs(mm) > radiusMm;
    card.classList.toggle("submerged", over);
    note.textContent = over
      ? mm > 0
        ? `above the bottle top (radius ${(radiusMm / 10).toFixed(1)}cm): bottle under water`
        : `below the bottle bottom (radius ${(radiusMm / 10).toFixed(1)}cm): bottle clear of the water`
      : "from the bottle centre, middle of the fin";
    const [lo, hi] = state.geometry?.rulers?.find((g) => g.id === rr[0].id)
      ?.range_mm ?? [-Infinity, Infinity];
    if (mm < lo || mm > hi) note.textContent += " · beyond the engraved scale";
  }
  // Roll/pitch gauges: the bottle lines tilt by the angle about the panel
  // centre (the turtle's middle); the level water sits at the midpoint of the
  // front and rear readings. Roll is seen from astern (port on the left), so
  // + roll (port up) is a clockwise turn; pitch is seen from starboard (bow
  // on the right), so + pitch (bow down) is clockwise too.
  const mids = Object.values(finMm);
  const midMm = mids.length
    ? mids.reduce((a, v) => a + v, 0) / mids.length
    : null;
  const midDiameters =
    midMm != null && radiusMm > 0 ? midMm / (2 * radiusMm) : null;
  setWaterGauge($("roll").parentElement, midDiameters, e.roll_deg);
  setWaterGauge($("pitch").parentElement, midDiameters, e.pitch_deg);
  // Roll + raises port; pitch + lowers the bow (the sim's conventions).
  const deg1 = (v) => `${v > 0 ? "+" : ""}${v.toFixed(1)}°`;
  $("roll").textContent = deg1(e.roll_deg);
  $("pitch").textContent = deg1(e.pitch_deg);
  const level = (v) => Math.abs(v) < 0.05;
  $("roll").parentElement.querySelector("span").textContent = level(e.roll_deg)
    ? "level"
    : e.roll_deg > 0
      ? "port side up"
      : "port side down";
  $("pitch").parentElement.querySelector("span").textContent = level(
    e.pitch_deg,
  )
    ? "level"
    : e.pitch_deg > 0
      ? "bow down, stern up"
      : "bow up, stern down";
  $("results").replaceChildren(
    text(
      "p",
      `Mass ${result.mass_kg.toFixed(3)} kg · displacement ${(e.volume_m3 * 1000).toFixed(3)} litres · ${e.stable ? "restoring about both local axes" : "check stability below"}. Red = centre of mass; blue = centre of buoyancy.`,
    ),
    text("p", result.search_note),
  );
  // Middle: which balanced pose to inspect (stable ones are where the
  // turtle settles; unstable ones are balance points it falls away from).
  $("eqchoice").replaceChildren();
  if (result.equilibria.length > 1) {
    const chooser = select(
      $("eqchoice"),
      "Inspect equilibrium",
      String(result.selected),
      result.equilibria.map((pose, i) => [
        String(i),
        `${i + 1}: roll ${pose.roll_deg.toFixed(1)}°, pitch ${pose.pitch_deg.toFixed(1)}° · ${pose.stable ? "stable: it settles here" : "unstable: it tips away"}`,
      ]),
      () => {},
    );
    chooser.onchange = () => {
      result.selected = Number(chooser.value);
      showResult(result);
    };
    $("results").append(
      text(
        "p",
        `${result.equilibria.length} balanced poses found. Only a stable one (restoring in both roll and pitch) is a place the turtle comes to rest; an unstable one balances only in theory and tips off at the slightest nudge. All poses are kept in the saved result.`,
      ),
    );
  }
  for (const w of result.warnings) $("results").append(text("p", w));
  $("graphs").replaceChildren();
  $("graphs").append(
    text(
      "p",
      "If a wave tips the turtle a little away from its resting pose, how hard does the water twist it, and which way? Green zones: the water twists it back (good). Red zones: the water tips it further over.",
    ),
  );
  for (const curve of e.stability) {
    $("graphs").append(stabilityFigure(curve, e));
  }
  $("comparisons").replaceChildren();
  for (const comp of result.configuration.observations
    .filter(
      (o) =>
        o.configuration === result.configuration.name &&
        o.water_density_kg_m3 === result.density_kg_m3,
    )
    .map((o) => ({
      ...o,
      residuals_mm: Object.fromEntries(
        e.rulers
          .filter((r) => r.in_range && o.readings_mm[r.id] != null)
          .map((r) => [r.id, r.reading_mm - o.readings_mm[r.id]]),
      ),
    }))) {
    $("comparisons").append(
      text(
        "p",
        comp.id +
          " / " +
          comp.purpose +
          " · predicted − measured: " +
          Object.entries(comp.residuals_mm)
            .map(([id, v]) => id + " " + v.toFixed(1) + " mm")
            .join(", "),
      ),
    );
  }
}
try {
  state.config = await api("config");
  await loadGeometry();
  renderForm();
} catch (e) {
  status(e.message, true);
}

// ---------------------------------------------------------------- Stage 3: sailing
// Overhead track is north-up, world x east / y north in metres, starting at 0,0.
const sail = { scenarios: [], run: null };
const deg = Math.PI / 180;
const fmt = (v, d = 1) => (v == null ? "—" : Number(v).toFixed(d));
// ---- Dials.
// Compass kinds (value = compass degrees, 0 north, clockwise):
//   heading: turtle facing the value; from: flow arrow coming FROM the value;
//   target: destination in the value's direction.
// sail: sail angle to the hull, 0 = square across, + = counter-clockwise seen
//   from above; the bow points up and the servo's unreachable arc is greyed.
// minutes: a 60-minute clock face.
const COMPASS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
const CUSTOM = "__custom";
// Destination dial temporarily disabled (its card is commented out in
// index.html). While false, runs send no destination; the engine, banner and
// track code for destinations stay in place for when it comes back.
const DESTINATION_ENABLED = false;
// What Custom starts with: a 5 m/s breeze and a weak 0.05 m/s current, both
// from the south, bow north, sail square (change timer at 15 min, also
// square), 30-minute trip, 100 m destination due north.
const CUSTOM_DEFAULT = {
  description:
    "Your own settings. Every dial and field is used as set. Starts as a 5 m/s breeze and a weak 0.05 m/s current, both from the south.",
  duration_s: 1800,
  heading_deg: 0,
  wind_from_deg: 180,
  wind_speed_mps: 5,
  current_from_deg: 180,
  current_speed_mps: 0.05,
  destination_bearing_deg: 0,
  destination_distance_m: 100,
  arrival_radius_m: 20,
  stop_at_destination: false,
  // Sail square from the start; the change timer set to 15 min, also square.
  servo_schedule: [
    { t_s: 0, servo_pos: 90 },
    { t_s: 900, servo_pos: 90 },
  ],
};
// Trip time as m:ss.
const clock = (t) =>
  `${Math.floor(t / 60)}:${String(Math.round(t % 60)).padStart(2, "0")}`;
const compassName = (v) => COMPASS[Math.round(v / 45) % 8];
const wrap = (v) => ((Math.round(v) % 360) + 360) % 360;
// Servo mapping from physics/hydrodynamics.yaml (loaded below); these are its
// defaults: servo_pos 0..180 spans 270° of travel, servo 90 = sail square.
const servoMap = { travel: 270, zero: 90 };
const sailLimits = () => [
  ((0 - servoMap.zero) * servoMap.travel) / 180,
  ((180 - servoMap.zero) * servoMap.travel) / 180,
];
const sailToServo = (a) =>
  Math.min(180, Math.max(0, servoMap.zero + (a * 180) / servoMap.travel));
const servoToSail = (pos) => ((pos - servoMap.zero) * servoMap.travel) / 180;
function makeKnob(el, { label, kind, colour, min = 1, max = 60, onChange }) {
  const NS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(NS, "svg");
  svg.setAttribute("viewBox", "-60 -60 120 120");
  svg.setAttribute("role", "slider");
  svg.setAttribute("tabindex", "0");
  svg.setAttribute("aria-label", label);
  const readout = text("span", "");
  readout.className = "knobvalue";
  el.replaceChildren(svg, readout);
  const knob = { value: 0, disabled: false };
  const compass = ["heading", "from", "target"].includes(kind);
  const pt = (bearing, r) => [
    r * Math.sin(bearing * deg),
    -r * Math.cos(bearing * deg),
  ];
  // Value <-> dial bearing, per kind. Sail: the handle marks the way the sail
  // FACES (perpendicular to the crossbar), so square across (0°) points at the
  // bow and the servo's dead zone sits directly behind it.
  const angleOf = (v) =>
    kind === "sail" ? -v : kind === "minutes" ? v * 6 : v;
  const limits = () =>
    kind === "sail" ? sailLimits() : kind === "minutes" ? [min, max] : [0, 359];
  const clampValue = (v) => {
    if (compass) return wrap(v);
    const [lo, hi] = limits();
    return Math.min(hi, Math.max(lo, Math.round(v)));
  };
  const fromBearing = (b, fine) => {
    if (kind === "sail") {
      const step = fine ? 1 : 5;
      const a = ((-b + 540) % 360) - 180;
      const [lo, hi] = sailLimits();
      // In the unreachable arc, snap to the nearer end stop.
      const v =
        a > hi || a < lo ? (Math.abs(a - hi) < Math.abs(a - lo) ? hi : lo) : a;
      return clampValue(Math.round(v / step) * step);
    }
    if (kind === "minutes") {
      let m = Math.round((((b % 360) + 360) % 360) / 6);
      if (m === 0 || m === 60) m = max >= 60 && min > 0 ? 60 : 0;
      return clampValue(m);
    }
    const step = fine ? 1 : 5;
    return wrap(Math.round(b / step) * step);
  };
  const keyStep = (fine) => (kind === "minutes" ? 1 : fine ? 1 : 5);
  const ticks = (n, every) =>
    Array.from({ length: n }, (_, i) => {
      const a = (360 / n) * i;
      const [x1, y1] = pt(a, i % every ? 46 : 42),
        [x2, y2] = pt(a, 50);
      return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#9fb5aa" stroke-width="${i % every ? 1 : 2}"/>`;
    }).join("");
  const labels = (items) =>
    items
      .map(([t, a, bold]) => {
        const [x, y] = pt(a, 33);
        return `<text x="${x}" y="${y + 4}" text-anchor="middle" font-size="10" font-weight="${bold ? 700 : 500}" fill="#4d6f73">${t}</text>`;
      })
      .join("");
  const arc = (from, to, r) => {
    const [x1, y1] = pt(from, r),
      [x2, y2] = pt(to, r);
    const large = (((to - from) % 360) + 360) % 360 > 180 ? 1 : 0;
    return `M${x1} ${y1}A${r} ${r} 0 ${large} 1 ${x2} ${y2}`;
  };
  const face = () => {
    if (compass)
      return (
        ticks(24, 6) +
        labels([
          ["N", 0, true],
          ["E", 90],
          ["S", 180],
          ["W", 270],
        ])
      );
    if (kind === "minutes")
      return (
        ticks(60, 5) +
        labels([
          [max >= 60 && min > 0 ? "60" : "0", 0, true],
          ["15", 90],
          ["30", 180],
          ["45", 270],
        ])
      );
    // Sail: greyed arc where the servo cannot reach (behind the bow when
    // servo mid-travel = square across).
    const [lo, hi] = sailLimits();
    return (
      ticks(24, 6) +
      `<path d="${arc(-lo, -hi + 360, 50)}" stroke="#c9d3cc" stroke-width="8" fill="none"/>` +
      labels([["bow", 0, true]])
    );
  };
  const describe = (v) => {
    if (compass) return `${v}° · ${compassName(v)}`;
    if (kind === "minutes") return v === 0 ? "never" : `${v} min`;
    const servo = Math.round(sailToServo(v));
    const side = v === 0 ? "square" : v > 0 ? "anticlockwise" : "clockwise";
    return `${v > 0 ? "+" : ""}${v}° ${side} · servo ${servo}`;
  };
  const draw = () => {
    const v = knob.value;
    const [hx, hy] = pt(angleOf(v), 50);
    let pointer = "";
    if (kind === "heading") {
      const [bx, by] = pt(v, 22),
        [lx, ly] = pt(v - 90, 14),
        [l1x, l1y] = pt(v - 25, 14),
        [l2x, l2y] = pt(v + 25, 14);
      pointer =
        `<circle r="12" fill="#fbfcf7" stroke="${colour}" stroke-width="2.5"/>` +
        `<line x1="${lx}" y1="${ly}" x2="${-lx}" y2="${-ly}" stroke="${colour}" stroke-width="2.5"/>` +
        `<polygon points="${bx},${by} ${l1x},${l1y} ${l2x},${l2y}" fill="${colour}"/>`;
    } else if (kind === "from") {
      const [tx, ty] = pt(v, 40),
        [px, py] = pt(v + 180, 40),
        [ax, ay] = pt(v + 180 - 14, 28),
        [cx, cy] = pt(v + 180 + 14, 28);
      pointer =
        `<line x1="${tx}" y1="${ty}" x2="${px}" y2="${py}" stroke="${colour}" stroke-width="3"/>` +
        `<polygon points="${px},${py} ${ax},${ay} ${cx},${cy}" fill="${colour}"/>`;
    } else if (kind === "target") {
      const [fx, fy] = pt(v, 38);
      pointer =
        `<circle r="4" fill="#2e9a4e"/>` +
        `<line x1="0" y1="0" x2="${fx}" y2="${fy}" stroke="${colour}" stroke-width="2" stroke-dasharray="4 3"/>` +
        `<circle cx="${fx}" cy="${fy}" r="6" fill="none" stroke="${colour}" stroke-width="2.5"/>` +
        `<circle cx="${fx}" cy="${fy}" r="2" fill="${colour}"/>`;
    } else if (kind === "sail") {
      // Bow-up turtle; the sail line turns with the value.
      const a = 90 - v,
        [sx, sy] = pt(a, 40),
        [bx, by] = pt(0, 22),
        [l1x, l1y] = pt(-25, 14),
        [l2x, l2y] = pt(25, 14);
      pointer =
        `<circle r="12" fill="#fbfcf7" stroke="#173d3c" stroke-width="2"/>` +
        `<polygon points="${bx},${by} ${l1x},${l1y} ${l2x},${l2y}" fill="#173d3c"/>` +
        `<line x1="${sx}" y1="${sy}" x2="${-sx}" y2="${-sy}" stroke="${colour}" stroke-width="4" stroke-linecap="round"/>`;
    } else {
      // Minutes: a filled wedge from 0 to the value, like a kitchen timer.
      const a = v * 6;
      const wedge =
        v > 0 && v < 60
          ? `<path d="M0 0L0 -40${arc(0, a, 40).replace(/^M[^A]+/, "")}Z" fill="${colour}" opacity="0.18"/>`
          : v >= 60
            ? `<circle r="40" fill="${colour}" opacity="0.18"/>`
            : "";
      const [tx, ty] = pt(a, 38);
      pointer =
        wedge +
        `<line x1="0" y1="0" x2="${tx}" y2="${ty}" stroke="${colour}" stroke-width="3" stroke-linecap="round"/>` +
        `<circle r="4" fill="${colour}"/>`;
    }
    svg.innerHTML =
      `<circle r="54" fill="#f1f5ef" stroke="#c6d5c9"/>` +
      face() +
      pointer +
      `<circle cx="${hx}" cy="${hy}" r="6" fill="${colour}" stroke="#fff" stroke-width="2"/>`;
    const [lo, hi] = limits();
    svg.setAttribute("aria-valuemin", String(lo));
    svg.setAttribute("aria-valuemax", String(hi));
    svg.setAttribute("aria-valuenow", String(v));
    svg.setAttribute("aria-valuetext", describe(v));
    readout.textContent = describe(v);
  };
  knob.set = (v) => {
    knob.value = clampValue(v);
    draw();
  };
  knob.setDisabled = (d) => {
    knob.disabled = d;
    el.closest(".knobcard")?.classList.toggle("disabled", d);
    svg.setAttribute("aria-disabled", String(d));
  };
  const fromPointer = (e) => {
    const r = svg.getBoundingClientRect();
    const dx = e.clientX - (r.left + r.width / 2),
      dy = e.clientY - (r.top + r.height / 2);
    if (Math.hypot(dx, dy) < 4) return;
    knob.set(fromBearing(Math.atan2(dx, -dy) / deg, e.shiftKey));
    onChange?.(knob.value);
    el.dispatchEvent(new Event("input", { bubbles: true }));
  };
  // Track the drag at window level so it keeps working outside the dial.
  let dragging = false;
  svg.addEventListener("pointerdown", (e) => {
    if (knob.disabled) return;
    dragging = true;
    svg.focus();
    fromPointer(e);
    e.preventDefault();
  });
  window.addEventListener("pointermove", (e) => dragging && fromPointer(e));
  window.addEventListener("pointerup", () => (dragging = false));
  window.addEventListener("pointercancel", () => (dragging = false));
  svg.addEventListener("keydown", (e) => {
    if (knob.disabled) return;
    const step = keyStep(e.shiftKey);
    // For the sail, right = clockwise on the dial = a more negative angle.
    const sign = kind === "sail" ? -1 : 1;
    const d = {
      ArrowRight: sign * step,
      ArrowUp: sign * step,
      ArrowLeft: -sign * step,
      ArrowDown: -sign * step,
    }[e.key];
    if (d === undefined) return;
    e.preventDefault();
    knob.set(knob.value + d);
    onChange?.(knob.value);
    el.dispatchEvent(new Event("input", { bubbles: true }));
  });
  knob.set(kind === "minutes" ? min : 0);
  return knob;
}
const syncSailChange = () => {
  // The change dial matters only if the change happens before the trip ends.
  const t = knobs.timer.value,
    d = knobs.duration.value;
  knobs.sail1.setDisabled(t === 0 || t >= d);
  $("timer_hint").textContent =
    t === 0
      ? "The sail stays at its start position for the whole trip."
      : t >= d
        ? "This is after the trip ends, so the sail never changes."
        : `The sail moves ${t} min into the trip.`;
};
const knobs = {
  heading: makeKnob($("k_heading"), {
    label: "Bow points at start",
    kind: "heading",
    colour: "#173d3c",
  }),
  wind: makeKnob($("k_wind"), {
    label: "Wind from",
    kind: "from",
    colour: "#2f5f8a",
  }),
  current: makeKnob($("k_current"), {
    label: "Current from",
    kind: "from",
    colour: "#2b7a6a",
  }),
  dest: makeKnob($("k_dest") ?? document.createElement("div"), {
    label: "Destination direction",
    kind: "target",
    colour: "#b07a12",
  }),
  sail0: makeKnob($("k_sail0"), {
    label: "Sail at start",
    kind: "sail",
    colour: "#7a4fa0",
  }),
  timer: makeKnob($("k_timer"), {
    label: "Change sail after, minutes",
    kind: "minutes",
    colour: "#8a5a2b",
    min: 0,
    max: 59,
    onChange: () => syncSailChange(),
  }),
  sail1: makeKnob($("k_sail1"), {
    label: "Change sail to",
    kind: "sail",
    colour: "#7a4fa0",
  }),
  duration: makeKnob($("k_duration"), {
    label: "Trip length, minutes",
    kind: "minutes",
    colour: "#225d49",
    min: 1,
    max: 60,
    onChange: () => syncSailChange(),
  }),
};
function scenarioToForm(sc) {
  knobs.heading.set(sc.heading_deg);
  knobs.wind.set(sc.wind_from_deg);
  $("sc_wind_speed").value = sc.wind_speed_mps;
  knobs.current.set(sc.current_from_deg);
  $("sc_cur_speed").value = sc.current_speed_mps;
  knobs.dest.set(sc.destination_bearing_deg ?? 0);
  if (DESTINATION_ENABLED) {
    $("sc_dest_dist").value = sc.destination_distance_m ?? 0;
    $("sc_dest_radius").value = sc.arrival_radius_m ?? 20;
    $("sc_dest_stop").checked = !!sc.stop_at_destination;
  }
  // The dials hold one sail change; a file with more keeps only the first.
  const [first, change] = sc.servo_schedule;
  knobs.sail0.set(servoToSail(first.servo_pos));
  knobs.timer.set(change ? Math.round(change.t_s / 60) : 0);
  knobs.sail1.set(servoToSail((change ?? first).servo_pos));
  knobs.duration.set(Math.round(sc.duration_s / 60));
  syncSailChange();
  $("sc_description").textContent = sc.description ?? "";
  refreshTrack();
}
function formToScenario() {
  const custom = $("scenario").value === CUSTOM;
  const base = custom
    ? {}
    : (sail.scenarios.find((s) => s.id === $("scenario").value) ?? {});
  const num = (id, name) => {
    const v = Number($(id).value);
    if ($(id).value === "" || !Number.isFinite(v))
      throw new Error(name + " must be a number");
    return v;
  };
  const duration = knobs.duration.value * 60,
    change = knobs.timer.value * 60;
  const schedule = [{ t_s: 0, servo_pos: sailToServo(knobs.sail0.value) }];
  if (change > 0 && change < duration)
    schedule.push({ t_s: change, servo_pos: sailToServo(knobs.sail1.value) });
  return {
    schema_version: 1,
    id: base.id ?? "custom",
    name: base.name ?? "Custom",
    description: base.description ?? sail.customFrom ?? "",
    duration_s: duration,
    // Long trips are sampled every second, short ones every half second.
    dt_s: duration > 1200 ? 1 : 0.5,
    heading_deg: knobs.heading.value,
    initial_speed_mps: base.initial_speed_mps ?? 0,
    wind_from_deg: knobs.wind.value,
    wind_speed_mps: num("sc_wind_speed", "Wind speed"),
    current_from_deg: knobs.current.value,
    current_speed_mps: num("sc_cur_speed", "Current speed"),
    ...(DESTINATION_ENABLED
      ? {
          destination_bearing_deg: knobs.dest.value,
          destination_distance_m: num("sc_dest_dist", "Destination distance"),
          arrival_radius_m: num("sc_dest_radius", "Arrival distance"),
          stop_at_destination: $("sc_dest_stop").checked,
        }
      : { destination_distance_m: 0 }),
    servo_schedule: schedule,
  };
}
async function loadScenarios() {
  try {
    const h = await api("hydrodynamics");
    servoMap.travel = h.servo_travel_deg.value;
    servoMap.zero = h.servo_zero_pos.value;
  } catch (e) {
    status("Coefficients: " + e.message, true);
  }
  sail.scenarios = await api("scenarios");
  const custom = text("option", "Custom (your own settings)");
  custom.value = CUSTOM;
  $("scenario").replaceChildren(
    custom,
    ...sail.scenarios.map((s) => {
      const o = text("option", s.name);
      o.value = s.id;
      return o;
    }),
  );
  // Open on Custom, preset to the default settings below.
  $("scenario").value = CUSTOM;
  scenarioToForm(CUSTOM_DEFAULT);
  sail.customFrom = "";
}
// Choosing a preset loads it; choosing Custom keeps whatever is on the dials.
$("scenario").onchange = () => {
  const sc = sail.scenarios.find((s) => s.id === $("scenario").value);
  if (sc) scenarioToForm(sc);
  else markCustom();
  dropSailRun();
};
function markCustom() {
  const sel = $("scenario");
  if (sel.value !== CUSTOM) {
    const from = sail.scenarios.find((s) => s.id === sel.value);
    sail.customFrom = from
      ? `Your own settings, started from "${from.name}".`
      : "";
    sel.value = CUSTOM;
  }
  $("sc_description").textContent =
    sail.customFrom ||
    "Your own settings. Every dial and field is used as set.";
}
// Any change to a dial or field (but not the scenario menu itself) = Custom.
$("sailing").addEventListener("input", (e) => {
  if (!e.target.closest(".knobs")) return;
  markCustom();
  dropSailRun();
});
$("sailing").addEventListener("change", (e) => {
  if (!e.target.closest(".knobs")) return;
  markCustom();
  dropSailRun();
});
$("sailrun").onclick = async () => {
  let scenario;
  try {
    scenario = formToScenario();
  } catch (e) {
    status(e.message, true);
    return;
  }
  state.busy = true;
  for (const id of ["export", "solve", "sailrun"]) $(id).disabled = true;
  const rev = state.revision;
  try {
    const { job_id } = await api("sail/run", "POST", {
      configuration: state.config,
      scenario,
    });
    status(
      "Building the sailing model (first run ~1 min) and sailing the scenario…",
      false,
      "working",
    );
    let j;
    do {
      await new Promise((r) => setTimeout(r, 1000));
      j = await api("jobs/" + job_id);
    } while (j.status === "running");
    if (j.status === "failed") throw new Error(j.message);
    if (rev !== state.revision) {
      status("Measurements changed during the run. Old result discarded.");
      return;
    }
    showSail(j.result);
    status(
      j.result.status === "complete"
        ? "Sailing run complete. Coefficients are uncalibrated: treat speeds and turn rates as indicative."
        : "Run stopped early: " + j.result.message,
      j.result.status !== "complete",
      j.result.status === "complete" ? "done" : "",
    );
  } catch (e) {
    status(e.message, true);
  } finally {
    state.busy = false;
    $("export").disabled = false;
    void readiness();
  }
};
function showSail(run) {
  sail.run = run;
  const n = run.samples.t_s.length;
  $("sailresult").hidden = false;
  $("sailtimebar").hidden = false;
  $("sailtime").max = n - 1;
  $("sailtime").value = n - 1;
  const m = run.model;
  const sails = m.plates.filter((p) => p.medium === "air");
  $("sailwarnings").replaceChildren(
    text(
      "li",
      `Model: ${fmt(m.mass_kg, 2)} kg, sail ${fmt(
        sails.reduce((a, p) => a + p.area_m2, 0),
        3,
      )} m², underwater area ${fmt(m.projected_area_m2.water.head_on, 3)} m² head-on / ${fmt(
        m.projected_area_m2.water.beam,
        3,
      )} m² beam, float pose roll ${fmt(m.equilibrium.roll_deg)}° pitch ${fmt(
        m.equilibrium.pitch_deg,
      )}°.`,
    ),
    ...run.warnings.map((w) => text("li", w)),
  );
  const d = run.destination;
  $("destsummary").classList.remove("idle");
  if (!d)
    $("destsummary").textContent =
      `Run complete: ${clock(run.samples.t_s[n - 1])} sailed. No destination was set.`;
  else {
    const sc = run.scenario;
    const where = `${fmt(sc.destination_distance_m, 0)} m ${compassName(wrap(sc.destination_bearing_deg))}`;
    const end = run.samples.t_s[n - 1];
    $("destsummary").textContent = d.arrived
      ? run.stopped_at_destination
        ? `Reached the destination (${where}, within ${d.arrival_radius_m} m) at ${clock(d.arrival_t_s)}. The trip ends there.`
        : `Reached the destination (${where}, within ${d.arrival_radius_m} m) at ${clock(d.arrival_t_s)}. Nothing stops it, so it sailed on to the end of the trip at ${clock(end)}, ending ${fmt(d.final_m, 0)} m from it. Tick "End the trip when it arrives" to stop there.`
      : `Did not reach the destination (${where}). Closest approach ${fmt(d.closest_m, 1)} m at ${clock(d.closest_t_s)}; ${fmt(d.final_m, 1)} m away when the trip ended at ${clock(end)}.`;
  }
  $("destsummary").classList.toggle("arrived", !!d?.arrived);
  $("destsummary").classList.toggle("idle", !d); // neutral when no destination
  updateSail();
}
$("sailtime").oninput = () => updateSail();
window.addEventListener("resize", () => refreshTrack());
new ResizeObserver(() => refreshTrack()).observe($("track"));
function updateSail() {
  const run = sail.run,
    s = run.samples,
    k = Number($("sailtime").value);
  drawTrack(run, k);
  $("sailreadout").textContent =
    `time ${clock(s.t_s[k])} · heading ${fmt(s.heading_deg[k], 0)}° · ` +
    `over ground ${fmt(s.sog_mps[k], 2)} m/s · through water ${fmt(s.stw_mps[k], 2)} m/s · ` +
    `sail ${fmt(s.sail_deg[k], 0)}° (servo ${fmt(s.servo_cmd[k], 0)}) · ` +
    `apparent wind ${fmt(s.apparent_wind_mps[k], 1)} m/s from ${fmt(s.apparent_wind_from_deg[k], 0)}° off the bow · ` +
    `heel ≈ ${fmt(s.heel_estimate_deg[k])}°` +
    (run.destination
      ? ` · ${fmt(run.destination.distance_m[k])} m to destination`
      : "");
  // Heading plotted within ±180° of the start heading, so passing north
  // doesn't jump between 0 and 360 (e.g. start 0: 350° plots as −10°).
  const h0 = run.scenario.heading_deg;
  const centred = s.heading_deg.map((h) => h0 + ((h - h0 + 540) % 360) - 180);
  $("sailplots").replaceChildren(
    plot("Speed over ground · m/s", s.t_s, s.sog_mps, k),
    plot(
      h0 === 0 ? "Heading · ° (− = west of north)" : "Heading · ° true",
      s.t_s,
      centred,
      k,
      [h0 - 180, h0 + 180],
    ),
    plot("Sail angle · °", s.t_s, s.sail_deg, k),
  );
}
function plot(title, t, v, k, range) {
  const f = document.createElement("figure");
  const vals = v.filter((x) => x != null);
  let lo = range ? range[0] : Math.min(...vals),
    hi = range ? range[1] : Math.max(...vals);
  if (hi - lo < 1e-9) {
    lo -= 1;
    hi += 1;
  }
  const T = t[t.length - 1] || 1;
  const X = (x) => 5 + (190 * x) / T,
    Y = (y) => 75 - (70 * (y - lo)) / (hi - lo);
  // Break the line where a value is missing or (for heading) wraps around.
  let d = "",
    prev = null;
  v.forEach((y, i) => {
    if (y == null) return (prev = null);
    const jump = range && prev != null && Math.abs(y - prev) > 180;
    d +=
      (prev == null || jump ? "M" : "L") +
      X(t[i]).toFixed(1) +
      " " +
      Y(y).toFixed(1);
    prev = y;
  });
  f.innerHTML =
    `<svg viewBox="0 0 200 80" role="img" aria-label="${title}">` +
    `<path d="${d}" stroke="#315d4c" fill="none" stroke-width="1.5"/>` +
    `<line x1="${X(t[k])}" x2="${X(t[k])}" y1="2" y2="78" stroke="#c9473a" stroke-width="1"/>` +
    `<text x="4" y="10" font-size="8" fill="#617c72">${fmt(hi, 1)}</text>` +
    `<text x="4" y="78" font-size="8" fill="#617c72">${fmt(lo, 1)}</text></svg>`;
  f.prepend(text("figcaption", title));
  return f;
}
function niceStep(span) {
  const p = 10 ** Math.floor(Math.log10(span));
  return [1, 2, 5, 10].map((m) => m * p).find((s) => span / s <= 6);
}
// Size the overhead canvas to its box (crisp on high-DPI screens).
function trackCanvas() {
  const c = $("track"),
    dpr = window.devicePixelRatio || 1,
    W = c.clientWidth,
    H = c.clientHeight;
  c.width = W * dpr;
  c.height = H * dpr;
  const g = c.getContext("2d");
  g.setTransform(dpr, 0, 0, dpr, 0, 0);
  return { g, W, H };
}
// The overhead turtle drawing from sim/turtle_sprite.svg. Its two groups
// become two square images centred on the sail hub (the circle in
// turtle_sail_system), so the sail image can turn on top of the body image.
// In the drawing the bow points up and the sail bar spans port-starboard
// (sail 0°). Until it loads (or if it fails) the plain sprite is drawn.
const turtleArt = { body: null, sail: null };
(async function loadTurtleArt() {
  try {
    const res = await fetch("/turtle_sprite.svg");
    if (!res.ok) return;
    const doc = new DOMParser().parseFromString(
      await res.text(),
      "image/svg+xml",
    );
    const svg = doc.documentElement;
    if (svg.nodeName !== "svg") return;
    // Measure in a hidden live copy: positions in root (viewBox) units.
    const live = document.importNode(svg, true);
    live.setAttribute(
      "style",
      "position:absolute;left:-9999px;top:0;visibility:hidden",
    );
    document.body.append(live);
    const toRoot = live.getScreenCTM().inverse();
    const rootPt = (el, x, y) => {
      const p = live.createSVGPoint();
      p.x = x;
      p.y = y;
      return p.matrixTransform(toRoot.multiply(el.getScreenCTM()));
    };
    const corners = (el) => {
      const b = el.getBBox();
      return [
        [b.x, b.y],
        [b.x + b.width, b.y],
        [b.x, b.y + b.height],
        [b.x + b.width, b.y + b.height],
      ].map(([x, y]) => rootPt(el, x, y));
    };
    const bodyEl = live.querySelector("#turtle_body"),
      sailEl = live.querySelector("#turtle_sail_system");
    const hub =
      sailEl?.querySelector("circle") ?? sailEl?.querySelector("ellipse");
    if (!bodyEl || !sailEl || !hub) {
      live.remove();
      return;
    }
    const c = rootPt(hub, +hub.getAttribute("cx"), +hub.getAttribute("cy"));
    // Radius that holds the body and the sail at any angle (+ stroke room).
    const R =
      Math.max(
        ...[...bodyEl.children, ...sailEl.children]
          .flatMap(corners)
          .map((p) => Math.hypot(p.x - c.x, p.y - c.y)),
      ) + 1;
    live.remove();
    // One standalone SVG per group: same viewBox, everything else stripped.
    const image = (keepId) => {
      const s = svg.cloneNode(true);
      s.querySelectorAll("#turtle_body, #turtle_sail_system").forEach((el) => {
        if (el.id !== keepId) el.remove();
      });
      s.setAttribute("viewBox", `${c.x - R} ${c.y - R} ${2 * R} ${2 * R}`);
      s.setAttribute("width", "512");
      s.setAttribute("height", "512");
      const img = new Image();
      const url = URL.createObjectURL(
        new Blob([new XMLSerializer().serializeToString(s)], {
          type: "image/svg+xml",
        }),
      );
      return new Promise((ok, fail) => {
        img.onload = () => ok(img);
        img.onerror = fail;
        img.src = url;
      });
    };
    const [body, sailImg] = await Promise.all([
      image("turtle_body"),
      image("turtle_sail_system"),
    ]);
    turtleArt.body = body;
    turtleArt.sail = sailImg;
    refreshTrack();
  } catch (e) {
    console.warn("turtle_sprite.svg not used:", e);
  }
})();
// A turtle seen from above, the body turned to the heading and the sail
// system turned on top of it. At sail 0° the sail spans port-starboard
// (heading − 90°); + sail angle turns it counter-clockwise seen from above.
// r sets the size: the drawing is about 4r across. weight is the line width
// of the plain fallback sprite.
function drawTurtleSprite(g, x, y, r, headingDeg, sailDeg, weight) {
  if (turtleArt.body && turtleArt.sail) {
    const side = 4 * r;
    const layer = (img, turnDeg) => {
      g.save();
      g.translate(x, y);
      g.rotate(turnDeg * deg);
      g.drawImage(img, -side / 2, -side / 2, side, side);
      g.restore();
    };
    layer(turtleArt.body, headingDeg);
    layer(turtleArt.sail, headingDeg - sailDeg);
    return;
  }
  const at = (b, d) => [x + d * Math.sin(b * deg), y - d * Math.cos(b * deg)];
  const sb = headingDeg - 90 - sailDeg;
  g.lineWidth = weight;
  g.strokeStyle = "#173d3c";
  g.fillStyle = "rgba(251,252,247,0.9)";
  g.beginPath();
  g.arc(x, y, r, 0, 2 * Math.PI);
  g.fill();
  g.stroke();
  g.lineWidth = weight + 1;
  g.beginPath();
  g.moveTo(...at(sb + 180, 1.5 * r));
  g.lineTo(...at(sb, 1.5 * r));
  g.stroke();
  g.fillStyle = "#173d3c";
  g.beginPath();
  g.moveTo(...at(headingDeg, 1.9 * r));
  g.lineTo(...at(headingDeg - 28, 0.95 * r));
  g.lineTo(...at(headingDeg + 28, 0.95 * r));
  g.closePath();
  g.fill();
}
function drawCompassRose(g, rx, ry) {
  g.fillStyle = "rgba(251,252,247,0.85)";
  g.strokeStyle = "#9fb5aa";
  g.lineWidth = 1;
  g.beginPath();
  g.arc(rx, ry, 20, 0, 2 * Math.PI);
  g.fill();
  g.stroke();
  g.fillStyle = "#c9473a";
  g.beginPath();
  g.moveTo(rx, ry - 15);
  g.lineTo(rx - 4, ry);
  g.lineTo(rx + 4, ry);
  g.closePath();
  g.fill();
  g.fillStyle = "#9fb5aa";
  g.beginPath();
  g.moveTo(rx, ry + 15);
  g.lineTo(rx - 4, ry);
  g.lineTo(rx + 4, ry);
  g.closePath();
  g.fill();
  g.font = "bold 10px Mulish, sans-serif";
  g.textAlign = "center";
  g.fillStyle = "#173d3c";
  g.fillText("N", rx, ry - 23);
  g.font = "9px Mulish, sans-serif";
  g.fillStyle = "#4d6f73";
  g.fillText("E", rx + 27, ry + 3);
  g.fillText("S", rx, ry + 31);
  g.fillText("W", rx - 27, ry + 3);
  g.textAlign = "left";
}
// Short labelled arrow pointing the way the wind/current flows.
function drawFlowArrow(g, x, y, bearing, colour, label) {
  const b = bearing * deg,
    dx = Math.sin(b),
    dy = -Math.cos(b);
  g.strokeStyle = g.fillStyle = colour;
  g.lineWidth = 2;
  g.beginPath();
  g.moveTo(x - 16 * dx, y - 16 * dy);
  g.lineTo(x + 16 * dx, y + 16 * dy);
  g.stroke();
  g.beginPath();
  g.moveTo(x + 16 * dx, y + 16 * dy);
  g.lineTo(x + 8 * dx - 5 * dy, y + 8 * dy + 5 * dx);
  g.lineTo(x + 8 * dx + 5 * dy, y + 8 * dy - 5 * dx);
  g.fill();
  g.font = "11px Mulish, sans-serif";
  g.fillText(label, x + 24, y + 4);
}
// A run that no longer matches the dials or measurements is dropped, and the
// overhead view goes back to previewing the dials.
function dropSailRun() {
  sail.run = null;
  $("sailresult").hidden = true;
  $("sailtimebar").hidden = true;
  $("destsummary").textContent = "Set the dials, then run the scenario.";
  $("destsummary").className = "destsummary idle";
  refreshTrack();
}
function refreshTrack() {
  if (sail.run) updateSail();
  else drawPreview();
}
// Before a run: the turtle in the middle, bow and sail from the dials, with
// the wind and current arrows flowing in toward it.
function drawPreview() {
  if (!knobs?.heading) return;
  const { g, W, H } = trackCanvas();
  if (!W || !H) return;
  const cx = W / 2,
    cy = H / 2,
    r = 24;
  g.strokeStyle = "#cfe0e2";
  g.lineWidth = 1;
  for (let x = cx % 40; x < W; x += 40) {
    g.beginPath();
    g.moveTo(x, 0);
    g.lineTo(x, H);
    g.stroke();
  }
  for (let y = cy % 40; y < H; y += 40) {
    g.beginPath();
    g.moveTo(0, y);
    g.lineTo(W, y);
    g.stroke();
  }
  const speed = (id) => {
    const v = Number($(id).value);
    return Number.isFinite(v) ? v : 0;
  };
  const wind = { from: knobs.wind.value, v: speed("sc_wind_speed") },
    cur = { from: knobs.current.value, v: speed("sc_cur_speed") };
  const reach = Math.min(W, H) / 2 - 14;
  // Big arrow from the upwind (up-current) side toward the turtle.
  const inflow = (from, colour, side, tailFrac, label) => {
    const b = from * deg,
      ux = Math.sin(b),
      uy = -Math.cos(b),
      px = -uy * side,
      py = ux * side;
    const tail = [
        cx + ux * reach * tailFrac + px,
        cy + uy * reach * tailFrac + py,
      ],
      head = [cx + ux * r * 2.4 + px, cy + uy * r * 2.4 + py];
    g.strokeStyle = g.fillStyle = colour;
    g.globalAlpha = 0.85;
    g.lineWidth = 4;
    g.lineCap = "round";
    g.beginPath();
    g.moveTo(...tail);
    g.lineTo(head[0] + ux * 10, head[1] + uy * 10);
    g.stroke();
    g.beginPath();
    g.moveTo(...head);
    g.lineTo(head[0] + ux * 16 - uy * 8, head[1] + uy * 16 + ux * 8);
    g.lineTo(head[0] + ux * 16 + uy * 8, head[1] + uy * 16 - ux * 8);
    g.closePath();
    g.fill();
    g.globalAlpha = 1;
    g.lineCap = "butt";
    g.font = "600 11px Mulish, sans-serif";
    // Label just beyond the tail, kept inside the canvas and clear of the
    // caption line at the bottom.
    const half = g.measureText(label).width / 2 + 4;
    let lx = tail[0] + ux * 14,
      ly = tail[1] + uy * 14;
    if (ly > H - 30 || ly < 14) {
      // No room beyond the tail: beside it, on the arrow's outer side.
      const out = px > 0 ? 1 : px < 0 ? -1 : 1;
      lx = tail[0] + out * (half + 6);
      ly = Math.min(H - 30, Math.max(14, tail[1] - uy * 10));
    }
    lx = Math.min(W - half, Math.max(half, lx));
    g.textAlign = "center";
    g.textBaseline = "middle";
    g.fillText(label, lx, ly);
    g.textAlign = "left";
    g.textBaseline = "alphabetic";
  };
  // Side-by-side when wind and current come from about the same way.
  const close = Math.abs(((wind.from - cur.from + 540) % 360) - 180) < 25;
  if (wind.v > 0)
    inflow(wind.from, "#2f5f8a", close && cur.v > 0 ? -12 : 0, 0.95, "wind");
  if (cur.v > 0)
    inflow(cur.from, "#2b7a6a", close && wind.v > 0 ? 12 : 0, 0.8, "current");
  drawTurtleSprite(g, cx, cy, r, knobs.heading.value, knobs.sail0.value, 2.5);
  drawCompassRose(g, W - 42, 32);
  if (wind.v > 0)
    drawFlowArrow(
      g,
      26,
      26,
      wind.from + 180,
      "#2f5f8a",
      `wind ${wind.v} m/s from ${wind.from}° (${compassName(wind.from)})`,
    );
  if (cur.v > 0)
    drawFlowArrow(
      g,
      26,
      62,
      cur.from + 180,
      "#2b7a6a",
      `current ${cur.v} m/s from ${cur.from}° (${compassName(cur.from)})`,
    );
  g.font = "11px Mulish, sans-serif";
  g.fillStyle = "#4d6f73";
  g.fillText(
    `Preview: bow ${knobs.heading.value}°, sail at start ${knobs.sail0.value > 0 ? "+" : ""}${knobs.sail0.value}°. Not run yet.`,
    10,
    H - 10,
  );
}
function drawTrack(run, k) {
  const { g, W, H } = trackCanvas();
  const s = run.samples,
    sc = run.scenario;
  const dest = run.destination;
  const xs = [0, ...s.x_m],
    ys = [0, ...s.y_m];
  if (dest) {
    xs.push(dest.x_m - dest.arrival_radius_m, dest.x_m + dest.arrival_radius_m);
    ys.push(dest.y_m - dest.arrival_radius_m, dest.y_m + dest.arrival_radius_m);
  }
  let x0 = Math.min(...xs),
    x1 = Math.max(...xs),
    y0 = Math.min(...ys),
    y1 = Math.max(...ys);
  const span = Math.max(x1 - x0, y1 - y0, 2);
  const mx = (x0 + x1) / 2,
    my = (y0 + y1) / 2,
    margin = 40;
  const scale = Math.min((W - 2 * margin) / span, (H - 2 * margin) / span);
  const P = (x, y) => [W / 2 + (x - mx) * scale, H / 2 - (y - my) * scale];
  // Grid.
  const step = niceStep(span);
  g.strokeStyle = "#c3d7d9";
  g.lineWidth = 1;
  g.font = "11px Mulish, sans-serif";
  g.fillStyle = "#4d6f73";
  for (
    let gx = Math.floor((mx - W / scale / 2) / step) * step;
    gx < mx + W / scale / 2;
    gx += step
  ) {
    const [px] = P(gx, 0);
    g.beginPath();
    g.moveTo(px, 0);
    g.lineTo(px, H);
    g.stroke();
  }
  for (
    let gy = Math.floor((my - H / scale / 2) / step) * step;
    gy < my + H / scale / 2;
    gy += step
  ) {
    const [, py] = P(0, gy);
    g.beginPath();
    g.moveTo(0, py);
    g.lineTo(W, py);
    g.stroke();
  }
  g.fillText(`grid ${step} m · north up`, 8, H - 8);
  // Destination: amber ring = arrival radius.
  const AMBER = "#b07a12";
  if (dest) {
    const [dx, dy] = P(dest.x_m, dest.y_m);
    g.strokeStyle = AMBER;
    g.fillStyle = "rgba(176,122,18,0.12)";
    g.lineWidth = 2;
    g.setLineDash([5, 4]);
    g.beginPath();
    g.arc(dx, dy, Math.max(dest.arrival_radius_m * scale, 8), 0, 2 * Math.PI);
    g.fill();
    g.stroke();
    g.setLineDash([]);
    g.fillStyle = AMBER;
    g.beginPath();
    g.arc(dx, dy, 3, 0, 2 * Math.PI);
    g.fill();
  }
  // Track, darkening with time.
  const n = s.t_s.length;
  g.lineWidth = 2.5;
  for (let i = 1; i < n; i++) {
    const f = i / n;
    g.strokeStyle = `rgb(${Math.round(150 - 127 * f)},${Math.round(190 - 129 * f)},${Math.round(175 - 115 * f)})`;
    g.beginPath();
    g.moveTo(...P(s.x_m[i - 1], s.y_m[i - 1]));
    g.lineTo(...P(s.x_m[i], s.y_m[i]));
    g.stroke();
  }
  // Where it first entered the arrival circle.
  // (Skipped when the trip ended there: the turtle itself marks it.)
  if (dest?.arrived && !run.stopped_at_destination) {
    const i = s.t_s.indexOf(dest.arrival_t_s);
    const [ax, ay] = P(s.x_m[i], s.y_m[i]);
    g.fillStyle = AMBER;
    g.strokeStyle = "#fff";
    g.lineWidth = 2;
    g.beginPath();
    g.arc(ax, ay, 5, 0, 2 * Math.PI);
    g.fill();
    g.stroke();
    g.font = "600 11px Mulish, sans-serif";
    g.fillText(`arrived ${clock(dest.arrival_t_s)}`, ax + 9, ay + 4);
    g.font = "11px Mulish, sans-serif";
  }
  const turtle = (...args) => drawTurtleSprite(g, ...args);
  const dot = (x, y, colour) => {
    g.fillStyle = colour;
    g.strokeStyle = "#ffffff";
    g.lineWidth = 2;
    g.beginPath();
    g.arc(x, y, 6, 0, 2 * Math.PI);
    g.fill();
    g.stroke();
  };
  // Small turtles along the track show how the sail was set.
  const every = Math.max(1, Math.round(n / 12));
  for (let i = every; i < n - every / 2; i += every)
    turtle(...P(s.x_m[i], s.y_m[i]), 4, s.heading_deg[i], s.sail_deg[i], 1);
  dot(...P(0, 0), "#2e9a4e");
  dot(...P(s.x_m[n - 1], s.y_m[n - 1]), "#c9473a");
  // The turtle at the slider's time.
  turtle(...P(s.x_m[k], s.y_m[k]), 9, s.heading_deg[k], s.sail_deg[k], 2);
  drawCompassRose(g, W - 42, 32);
  // Key, bottom right; wraps to a second row on narrow screens.
  g.font = "11px Mulish, sans-serif";
  g.textAlign = "right";
  let kx = W - 10,
    ky = H - 8;
  const key = (label, draw) => {
    const need = g.measureText(label).width + 34;
    if (kx - need < W * 0.3 && kx < W - 10) {
      kx = W - 10;
      ky -= 20;
    }
    g.fillStyle = "#4d6f73";
    g.fillText(label, kx, ky);
    kx -= g.measureText(label).width + 12;
    draw(kx, ky - 4);
    kx -= 22;
  };
  key(
    turtleArt.body
      ? "turtle from above (long bar = sail)"
      : "turtle (arrow = bow, line = sail)",
    (x, y) => turtle(x, y, 5, 0, 0, 1),
  );
  if (dest)
    key("destination", (x, y) => {
      g.strokeStyle = AMBER;
      g.lineWidth = 2;
      g.setLineDash([3, 2]);
      g.beginPath();
      g.arc(x, y, 6, 0, 2 * Math.PI);
      g.stroke();
      g.setLineDash([]);
    });
  key("end", (x, y) => dot(x, y, "#c9473a"));
  key("start", (x, y) => dot(x, y, "#2e9a4e"));
  g.textAlign = "left";
  const arrow = (...args) => drawFlowArrow(g, ...args);
  if (sc.wind_speed_mps > 0)
    arrow(
      26,
      26,
      sc.wind_from_deg + 180,
      "#2f5f8a",
      `wind ${sc.wind_speed_mps} m/s from ${sc.wind_from_deg}° (${compassName(sc.wind_from_deg)})`,
    );
  if (sc.current_speed_mps > 0)
    arrow(
      26,
      62,
      sc.current_from_deg + 180,
      "#2b7a6a",
      `current ${sc.current_speed_mps} m/s from ${sc.current_from_deg}° (${compassName(sc.current_from_deg)})`,
    );
}
loadScenarios().catch((e) => status("Scenarios: " + e.message, true));
