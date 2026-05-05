const app = {
  tab: "today",
  route: "tab",
  routeParams: {},
  sheet: null,
  toast: "",
  onboardingStep: 0,
  selectedCareType: "medicine",
  form: {
    petId: "momo",
    name: "Heart med",
    dose: "1 tablet",
    time: "8:00 AM",
    repeat: "Daily",
    note: "After breakfast",
  },
  formErrors: {},
  notificationStatus: "On",
  subscriptionStatus: "Free",
  pets: [
    { id: "momo", name: "Momo", species: "Cat", age: "12 years", weight: "4.2 kg", initial: "M" },
    { id: "luna", name: "Luna", species: "Dog", age: "7 years", weight: "12.8 kg", initial: "L" },
    { id: "rio", name: "Rio", species: "Rabbit", age: "4 years", weight: "1.9 kg", initial: "R" },
  ],
  reminders: [
    {
      id: "heart-med",
      petId: "momo",
      type: "medicine",
      title: "Heart med",
      detail: "1 tablet, after breakfast",
      time: "8:00",
      status: "due",
      completedBy: "",
    },
    {
      id: "breakfast",
      petId: "momo",
      type: "food",
      title: "Breakfast notes",
      detail: "Ate half portion",
      time: "9:00",
      status: "upcoming",
      completedBy: "",
    },
    {
      id: "eye-drops",
      petId: "rio",
      type: "medicine",
      title: "Rio eye drops",
      detail: "2 drops, left eye",
      time: "12:30",
      status: "upcoming",
      completedBy: "",
    },
    {
      id: "vet-visit",
      petId: "luna",
      type: "visit",
      title: "Luna vet visit",
      detail: "Green Vet Clinic",
      time: "16:00",
      status: "upcoming",
      completedBy: "",
    },
  ],
  records: [
    { id: "rec-1", type: "medicine", title: "Heart med done", detail: "Completed by Alex", meta: "Today" },
    { id: "rec-2", type: "food", title: "Ate less than usual", detail: "Saved as owner note", meta: "Mon" },
    { id: "rec-3", type: "visit", title: "Vaccine record", detail: "Certificate attached", meta: "Apr 22" },
  ],
};

const careTypes = [
  { id: "medicine", label: "Med" },
  { id: "food", label: "Food" },
  { id: "weight", label: "Weight" },
  { id: "visit", label: "Visit" },
];

const ONBOARDING_STORAGE_KEY = "tendPetsOnboardingComplete";

function storageGet(key) {
  try {
    return window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

function storageSet(key, value) {
  try {
    window.localStorage.setItem(key, value);
  } catch (_) {
    // Storage can be blocked in private contexts; the prototype still works.
  }
}

function hasCompletedOnboarding() {
  return storageGet(ONBOARDING_STORAGE_KEY) === "true";
}

const onboardingSteps = [
  {
    eyebrow: "Why it matters",
    title: "Care is hard to remember when life is already full.",
    body: "Medication, food changes, weight shifts, vaccines, and vet visits all live in different places. Tend Pets turns them into one calm daily routine.",
    stat: "0 missed routines is the goal",
    cards: [
      ["Medication", "Know what is due, done, snoozed, or skipped."],
      ["Visits", "Keep notes ready before the appointment."],
    ],
  },
  {
    eyebrow: "Today first",
    title: "Open the app and know exactly what needs care next.",
    body: "The Today screen is built for busy mornings: one pet, one due card, and three clear actions.",
    stat: "Done, Snooze, Skip",
    cards: [
      ["Done", "Record who completed the care."],
      ["Snooze", "Move a reminder without losing it."],
    ],
  },
  {
    eyebrow: "For family and vets",
    title: "A cleaner handoff when more than one person helps.",
    body: "Shared care notes reduce duplicate messages, and records become a simple vet summary instead of a memory test.",
    stat: "Vet-ready history",
    cards: [
      ["Family", "See who completed each routine."],
      ["Records", "Medication, weight, visit, and vaccine history."],
    ],
  },
  {
    eyebrow: "Start small",
    title: "Add one pet and one routine. That is enough to begin.",
    body: "You do not need to organize everything today. Start with the care task that would be worst to forget.",
    stat: "First reminder in under a minute",
    cards: [
      ["Momo", "Example pet profile is ready."],
      ["Heart med", "Use this as your first medication routine."],
    ],
  },
];

function pet(id) {
  return app.pets.find((item) => item.id === id) || app.pets[0];
}

function reminder(id) {
  return app.reminders.find((item) => item.id === id);
}

function escapeText(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;",
  })[char]);
}

function row({ dot = "", title, detail, meta = "", action = "", route = "", id = "" }) {
  const attrs = [
    action ? `data-action="${action}"` : "",
    route ? `data-route="${route}"` : "",
    id ? `data-id="${id}"` : "",
  ].filter(Boolean).join(" ");

  const tag = attrs ? "button" : "div";

  return `
    <${tag} class="ios-row ${attrs ? "tappable" : ""}" ${attrs}>
      <span class="row-dot ${dot}"></span>
      <span class="row-copy">
        <span class="row-main">${escapeText(title)}</span>
        <span class="row-detail">${escapeText(detail)}</span>
      </span>
      <span class="row-meta">${escapeText(meta)}</span>
    </${tag}>
  `;
}

function nav(title, options = {}) {
  const left = options.back
    ? `<button class="nav-action" data-action="back" aria-label="Back">‹</button>`
    : `<span></span>`;
  const rightClass = options.right && options.right.length > 2 ? "nav-action text-action" : "nav-action";
  const right = options.right
    ? `<button class="${rightClass}" ${options.rightAttrs || ""}>${options.right}</button>`
    : `<span></span>`;

  return `
    <div class="nav-row">
      ${left}
      ${right}
    </div>
    <h2 class="large-title">${escapeText(title)}</h2>
  `;
}

function statusPill(text, tone = "") {
  return `<span class="status-pill ${tone}">${escapeText(text)}</span>`;
}

function renderOnboarding() {
  const step = onboardingSteps[app.onboardingStep] || onboardingSteps[0];
  const isLast = app.onboardingStep === onboardingSteps.length - 1;
  const seenBefore = hasCompletedOnboarding();

  return `
    <section class="onboarding-flow" aria-label="Tend Pets onboarding">
      <div class="onboarding-top">
        <div class="onboarding-mark">
          <div class="care-ring"><div class="pet-face">M</div></div>
          <span>Tend Pets</span>
        </div>
        <button class="text-link inline" data-action="skipOnboarding">
          ${seenBefore ? "Skip" : "Skip for now"}
        </button>
      </div>

      <div class="onboarding-hero">
        <p class="onboarding-eyebrow">${escapeText(step.eyebrow)}</p>
        <h2>${escapeText(step.title)}</h2>
        <p>${escapeText(step.body)}</p>
      </div>

      <div class="onboarding-proof">
        <span>${escapeText(step.stat)}</span>
      </div>

      <div class="onboarding-cards">
        ${step.cards.map(([title, detail]) => `
          <div>
            <strong>${escapeText(title)}</strong>
            <span>${escapeText(detail)}</span>
          </div>
        `).join("")}
      </div>

      <div class="onboarding-dots" aria-label="Onboarding progress">
        ${onboardingSteps.map((_, index) => `<span class="${index === app.onboardingStep ? "active" : ""}"></span>`).join("")}
      </div>

      <div class="onboarding-actions">
        ${app.onboardingStep > 0 ? `<button class="ios-button" data-action="prevOnboarding">Back</button>` : `<span></span>`}
        <button class="ios-button primary" data-action="${isLast ? "finishOnboarding" : "nextOnboarding"}">
          ${isLast ? "Add first care" : "Continue"}
        </button>
      </div>
    </section>
  `;
}

function progress() {
  const done = app.reminders.filter((item) => item.status === "done").length;
  const total = app.reminders.length;
  return Math.round((done / total) * 100);
}

function renderToday() {
  const due = app.reminders.find((item) => item.status === "due") || app.reminders[0];
  const duePet = pet(due.petId);
  const percent = progress();

  return `
    ${nav("Today", { right: "+", rightAttrs: 'data-native-tab="add" aria-label="Add care"' })}
    <button class="summary-strip tappable" data-route="pet" data-id="${duePet.id}">
      <div class="care-ring"><div class="pet-face">${duePet.initial}</div></div>
      <div>
        <div class="summary-title">${escapeText(duePet.name)}</div>
        <div class="summary-sub">Tue, May 5 - ${app.reminders.filter((item) => item.status === "done").length} of ${app.reminders.length} done</div>
      </div>
      <span class="progress-pill">${percent}%</span>
    </button>

    <div class="section-label">Due now</div>
    ${renderCareCard(due)}

    <div class="section-label">Later today</div>
    <div class="ios-list">
      ${app.reminders.filter((item) => item.id !== due.id).map((item) => row({
        dot: item.type,
        title: item.title,
        detail: item.detail,
        meta: item.time,
        route: "reminder",
        id: item.id,
      })).join("")}
    </div>
  `;
}

function renderCareCard(item) {
  const owner = pet(item.petId);
  const isDone = item.status === "done";
  const isSkipped = item.status === "skipped";
  return `
    <div class="care-card ${isDone ? "completed" : ""}">
      <div class="card-topline">
        ${statusPill(isDone ? "Done" : isSkipped ? "Skipped" : "Due now", isDone ? "success" : "")}
        <span>${escapeText(item.time)}</span>
      </div>
      <div class="row-main">${escapeText(owner.name)}'s ${escapeText(item.title)}</div>
      <div class="row-detail">${escapeText(item.detail)}</div>
      ${isDone || isSkipped ? `
        <div class="completion-note">${isDone ? `Completed by ${escapeText(item.completedBy || "Alex")}` : "Skipped with note"}</div>
        <button class="ios-button" data-action="undo" data-id="${item.id}">Undo</button>
      ` : `
        <div class="care-actions">
          <button class="ios-button primary" data-action="done" data-id="${item.id}">Done</button>
          <button class="ios-button" data-action="snooze" data-id="${item.id}">Snooze</button>
          <button class="ios-button" data-action="skip" data-id="${item.id}">Skip</button>
        </div>
      `}
    </div>
  `;
}

function renderPets() {
  return `
    ${nav("Pets", { right: "+", rightAttrs: 'data-action="addPet" aria-label="Add pet"' })}
    <div class="pet-stack">
      ${app.pets.map((item) => `
        <button class="pet-card tappable" data-route="pet" data-id="${item.id}">
          <div class="care-ring"><div class="pet-face">${item.initial}</div></div>
          <div>
            <div class="summary-title">${escapeText(item.name)}</div>
            <div class="summary-sub">${escapeText(item.species)} - ${escapeText(item.age)} - ${escapeText(item.weight)}</div>
          </div>
          <span class="row-meta">Open</span>
        </button>
      `).join("")}
    </div>
    <div class="section-label">Family handoff</div>
    <div class="ios-list">
      ${row({ dot: "medicine", title: "Alex", detail: "Completed morning medication", meta: "8:14" })}
      ${row({ dot: "food", title: "Mina", detail: "Added appetite note", meta: "9:05" })}
    </div>
  `;
}

function renderPetDetail() {
  const current = pet(app.routeParams.id);
  const active = app.reminders.filter((item) => item.petId === current.id);
  return `
    ${nav("Pet Profile", { back: true, right: "Edit", rightAttrs: 'data-action="editPet"' })}
    <div class="profile-hero">
      <div class="care-ring large"><div class="pet-face">${current.initial}</div></div>
      <div class="profile-name">${escapeText(current.name)}</div>
      <div class="summary-sub">${escapeText(current.species)} - ${escapeText(current.age)} - ${escapeText(current.weight)}</div>
    </div>

    <div class="metric-grid">
      <button class="metric-card" data-route="records"><strong>${active.length}</strong><span>Active care</span></button>
      <button class="metric-card" data-route="calendar"><strong>May 5</strong><span>Next visit</span></button>
    </div>

    <div class="section-label">Active meds and care</div>
    <div class="ios-list">
      ${active.map((item) => row({
        dot: item.type,
        title: item.title,
        detail: item.detail,
        meta: item.time,
        route: "reminder",
        id: item.id,
      })).join("")}
    </div>

    <div class="section-label">Weight trend</div>
    <button class="chart-card tappable" data-route="records">
      <div class="row-main">${escapeText(current.weight)}</div>
      <div class="row-detail">Stable over the last 30 days</div>
      <div class="chart-line"></div>
    </button>
  `;
}

function renderReminderDetail() {
  const item = reminder(app.routeParams.id) || app.reminders[0];
  const owner = pet(item.petId);
  return `
    ${nav(item.title, { back: true, right: "Edit", rightAttrs: 'data-action="editReminder"' })}
    <div class="care-card">
      <div class="card-topline">
        ${statusPill(item.status, item.status === "done" ? "success" : "")}
        <span>${escapeText(item.time)}</span>
      </div>
      <div class="row-main">${escapeText(owner.name)} - ${escapeText(item.title)}</div>
      <div class="row-detail">${escapeText(item.detail)}</div>
      <div class="care-actions">
        <button class="ios-button primary" data-action="done" data-id="${item.id}">Done</button>
        <button class="ios-button" data-action="snooze" data-id="${item.id}">Snooze</button>
        <button class="ios-button" data-action="skip" data-id="${item.id}">Skip</button>
      </div>
    </div>
    <div class="section-label">History</div>
    <div class="ios-list">
      ${row({ dot: item.type, title: "Last completed", detail: "Completed by Alex", meta: "Yesterday" })}
      ${row({ dot: "food", title: "Related food note", detail: "Ate half portion", meta: "Mon" })}
    </div>
  `;
}

function selectedCareConfig() {
  const configs = {
    medicine: {
      nameLabel: "Name",
      amountLabel: "Dose",
      amountRequired: true,
      amountError: "Enter the dose from your vet label",
      noteLabel: "Instructions",
      notificationTitle: "Notify at medication time",
      notificationDetail: "Done and Snooze available from notification",
      saveLabel: "Save medication",
    },
    food: {
      nameLabel: "Meal",
      amountLabel: "Amount",
      amountRequired: false,
      amountError: "",
      noteLabel: "Food note",
      notificationTitle: "Notify at meal time",
      notificationDetail: "Useful for appetite and diet changes",
      saveLabel: "Save food reminder",
    },
    weight: {
      nameLabel: "Record name",
      amountLabel: "Weight",
      amountRequired: false,
      amountError: "",
      noteLabel: "Weight note",
      notificationTitle: "Notify to weigh",
      notificationDetail: "Keeps trends ready for vet visits",
      saveLabel: "Save weight reminder",
    },
    visit: {
      nameLabel: "Visit reason",
      amountLabel: "Clinic",
      amountRequired: false,
      amountError: "",
      noteLabel: "Visit note",
      notificationTitle: "Notify before visit",
      notificationDetail: "Prepare questions, meds, and recent records",
      saveLabel: "Save visit",
    },
  };
  return configs[app.selectedCareType] || configs.medicine;
}

function renderAdd() {
  const config = selectedCareConfig();
  return `
    ${nav("Add Care", { right: "Save", rightAttrs: 'data-action="saveCare"' })}
    <div class="segmented-control" role="tablist">
      ${careTypes.map((type) => `
        <button class="${app.selectedCareType === type.id ? "active" : ""}" data-action="careType" data-id="${type.id}">${type.label}</button>
      `).join("")}
    </div>
    <div class="section-label">Reminder</div>
    <div class="grouped-form">
      <label class="form-row">
        <span>Pet</span>
        <select data-form="petId">
          ${app.pets.map((item) => `<option value="${item.id}" ${app.form.petId === item.id ? "selected" : ""}>${escapeText(item.name)}</option>`).join("")}
        </select>
      </label>
      <label class="form-row ${app.formErrors.name ? "invalid" : ""}">
        <span>${escapeText(config.nameLabel)}</span>
        <input data-form="name" value="${escapeText(app.form.name)}" />
        ${app.formErrors.name ? `<small>${escapeText(app.formErrors.name)}</small>` : ""}
      </label>
      <label class="form-row ${app.formErrors.dose ? "invalid" : ""}">
        <span>${escapeText(config.amountLabel)}</span>
        <input data-form="dose" value="${escapeText(app.form.dose)}" />
        ${app.formErrors.dose ? `<small>${escapeText(app.formErrors.dose)}</small>` : ""}
      </label>
      <label class="form-row">
        <span>Time</span>
        <select data-form="time">
          ${["7:00 AM", "8:00 AM", "12:30 PM", "4:00 PM", "7:00 PM"].map((time) => `<option ${app.form.time === time ? "selected" : ""}>${time}</option>`).join("")}
        </select>
      </label>
      <label class="form-row">
        <span>Repeat</span>
        <select data-form="repeat">
          ${["Daily", "Weekly", "Every 3 days", "Custom"].map((rule) => `<option ${app.form.repeat === rule ? "selected" : ""}>${rule}</option>`).join("")}
        </select>
      </label>
      <label class="form-row stacked">
        <span>${escapeText(config.noteLabel)}</span>
        <textarea data-form="note">${escapeText(app.form.note)}</textarea>
      </label>
    </div>
    <div class="section-label">Notifications</div>
    <div class="ios-list">
      ${row({ dot: app.selectedCareType, title: config.notificationTitle, detail: config.notificationDetail, meta: app.notificationStatus })}
      ${row({ dot: "visit", title: "Snooze options", detail: "10 min, 30 min, 1 hour", meta: "Edit" })}
    </div>
    <button class="ios-button primary full" data-action="saveCare">${escapeText(config.saveLabel)}</button>
  `;
}

function renderRecords() {
  return `
    ${nav("Records", { right: "PDF", rightAttrs: 'data-route="vetSummary"' })}
    <div class="care-card">
      <div class="row-main">Vet summary</div>
      <div class="row-detail">Last 30 days, active meds, skipped care, weight trend, and visit notes.</div>
      <button class="ios-button primary full" data-route="vetSummary">Prepare PDF</button>
    </div>
    <div class="section-label">Timeline</div>
    <div class="ios-list">
      ${app.records.map((item) => row({
        dot: item.type,
        title: item.title,
        detail: item.detail,
        meta: item.meta,
        route: "recordDetail",
        id: item.id,
      })).join("")}
    </div>
    <button class="text-link" data-route="calendar">Open calendar view</button>
  `;
}

function renderCalendar() {
  const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const leadingBlanks = 4;
  const days = [
    ...Array.from({ length: leadingBlanks }, () => null),
    ...Array.from({ length: 31 }, (_, index) => index + 1),
  ];
  return `
    ${nav("Calendar", { back: true, right: "Today", rightAttrs: 'data-native-tab="today"' })}
    <div class="calendar-card">
      <div class="calendar-head">
        <strong>May 2026</strong>
        ${statusPill("3 events")}
      </div>
      <div class="calendar-grid">
        ${weekdays.map((day) => `<span class="calendar-weekday">${day}</span>`).join("")}
        ${days.map((day) => day ? `
          <button class="calendar-day ${day === 5 ? "selected" : ""} ${[1, 3, 9, 21, 27].includes(day) ? "has-event" : ""}" data-route="calendarDay" data-id="${day}" aria-label="May ${day}">
            ${day}
          </button>
        ` : `
          <span class="calendar-day empty" aria-hidden="true"></span>
        `).join("")}
      </div>
    </div>
    <div class="section-label">May 5</div>
    <div class="ios-list">
      ${row({ dot: "medicine", title: "Heart med", detail: "Momo, after breakfast", meta: "8:00", route: "reminder", id: "heart-med" })}
      ${row({ dot: "visit", title: "Vet visit", detail: "Luna, Green Vet Clinic", meta: "16:00", route: "reminder", id: "vet-visit" })}
    </div>
  `;
}

function renderVetSummary() {
  return `
    ${nav("Vet Summary", { back: true, right: "Export", rightAttrs: 'data-action="exportPdf"' })}
    <div class="summary-document">
      <h3>Momo care summary</h3>
      <p>Prepared for Green Vet Clinic. This is a record summary only, not medical advice.</p>
      <dl>
        <dt>Active medication</dt><dd>Heart med - daily at 8:00 AM</dd>
        <dt>Skipped care</dt><dd>None in the last 7 days</dd>
        <dt>Weight</dt><dd>4.2 kg, stable</dd>
      </dl>
    </div>
    <button class="ios-button primary full" data-action="exportPdf">Export PDF</button>
    <button class="ios-button full" data-action="shareFamily">Share with family</button>
  `;
}

function renderSettings() {
  return `
    ${nav("Settings")}
    <div class="section-label">Reminders</div>
    <div class="ios-list">
      ${row({ dot: "medicine", title: "Notifications", detail: "Test reminder and recovery", meta: app.notificationStatus, action: "toggleNotifications" })}
      ${row({ dot: "visit", title: "Test notification", detail: "Send a local reminder preview", meta: "Send", action: "testNotification" })}
      ${row({ dot: "food", title: "Snooze defaults", detail: "10 min, 30 min, 1 hour", meta: "Edit", action: "editSnooze" })}
    </div>
    <div class="section-label">Subscription</div>
    <div class="ios-list">
      ${row({ title: "Tend Pets Plus", detail: "Unlimited reminders and vet summary export", meta: app.subscriptionStatus, route: "paywall" })}
      ${row({ title: "Restore Purchase", detail: "Check App Store purchase", meta: "", action: "restorePurchase" })}
    </div>
    <div class="section-label">Data and privacy</div>
    <div class="ios-list">
      ${row({ title: "Replay onboarding", detail: "See why and how Tend Pets is used", meta: "", action: "replayOnboarding" })}
      ${row({ title: "Export data", detail: "Download pet records", action: "exportData" })}
      ${row({ title: "Medical disclaimer", detail: "No veterinary medical advice", route: "disclaimer" })}
      ${row({ title: "Delete account", detail: "Remove local prototype data", action: "deleteAccount" })}
    </div>
  `;
}

function renderPaywall() {
  return `
    ${nav("Tend Pets Plus", { back: true })}
    <div class="paywall-hero">
      <div class="row-main">Keep every routine organized</div>
      <div class="row-detail">For pets with daily care, shared routines, and vet-ready records.</div>
    </div>
    <div class="ios-list">
      ${row({ dot: "medicine", title: "Unlimited reminders", detail: "Medication, visits, food, weight, vaccines" })}
      ${row({ dot: "visit", title: "Vet summary export", detail: "Prepare clean PDFs before appointments" })}
      ${row({ dot: "food", title: "Family handoff", detail: "See who completed each routine" })}
    </div>
    <div class="pricing-choice featured-choice">
      <strong>$4.99 / month</strong>
      <span>7 day free trial, then monthly renewal</span>
    </div>
    <div class="pricing-choice">
      <strong>$39.99 / year</strong>
      <span>Best for long term medication routines</span>
    </div>
    <button class="ios-button primary full" data-action="purchasePlus">Start free trial</button>
    <button class="ios-button full" data-action="restorePurchase">Restore Purchase</button>
    <p class="fine-print">Terms, Privacy, renewal price, and restore purchase must remain visible in the final StoreKit paywall.</p>
  `;
}

function renderDisclaimer() {
  return `
    ${nav("Disclaimer", { back: true })}
    <div class="summary-document">
      <h3>Records and reminders only</h3>
      <p>Tend Pets helps you record care routines and remember tasks. It does not provide diagnosis, dosage advice, treatment recommendations, or emergency triage.</p>
      <p>Always follow your veterinarian's instructions.</p>
    </div>
  `;
}

function renderRoute() {
  switch (app.route) {
    case "onboarding":
      return renderOnboarding();
    case "pet":
      return renderPetDetail();
    case "reminder":
      return renderReminderDetail();
    case "calendar":
    case "calendarDay":
      return renderCalendar();
    case "vetSummary":
      return renderVetSummary();
    case "paywall":
      return renderPaywall();
    case "disclaimer":
      return renderDisclaimer();
    case "recordDetail":
      return renderRecordDetail();
    default:
      return renderTab();
  }
}

function renderRecordDetail() {
  const record = app.records.find((item) => item.id === app.routeParams.id) || app.records[0];
  return `
    ${nav(record.title, { back: true })}
    <div class="summary-document">
      <h3>${escapeText(record.title)}</h3>
      <p>${escapeText(record.detail)}</p>
      <dl>
        <dt>Date</dt><dd>${escapeText(record.meta)}</dd>
        <dt>Pet</dt><dd>Momo</dd>
        <dt>Category</dt><dd>${escapeText(record.type)}</dd>
      </dl>
    </div>
  `;
}

function renderTab() {
  switch (app.tab) {
    case "pets":
      return renderPets();
    case "add":
      return renderAdd();
    case "records":
      return renderRecords();
    case "settings":
      return renderSettings();
    default:
      return renderToday();
  }
}

function renderSheet() {
  if (!app.sheet) return "";
  const sheets = {
    snooze: `
      <div class="sheet-title">Snooze reminder</div>
      <p>Choose when Tend Pets should remind you again.</p>
      <div class="sheet-options">
        <button class="ios-button primary" data-action="snoozeFor" data-minutes="10">10 min</button>
        <button class="ios-button" data-action="snoozeFor" data-minutes="30">30 min</button>
        <button class="ios-button" data-action="snoozeFor" data-minutes="60">1 hour</button>
      </div>
    `,
    skip: `
      <div class="sheet-title">Skip with note</div>
      <p>Keep the record useful for the next vet visit.</p>
      <div class="sheet-options vertical">
        <button class="ios-button primary" data-action="skipReason" data-reason="Pet did not eat">Pet did not eat</button>
        <button class="ios-button" data-action="skipReason" data-reason="Vet instructed">Vet instructed</button>
        <button class="ios-button" data-action="skipReason" data-reason="Owner chose to skip">Owner chose to skip</button>
      </div>
    `,
    addPet: `
      <div class="sheet-title">Add pet</div>
      <p>This prototype adds a sample bird profile so you can test multi-pet flow.</p>
      <button class="ios-button primary full" data-action="confirmAddPet">Add Kiwi</button>
    `,
    confirmDelete: `
      <div class="sheet-title">Delete account?</div>
      <p>This prototype action only clears demo completion state.</p>
      <button class="ios-button danger full" data-action="confirmDelete">Delete demo data</button>
    `,
  };

  return `
    <div class="sheet-scrim" data-action="dismissSheet"></div>
    <div class="sheet">
      <div class="sheet-handle"></div>
      ${sheets[app.sheet.kind] || ""}
      <button class="text-link" data-action="dismissSheet">Cancel</button>
    </div>
  `;
}

function renderToast() {
  return app.toast ? `<div class="toast">${escapeText(app.toast)}</div>` : "";
}

function render() {
  const screen = document.querySelector("#native-screen");
  screen.innerHTML = `<div class="screen-transition">${renderRoute()}</div>`;
  const isOnboarding = app.route === "onboarding";
  document.querySelector(".app-root").classList.toggle("is-onboarding", isOnboarding);
  screen.classList.toggle("onboarding-screen", isOnboarding);
  document.querySelectorAll(".tabbar-item").forEach((item) => {
    item.classList.toggle("active", item.dataset.nativeTab === app.tab);
  });
  document.querySelector(".sheet")?.remove();
  document.querySelector(".sheet-scrim")?.remove();
  document.querySelector(".toast")?.remove();
  document.querySelector(".app-root").insertAdjacentHTML("beforeend", renderSheet() + renderToast());
}

function setTab(tab) {
  app.tab = tab;
  app.route = "tab";
  app.routeParams = {};
  app.sheet = null;
  render();
}

function setRoute(route, params = {}) {
  app.route = route;
  app.routeParams = params;
  app.sheet = null;
  render();
}

function completeOnboarding(destination = "today") {
  storageSet(ONBOARDING_STORAGE_KEY, "true");
  app.onboardingStep = 0;
  app.route = "tab";
  app.routeParams = {};
  app.sheet = null;
  app.tab = destination;
  render();
}

function toast(message) {
  app.toast = message;
  render();
  window.clearTimeout(toast.timer);
  toast.timer = window.setTimeout(() => {
    app.toast = "";
    render();
  }, 1800);
}

function markReminder(id, status) {
  const item = reminder(id);
  if (!item) return;
  item.status = status;
  item.completedBy = status === "done" ? "Alex" : "";
  if (status === "done") {
    app.records.unshift({ id: `rec-${Date.now()}`, type: item.type, title: `${item.title} done`, detail: "Completed by Alex", meta: "Now" });
    toast("Care marked done");
  }
  render();
}

function saveFormFromInputs() {
  document.querySelectorAll("[data-form]").forEach((input) => {
    app.form[input.dataset.form] = input.value.trim();
  });
}

function saveCare() {
  saveFormFromInputs();
  const config = selectedCareConfig();
  app.formErrors = {};
  if (!app.form.name) app.formErrors.name = "Enter a care name";
  if (config.amountRequired && !app.form.dose) app.formErrors.dose = config.amountError;
  if (Object.keys(app.formErrors).length) {
    render();
    toast("Check required fields");
    return;
  }
  const id = `care-${Date.now()}`;
  const detailParts = [app.form.dose, app.form.note || "care note"].filter(Boolean);
  app.reminders.push({
    id,
    petId: app.form.petId,
    type: app.selectedCareType,
    title: app.form.name,
    detail: detailParts.join(", "),
    time: app.form.time.replace(" AM", "").replace(" PM", ""),
    status: "upcoming",
    completedBy: "",
  });
  app.tab = "today";
  app.route = "tab";
  app.formErrors = {};
  toast("Reminder saved");
}

document.addEventListener("input", (event) => {
  const input = event.target.closest("[data-form]");
  if (input) {
    app.form[input.dataset.form] = input.value;
    delete app.formErrors[input.dataset.form];
  }
});

document.addEventListener("change", (event) => {
  const input = event.target.closest("[data-form]");
  if (input) {
    app.form[input.dataset.form] = input.value;
    delete app.formErrors[input.dataset.form];
  }
});

document.addEventListener("click", (event) => {
  const tabButton = event.target.closest("[data-native-tab]");
  if (tabButton) {
    setTab(tabButton.dataset.nativeTab);
    return;
  }

  const routeButton = event.target.closest("[data-route]");
  if (routeButton) {
    const route = routeButton.dataset.route;
    if (["today", "pets", "add", "records", "settings"].includes(route)) {
      setTab(route);
    } else {
      setRoute(route, { id: routeButton.dataset.id });
    }
    return;
  }

  const actionButton = event.target.closest("[data-action]");
  if (!actionButton) return;

  const action = actionButton.dataset.action;
  const id = actionButton.dataset.id;

  if (action === "back") {
    app.route = "tab";
    render();
  } else if (action === "nextOnboarding") {
    app.onboardingStep = Math.min(app.onboardingStep + 1, onboardingSteps.length - 1);
    render();
  } else if (action === "prevOnboarding") {
    app.onboardingStep = Math.max(app.onboardingStep - 1, 0);
    render();
  } else if (action === "skipOnboarding") {
    completeOnboarding("today");
  } else if (action === "finishOnboarding") {
    completeOnboarding("add");
  } else if (action === "done") {
    markReminder(id, "done");
  } else if (action === "undo") {
    markReminder(id, "due");
    toast("Care moved back to due");
  } else if (action === "snooze") {
    app.sheet = { kind: "snooze", id };
    render();
  } else if (action === "snoozeFor") {
    const item = reminder(app.sheet?.id);
    if (item) item.status = "upcoming";
    app.sheet = null;
    toast(`Snoozed ${actionButton.dataset.minutes} min`);
  } else if (action === "skip") {
    app.sheet = { kind: "skip", id };
    render();
  } else if (action === "skipReason") {
    const item = reminder(app.sheet?.id);
    if (item) item.status = "skipped";
    app.sheet = null;
    toast("Skip note saved");
  } else if (action === "careType") {
    app.selectedCareType = id;
    render();
  } else if (action === "saveCare") {
    saveCare();
  } else if (action === "addPet") {
    app.sheet = { kind: "addPet" };
    render();
  } else if (action === "confirmAddPet") {
    if (!app.pets.some((item) => item.id === "kiwi")) {
      app.pets.push({ id: "kiwi", name: "Kiwi", species: "Bird", age: "2 years", weight: "38 g", initial: "K" });
    }
    app.sheet = null;
    app.tab = "pets";
    app.route = "tab";
    toast("Kiwi added");
  } else if (action === "toggleNotifications") {
    app.notificationStatus = app.notificationStatus === "On" ? "Off" : "On";
    toast(`Notifications ${app.notificationStatus.toLowerCase()}`);
  } else if (action === "testNotification") {
    toast("Test notification scheduled");
  } else if (action === "purchasePlus") {
    app.subscriptionStatus = "Plus";
    toast("Plus trial started");
  } else if (action === "restorePurchase") {
    toast("Purchases restored");
  } else if (action === "exportPdf") {
    toast("Vet summary PDF prepared");
  } else if (action === "shareFamily") {
    toast("Shared with family");
  } else if (action === "exportData") {
    toast("Data export prepared");
  } else if (action === "replayOnboarding") {
    app.onboardingStep = 0;
    app.route = "onboarding";
    app.sheet = null;
    render();
  } else if (action === "deleteAccount") {
    app.sheet = { kind: "confirmDelete" };
    render();
  } else if (action === "confirmDelete") {
    app.reminders.forEach((item) => {
      item.status = item.id === "heart-med" ? "due" : "upcoming";
      item.completedBy = "";
    });
    app.sheet = null;
    toast("Demo data reset");
  } else if (action === "editSnooze" || action === "editPet" || action === "editReminder") {
    toast("Edit flow placeholder opened");
  } else if (action === "dismissSheet") {
    app.sheet = null;
    render();
  }
});

if (!hasCompletedOnboarding()) {
  app.route = "onboarding";
}

render();

