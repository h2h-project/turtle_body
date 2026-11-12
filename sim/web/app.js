import * as THREE from "three";
import { OrbitControls } from "./vendor/OrbitControls.js";
const $ = (id) => document.getElementById(id);
const state = {
  config: null,
  geometry: null,
  result: null,
  revision: 0,
  busy: false,
};
const number = (v) => (v === "" ? null : Number(v));
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
function status(message, error = false) {
  $("status").textContent = message;
  $("status").classList.toggle("error", error);
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
function vector(parent, title, value, change) {
  const l = text("label", title),
    row = document.createElement("div");
  row.className = "vector";
  const v = value ? [...value] : [null, null, null];
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
      changed();
    };
    row.append(i);
  }
  l.append(row);
  parent.append(l);
}
function changed() {
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
    $("missing").replaceChildren(
      ...(missing.length ? missing : ["Ready to calculate."]).map((v) =>
        text("li", v),
      ),
    );
    $("solve").disabled = state.busy || missing.length > 0;
  } catch (e) {
    $("solve").disabled = true;
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
  cg.visible = false;
  cb.visible = false;
  for (const id of ["front", "rear", "attitude"]) $(id).textContent = "—";
  $("results").textContent =
    "Measurements changed or no calculation yet. Calculate to show the current equilibrium.";
  $("graphs").replaceChildren();
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
  $("components").replaceChildren();
  for (const p of c.components) {
    const meta = state.geometry?.components?.find((m) => m.id === p.id);
    const d = document.createElement("details"),
      s = document.createElement("summary");
    s.append(text("span", meta?.label ?? p.id));
    const mass = text(
      "span",
      p.installed
        ? p.mass_kg === null
          ? "mass needed"
          : p.mass_kg + " kg"
        : "absent",
    );
    mass.className = "mass";
    s.append(mass);
    d.append(s);
    const b = document.createElement("div");
    d.append(b);
    check(b, "Installed in this build", p.installed, (v) => {
      p.installed = v;
      mass.textContent = v
        ? p.mass_kg === null
          ? "mass needed"
          : p.mass_kg + " kg"
        : "absent";
    });
    const grid = document.createElement("div");
    grid.className = "grid2";
    b.append(grid);
    field(
      grid,
      "Measured group mass · kg",
      p.mass_kg,
      (v) => {
        p.mass_kg = v;
        mass.textContent = v === null ? "mass needed" : v + " kg";
      },
      "number",
    );
    select(
      grid,
      "Displacement",
      p.displacement,
      [
        ["unknown", "Choose treatment"],
        ["solid", "Exposed solid"],
        ["sealed", "Sealed bottle / housing"],
        ["flooded", "Flooded hollow vessel"],
        ["contained", "Inside another displaced envelope"],
      ],
      (v) => (p.displacement = v),
    );
    select(
      b,
      "Centre of mass source",
      p.com_source,
      [
        ["measured", "Measured balance point"],
        ...(meta?.kind === "uniform" ||
        ["front_fin", "rear_fin", "front_support"].includes(p.id)
          ? [["cad_uniform", "CAD centre · uniform material assumption"]]
          : []),
      ],
      (v) => (p.com_source = v),
    );
    if (meta)
      b.append(
        text(
          "p",
          "CAD centre (m): " +
            meta.centroid_m.map((n) => n.toFixed(4)).join(", "),
        ),
      );
    vector(b, "Measured group centre · m", p.com_m, (v) => (p.com_m = v));
    vector(
      b,
      "Move whole group from CAD · m",
      p.offset_m,
      (v) => (p.offset_m = v ?? [0, 0, 0]),
    );
    field(
      b,
      "Uniform shell thickness · mm (ordinary flooded bottles only)",
      p.uniform_shell_mm,
      (v) => (p.uniform_shell_mm = v),
      "number",
    );
    field(
      b,
      "Notes / enclosure / included equipment",
      p.notes,
      (v) => (p.notes = v),
    );
    check(
      b,
      "I confirm this displacement shape and sealed/flooded status match the physical group.",
      p.geometry_confirmed,
      (v) => (p.geometry_confirmed = v),
    );
    const upload = text(
      "label",
      "Optional replacement displacement STL · metres in body coordinates",
    );
    const file = document.createElement("input");
    file.type = "file";
    file.accept = ".stl";
    file.onchange = async () => {
      try {
        if (!file.files[0]) return;
        const r = await fetch("/api/mesh-upload/" + p.id, {
          method: "POST",
          body: file.files[0],
        });
        const data = await r.json();
        if (!r.ok) throw new Error(data.detail);
        p.displacement_mesh = data.id;
        changed();
        status(
          "Replacement displacement mesh uploaded. It is saved with this configuration.",
        );
      } catch (e) {
        status(e.message, true);
      }
    };
    upload.append(file);
    b.append(upload);
    if (p.displacement_mesh) {
      b.append(text("p", "Replacement: " + p.displacement_mesh));
      const remove = text("button", "Use CAD mesh instead");
      remove.onclick = () => {
        p.displacement_mesh = null;
        renderForm();
        changed();
      };
      b.append(remove);
    }
    $("components").append(d);
  }
  renderPayloads();
  renderTrials();
  void readiness();
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
    if (id === "density") {state.config.density_source="measured";$("density_source").value="measured";}
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
    await api("config", "PUT", state.config);
    status(
      "Measurements saved locally. Use Download YAML for a portable copy.",
    );
  } catch (e) {
    status(e.message, true);
  }
};
$("download").onclick = async () => {
  try {
    await api("config", "PUT", state.config);
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
  const rev = state.revision;
  try {
    if (kind === "solve") {
      clearResult();
      await api("config", "PUT", state.config);
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
      );
    } else if (rev !== state.revision) {
      status("Measurements changed during calculation. Old result discarded.");
    } else {
      showResult(j.result);
      status(
        j.result.status === "equilibrium"
          ? "Calculation complete. Compare with independent water trials."
          : (j.result.message ?? j.result.status),
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
const centre = new THREE.Mesh(
  new THREE.PlaneGeometry(1.3, 0.8),
  new THREE.MeshBasicMaterial({
    color: 0xa47435,
    transparent: true,
    opacity: 0.12,
    side: THREE.DoubleSide,
    depthWrite: false,
  }),
);
bodyGroup.add(centre);
const axes = new THREE.AxesHelper(0.15);
bodyGroup.add(axes);
const water = new THREE.Mesh(
  new THREE.PlaneGeometry(3, 3),
  new THREE.MeshPhongMaterial({
    color: 0x649baf,
    transparent: true,
    opacity: 0.3,
    side: THREE.DoubleSide,
    depthWrite: false,
  }),
);
water.visible = false;
scene.add(water);
function marker(color) {
  const m = new THREE.Mesh(
    new THREE.SphereGeometry(0.009, 16, 12),
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
function updatePayloadView() {
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
  ctx.font = "24px sans-serif";
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
$("centre").onclick = () => (centre.visible = !centre.visible);
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
      hit.object.userData.label + " · double click to focus";
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
    m.material.dispose();
  }
  for (const part of state.geometry.components) {
    const data = await api("mesh/" + part.id),
      g = new THREE.BufferGeometry();
    g.setAttribute(
      "position",
      new THREE.Float32BufferAttribute(data.vertices.flat(), 3),
    );
    g.setIndex(data.faces.flat());
    g.computeVertexNormals();
    const bottle = part.kind === "bottle" || part.kind === "housing";
    const m = new THREE.Mesh(
      g,
      new THREE.MeshPhongMaterial({
        color: bottle
          ? 0x86bfbe
          : part.id.includes("fin")
            ? 0x9b9c62
            : 0xb79363,
        transparent: bottle,
        opacity: bottle ? 0.4 : 1,
        side: THREE.DoubleSide,
        flatShading: true,
      }),
    );
    m.userData = part;
    meshGroup.add(m);
  }
  status("CAD ready. Complete the measurement survey to calculate flotation.");
}
function showResult(result) {
  state.result = result;
  if (result.status !== "equilibrium") {
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
  for (const part of meshGroup.children) {
    const config = state.config.components.find(
      (c) => c.id === part.userData.id,
    );
    part.visible = config.installed;
    part.position.fromArray(config.offset_m);
  }
  for (const fin of ["front", "rear"]) {
    const rr = e.rulers
      .filter((r) => r.id.startsWith(fin))
      .sort(
        (a, b) =>
          (a.id.endsWith("port") ? -1 : 1) - (b.id.endsWith("port") ? -1 : 1),
      );
    $(fin).textContent = rr.length
      ? rr
          .map((r) =>
            r.in_range
              ? (r.reading_mm >= 0 ? "+" : "") + r.reading_mm.toFixed(1)
              : "out of range",
          )
          .join(" / ")
      : "absent";
  }
  $("attitude").textContent =
    e.roll_deg.toFixed(1) + " / " + e.pitch_deg.toFixed(1);
  $("results").replaceChildren(
    text(
      "p",
      `Mass ${result.mass_kg.toFixed(3)} kg · displacement ${(e.volume_m3 * 1000).toFixed(3)} litres · ${e.stable ? "restoring about both local axes" : "check stability below"}. Red = centre of mass; blue = centre of buoyancy.`,
    ),
    text("p", result.search_note),
  );
  if (result.equilibria.length > 1) {
    $("results").append(
      text(
        "p",
        `${result.equilibria.length} distinct equilibria found; all poses are retained in the saved result.`,
      ),
    );
    select(
      $("results"),
      "Inspect equilibrium",
      String(result.selected),
      result.equilibria.map((pose, i) => [
        String(i),
        `${i + 1}: roll ${pose.roll_deg.toFixed(1)}°, pitch ${pose.pitch_deg.toFixed(1)}°`,
      ]),
      (v) => {
        result.selected = Number(v);
        showResult(result);
      },
    );
    const chooser = $("results").querySelector("select");
    chooser.onchange = () => {
      result.selected = Number(chooser.value);
      showResult(result);
    };
  }
  for (const w of result.warnings) $("results").append(text("p", w));
  $("graphs").replaceChildren();
  for (const curve of e.stability) {
    const f = document.createElement("figure");
    f.append(text("figcaption", curve.axis + " · " + curve.classification));
    const vals = curve.samples,
      limit = Math.max(...vals.map((s) => Math.abs(s.moment_nm)), 0.000001);
    const points = vals
      .map(
        (s) => `${100 + s.offset_deg * 18},${50 - (s.moment_nm / limit) * 42}`,
      )
      .join(" ");
    f.insertAdjacentHTML(
      "beforeend",
      `<svg viewBox="0 0 200 100" role="img" aria-label="Restoring moment versus angle"><path d="M10 50H190M100 5V95" stroke="#a5b8a4"/><polyline points="${points}" stroke="#315d4c" fill="none" stroke-width="2"/></svg>`,
    );
    f.append(text("small", `−5° to +5° · ±${limit.toPrecision(3)} N·m`));
    $("graphs").append(f);
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
