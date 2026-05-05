const screens = {
  onboarding: {
    title: "Onboarding",
    description:
      "The first run avoids account friction and creates one real care reminder before asking for notification permission.",
    bullets: [
      "Pet setup stays to name, species, and optional photo",
      "First care can be created with only name, time, and repeat",
      "Soft upgrade appears after value is visible",
    ],
    render: renderOnboarding,
  },
  today: {
    title: "Today",
    description:
      "The launch screen focuses on the next care task and keeps Done, Snooze, and Skip within thumb reach.",
    bullets: [
      "Care Ring progress around pet photos",
      "One-tap completion with Undo-ready state",
      "Overdue care uses amber, not panic red",
    ],
    render: renderToday,
  },
  "add-care": {
    title: "Add Care",
    description:
      "A short iOS form handles the common medication reminder path while keeping advanced details optional.",
    bullets: [
      "Segmented care type selection",
      "Native-feeling time and repeat rows",
      "Paid upgrade trigger after the free reminder limit",
    ],
    render: renderAddCare,
  },
  profile: {
    title: "Pet Profile",
    description:
      "Each pet has a calm health overview with active medication, upcoming care, and recent trends.",
    bullets: [
      "Care Ring becomes the page identity",
      "Small animals are supported through flexible units",
      "Weight trend and next visit are immediately visible",
    ],
    render: renderProfile,
  },
  calendar: {
    title: "Calendar",
    description:
      "The calendar gives a month-level view without letting daily medication dots overwhelm visits and vaccines.",
    bullets: [
      "Visits and vaccines remain visually prominent",
      "Daily medication is indicated with subtle dots",
      "Agenda list provides the useful detail",
    ],
    render: renderCalendar,
  },
  records: {
    title: "Records",
    description:
      "Records are designed around the moment before a vet visit, where PDF export becomes a strong paid feature.",
    bullets: [
      "Timeline filters for medication, weight, vaccine, and visit",
      "Vet Summary card creates the paid upgrade moment",
      "Charts and notes stay readable inside the phone",
    ],
    render: renderRecords,
  },
  "vet-summary": {
    title: "Vet Summary",
    description:
      "The export preview turns scattered care logs into something a veterinarian can scan quickly.",
    bullets: [
      "Shows date range, active medication, weight trend, and skipped care",
      "Export stays gated but the preview explains the value",
      "PDF layout avoids diagnosis or treatment claims",
    ],
    render: renderVetSummary,
  },
  family: {
    title: "Family",
    description:
      "Family sharing is about reducing uncertainty: who completed each dose, when, and what remains open.",
    bullets: [
      "Caregivers are visible without complex scheduling",
      "Completion history is the core value",
      "Invite caregiver is the Family plan trigger",
    ],
    render: renderFamily,
  },
  "notification-primer": {
    title: "Notifications",
    description:
      "The permission screen appears after a real reminder exists, so the system prompt has context.",
    bullets: [
      "Explains exactly what notifications are used for",
      "Includes a pet-specific example instead of generic copy",
      "Does not overpromise emergency or critical alerts",
    ],
    render: renderNotificationPrimer,
  },
  "notification-off": {
    title: "Notification Recovery",
    description:
      "A paid reminder app needs a calm recovery path when iOS notifications are disabled.",
    bullets: [
      "States the problem without blaming the user",
      "Gives a direct settings action and a test path",
      "Keeps Today usable even while reminders are off",
    ],
    render: renderNotificationOff,
  },
  settings: {
    title: "Settings",
    description:
      "Settings keeps trust features easy to find: test notification, restore purchase, export, privacy, and deletion.",
    bullets: [
      "Subscription controls are explicit",
      "Notification test helps users trust reminders",
      "Privacy and medical disclaimer are visible",
    ],
    render: renderSettings,
  },
  paywall: {
    title: "Paywall",
    description:
      "The Plus paywall sells outcomes first, then shows price and subscription controls clearly.",
    bullets: [
      "Annual plan is recommended but monthly is visible",
      "Restore, Terms, and Privacy are not hidden",
      "Feature list maps directly to serious care use cases",
    ],
    render: renderPaywall,
  },
  "paywall-states": {
    title: "Purchase States",
    description:
      "Subscription screens need recovery states for trial, restore, purchase failure, and expired access.",
    bullets: [
      "Reduces support burden around App Store purchases",
      "Makes Restore Purchase feel trustworthy",
      "Keeps failed payments calm and recoverable",
    ],
    render: renderPaywallStates,
  },
};

function petChip(name, initial, ringClass = "") {
  return `
    <div class="pet-chip">
      <div class="care-ring ${ringClass}">
        <div class="pet-avatar">${initial}</div>
      </div>
      <span>${name}</span>
    </div>
  `;
}

function bottomNav(active) {
  const items = ["Today", "Pets", "Cal", "Records", "More"];
  return `
    <div class="bottom-nav">
      ${items.map((item) => `<span class="${item === active ? "active" : ""}">${item}</span>`).join("")}
    </div>
  `;
}

function careRow(dot, title, sub, time) {
  return `
    <div class="list-row">
      <span class="dot ${dot}"></span>
      <div>
        <div class="row-title">${title}</div>
        <div class="row-sub">${sub}</div>
      </div>
      <span class="pill">${time}</span>
    </div>
  `;
}

function renderToday() {
  return `
    <div class="screen-topline">
      <div>
        <div class="screen-title">Today</div>
        <div class="screen-sub">Tue, May 5 - 4 of 6 done</div>
      </div>
      <span class="pill primary">67%</span>
    </div>
    <div class="pet-row">
      ${petChip("Momo", "M")}
      ${petChip("Luna", "L", "blue")}
      ${petChip("Rio", "R", "done")}
    </div>
    <div class="stack">
      <div class="card care-card">
        <div class="card-label">Due now</div>
        <div class="card-title">Momo's heart med</div>
        <div class="card-detail">1 tablet, after breakfast</div>
        <div class="action-row">
          <button class="ios-button primary" data-care-action="done">Done</button>
          <button class="ios-button" data-care-action="snooze">Snooze</button>
          <button class="ios-button" data-care-action="skip">Skip</button>
        </div>
      </div>
      ${careRow("food", "Breakfast notes", "Ate half portion", "9:00")}
      ${careRow("medicine", "Rio eye drops", "2 drops, left eye", "12:30")}
      ${careRow("visit", "Luna vet visit", "Green Vet Clinic", "16:00")}
    </div>
    ${bottomNav("Today")}
  `;
}

function renderOnboarding() {
  return `
    <div class="screen-title">Care routines, remembered.</div>
    <p class="card-detail">Track medications, visits, weight, and notes for every pet.</p>
    <div class="card" style="margin-top:18px;">
      <div class="care-ring" style="margin:0 auto 14px;width:72px;height:72px;">
        <div class="pet-avatar">M</div>
      </div>
      <div class="field"><span>Name</span><strong>Momo</strong></div>
      <div class="field"><span>Species</span><strong>Cat</strong></div>
      <div class="field"><span>Photo</span><strong>Added</strong></div>
      <button class="ios-button primary" style="width:100%;margin-top:16px;">Add my pet</button>
    </div>
    <div class="card" style="margin-top:12px;">
      <div class="card-label">Next</div>
      <div class="card-title">What should we remember first?</div>
      <div class="segmented" style="margin-top:12px;">
        <span class="active">Med</span><span>Visit</span><span>Weight</span><span>Food</span>
      </div>
    </div>
  `;
}

function renderAddCare() {
  return `
    <div class="screen-title">Add Care</div>
    <div class="segmented">
      <span class="active">Medicine</span><span>Food</span><span>Weight</span><span>Visit</span>
    </div>
    <div class="card" style="margin-top:16px;">
      <div class="field"><span>Pet</span><strong>Momo</strong></div>
      <div class="field"><span>Name</span><strong>Heart med</strong></div>
      <div class="field"><span>Dose</span><strong>1 tablet</strong></div>
      <div class="field"><span>Time</span><strong>8:00 AM</strong></div>
      <div class="field"><span>Repeat</span><strong>Daily</strong></div>
      <div class="field"><span>End</span><strong>Until stopped</strong></div>
    </div>
    <div class="card" style="margin-top:12px;">
      <div class="card-label">Reminder</div>
      <div class="card-title">Notify at care time</div>
      <div class="card-detail">Snooze options: 10 min, 30 min, 1 hour</div>
    </div>
    <button class="ios-button primary" style="width:100%;margin-top:16px;">Save reminder</button>
  `;
}

function renderProfile() {
  return `
    <div style="text-align:center;">
      <div class="care-ring" style="margin:0 auto 10px;width:86px;height:86px;">
        <div class="pet-avatar" style="font-size:26px;">M</div>
      </div>
      <div class="screen-title" style="font-size:32px;margin-bottom:4px;">Momo</div>
      <div class="screen-sub">Cat - 12 years - 4.2 kg</div>
    </div>
    <div class="stack" style="margin-top:18px;">
      <div class="card">
        <div class="card-label">Active meds</div>
        <div class="card-title">Heart med</div>
        <div class="card-detail">Daily at 8:00 AM, after breakfast</div>
      </div>
      <div class="card">
        <div class="card-label">Next visit</div>
        <div class="card-title">Green Vet Clinic</div>
        <div class="card-detail">Today, 4:00 PM</div>
      </div>
      <div class="card">
        <div class="card-label">Weight trend</div>
        <div class="chart"></div>
      </div>
    </div>
    ${bottomNav("Pets")}
  `;
}

function renderCalendar() {
  const days = Array.from({ length: 35 }, (_, i) => i + 1);
  return `
    <div class="screen-topline">
      <div>
        <div class="screen-title">Calendar</div>
        <div class="screen-sub">May 2026</div>
      </div>
      <span class="pill primary">Today</span>
    </div>
    <div class="month-grid">
      ${days.map((day) => `<div class="day ${day === 5 ? "active" : ""}">${day}</div>`).join("")}
    </div>
    <div class="stack" style="margin-top:16px;">
      ${careRow("medicine", "Heart med", "Momo, after breakfast", "8:00")}
      ${careRow("visit", "Vet visit", "Luna, Green Vet Clinic", "16:00")}
      ${careRow("food", "Food note", "Rio appetite check", "19:00")}
    </div>
    ${bottomNav("Cal")}
  `;
}

function renderRecords() {
  return `
    <div class="screen-title">Records</div>
    <div class="segmented">
      <span class="active">Med</span><span>Weight</span><span>Vaccine</span><span>Visit</span>
    </div>
    <div class="card" style="margin-top:14px;">
      <div class="card-label">Vet Summary</div>
      <div class="card-title">Prepare clear notes</div>
      <div class="card-detail">Last 30 days, active meds, missed care, weight trend, visit notes.</div>
      <button class="ios-button primary" data-screen-link="vet-summary" style="width:100%;margin-top:13px;">Preview summary</button>
    </div>
    <div class="stack" style="margin-top:12px;">
      ${careRow("medicine", "Heart med done", "By Alex at 8:14", "Today")}
      ${careRow("food", "Ate less than usual", "Added note", "Mon")}
      ${careRow("visit", "Vaccine record", "Certificate attached", "Apr 22")}
    </div>
    ${bottomNav("Records")}
  `;
}

function renderVetSummary() {
  return `
    <div class="screen-topline">
      <div>
        <div class="screen-title">Vet Summary</div>
        <div class="screen-sub">Momo - Last 30 days</div>
      </div>
      <span class="pill primary">PDF</span>
    </div>
    <div class="pdf-preview">
      <div class="pdf-header">
        <div>
          <strong>Momo</strong>
          <span>Cat - 12 years - 4.2 kg</span>
        </div>
        <span class="mini-ring"></span>
      </div>
      <div class="pdf-section">
        <b>Active medication</b>
        <p>Heart med, daily 8:00 AM, after breakfast.</p>
      </div>
      <div class="pdf-section">
        <b>Recent skipped care</b>
        <p>May 3: skipped breakfast note, reason: not eating.</p>
      </div>
      <div class="pdf-section">
        <b>Weight trend</b>
        <div class="chart compact-chart"></div>
      </div>
      <div class="pdf-section">
        <b>Vet notes</b>
        <p>Coughing less this week. Appetite lower in mornings.</p>
      </div>
    </div>
    <button class="ios-button primary" style="width:100%;margin-top:13px;">Export PDF</button>
    <button class="ios-button" style="width:100%;margin-top:8px;">Share preview</button>
  `;
}

function renderFamily() {
  return `
    <div class="screen-title">Family</div>
    <div class="stack">
      <div class="card">
        <div class="card-label">Caregivers</div>
        <div class="pet-row" style="margin-bottom:0;">
          ${petChip("Alex", "A", "done")}
          ${petChip("Mina", "M", "blue")}
          ${petChip("Sam", "S")}
        </div>
      </div>
      <div class="card care-card">
        <div class="card-label">Completion history</div>
        <div class="card-title">Heart med</div>
        <div class="card-detail">Done by Alex at 8:14 AM</div>
      </div>
      <div class="card">
        <div class="card-label">Assignment</div>
        <div class="card-title">Morning meds</div>
        <div class="card-detail">Assigned to Mina on weekdays</div>
      </div>
      <button class="ios-button primary">Invite caregiver</button>
    </div>
  `;
}

function renderNotificationPrimer() {
  return `
    <div class="screen-title">Enable reminders</div>
    <p class="card-detail">Tend Pets can remind you when Momo's care is due.</p>
    <div class="notification-card">
      <div class="notification-icon"></div>
      <div>
        <div class="card-title">Momo's heart med is due</div>
        <div class="card-detail">1 tablet, after breakfast</div>
      </div>
      <div class="notification-actions">
        <span>Done</span><span>Snooze</span>
      </div>
    </div>
    <div class="stack" style="margin-top:16px;">
      ${careRow("medicine", "Medication reminders", "At the time you choose", "")}
      ${careRow("visit", "Visit reminders", "Before appointments", "")}
      ${careRow("food", "No emergency alerts", "This is not veterinary advice", "")}
    </div>
    <button class="ios-button primary" style="width:100%;margin-top:16px;">Enable reminders</button>
    <button class="ios-button" style="width:100%;margin-top:8px;">Not now</button>
  `;
}

function renderNotificationOff() {
  return `
    <div class="screen-title">Reminders are off</div>
    <div class="status-panel warning">
      <div class="card-label">iOS Settings</div>
      <div class="card-title">Notifications are disabled</div>
      <div class="card-detail">Today still works, but Tend Pets cannot remind you when care is due.</div>
    </div>
    <div class="stack" style="margin-top:14px;">
      <div class="field"><span>Medication due</span><strong>Blocked</strong></div>
      <div class="field"><span>Snooze reminders</span><strong>Blocked</strong></div>
      <div class="field"><span>App badge</span><strong>Available</strong></div>
      <div class="field"><span>Today list</span><strong>Available</strong></div>
    </div>
    <button class="ios-button primary" style="width:100%;margin-top:16px;">Open iOS Settings</button>
    <button class="ios-button" style="width:100%;margin-top:8px;">Test notification</button>
  `;
}

function renderSettings() {
  const rows = [
    ["Notifications", "Test reminder"],
    ["Subscription", "Manage Plus"],
    ["Purchases", "Restore purchase"],
    ["Data & Export", "Download records"],
    ["Privacy", "Delete account"],
    ["Help", "Medical disclaimer"],
  ];
  return `
    <div class="screen-title">Settings</div>
    <div class="stack">
      ${rows
        .map(
          ([title, sub]) => `
            <div class="list-row">
              <span class="dot"></span>
              <div>
                <div class="row-title">${title}</div>
                <div class="row-sub">${sub}</div>
              </div>
              <span class="pill">Open</span>
            </div>
          `,
        )
        .join("")}
    </div>
  `;
}

function renderPaywall() {
  return `
    <div class="paywall-hero">
      <div class="card-label">Tend Pets Plus</div>
      <div class="screen-title" style="font-size:29px;">Keep every routine organized</div>
      <div class="card-detail">For pets with daily care, shared routines, and vet-ready records.</div>
    </div>
    <div class="stack" style="margin-top:14px;">
      ${careRow("medicine", "Unlimited reminders", "Medication, food, weight, visits", "")}
      ${careRow("visit", "Vet summary export", "Clear PDF for appointments", "")}
      ${careRow("", "Cloud backup", "Records stay synced", "")}
      <div class="plan-row selected">
        <div><strong>$39.99 yearly</strong><div class="row-sub">Save 33%</div></div>
        <span class="pill primary">Best</span>
      </div>
      <div class="plan-row">
        <div><strong>$4.99 monthly</strong><div class="row-sub">Cancel anytime</div></div>
      </div>
      <button class="ios-button primary">Start 7-day free trial</button>
      <button class="ios-button">Continue with Free</button>
      <div class="row-sub" style="text-align:center;">Restore Purchase - Terms - Privacy</div>
    </div>
  `;
}

function renderPaywallStates() {
  return `
    <div class="screen-title">Subscription</div>
    <div class="stack">
      <div class="status-panel success">
        <div class="card-label">Trial active</div>
        <div class="card-title">6 days left</div>
        <div class="card-detail">Plus renews at $39.99/year on May 11.</div>
      </div>
      <div class="status-panel">
        <div class="card-label">Restore purchase</div>
        <div class="card-title">Checking App Store</div>
        <div class="progress-line"><span></span></div>
      </div>
      <div class="status-panel warning">
        <div class="card-label">Purchase failed</div>
        <div class="card-title">No charge was made</div>
        <div class="card-detail">Please check your App Store payment method and try again.</div>
      </div>
      <div class="status-panel muted">
        <div class="card-label">Expired</div>
        <div class="card-title">Plus access paused</div>
        <div class="card-detail">Your records are safe. Upgrade to export new summaries.</div>
      </div>
      <button class="ios-button primary">Manage subscription</button>
    </div>
  `;
}

function setActiveScreen(name) {
  const config = screens[name] || screens.today;
  const active = document.querySelector("#active-screen");
  active.className = `screen ${name}-screen`;
  active.innerHTML = config.render();

  document.querySelector("#screen-title").textContent = config.title;
  document.querySelector("#screen-description").textContent = config.description;
  document.querySelector("#screen-bullets").innerHTML = config.bullets
    .map((bullet) => `<li>${bullet}</li>`)
    .join("");

  document.querySelectorAll(".tab").forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.target === name);
  });
}

function hydrateStaticScreens() {
  document.querySelectorAll("[class*='-screen']").forEach((node) => {
    const match = Array.from(node.classList).find((name) => name.endsWith("-screen"));
    if (!match || node.id === "active-screen") return;
    const key = match.replace("-screen", "");
    const normalized = key === "add-care" ? "add-care" : key;
    const config = screens[normalized];
    if (config) node.innerHTML = config.render();
  });
}

document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => setActiveScreen(tab.dataset.target));
});

document.querySelectorAll("[data-screen-card]").forEach((card) => {
  card.addEventListener("click", () => {
    setActiveScreen(card.dataset.screenCard);
    document.querySelector("#app").scrollIntoView({ behavior: "smooth", block: "start" });
  });
});

document.addEventListener("click", (event) => {
  const screenLink = event.target.closest("[data-screen-link]");
  if (screenLink) {
    setActiveScreen(screenLink.dataset.screenLink);
    return;
  }

  const button = event.target.closest("[data-care-action]");
  if (!button) return;
  const card = button.closest(".care-card");
  if (!card) return;

  const action = button.dataset.careAction;
  const title = card.querySelector(".card-title")?.textContent || "Care";

  if (action === "done") {
    card.classList.remove("overdue");
    card.innerHTML = `
      <div class="card-label">Done</div>
      <div class="card-title">${title}</div>
      <div class="card-detail">Completed by Alex at 8:14 AM</div>
      <button class="ios-button" data-care-action="undo" style="width:100%;margin-top:12px;">Undo</button>
    `;
  }

  if (action === "snooze") {
    card.classList.add("overdue");
    card.querySelector(".card-label").textContent = "Snoozed";
    card.querySelector(".card-detail").textContent = "We will remind you again in 10 minutes.";
  }

  if (action === "skip") {
    card.innerHTML = `
      <div class="card-label">Skipped with note</div>
      <div class="card-title">${title}</div>
      <div class="card-detail">Reason: not eating. Saved to records.</div>
      <button class="ios-button" data-care-action="undo" style="width:100%;margin-top:12px;">Undo</button>
    `;
  }

  if (action === "undo") {
    setActiveScreen("today");
  }
});

hydrateStaticScreens();
setActiveScreen("today");
