const $ = (selector) => document.querySelector(selector);

const issueForm = $("#idea-form");
const titleInput = $("#idea-title");
const ideaInput = $("#idea-description");
const audienceInput = $("#idea-audience");
const confirmOverlay = $("#confirm-overlay");
const previewPanel = $("#idea-preview");
const confirmButton = $("#confirm-submit");
const toast = $("#toast");
let confirmationId = null;
let toastTimer = null;

function escapeText(value) {
  return String(value ?? "");
}

function showToast(message, isError = false) {
  toast.textContent = message;
  toast.classList.toggle("toast-error", isError);
  toast.classList.add("toast-visible");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("toast-visible"), 4200);
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status}).`);
  return data;
}

function setListMessage(element, message, isError = false) {
  element.replaceChildren();
  const row = document.createElement("div");
  row.className = isError ? "empty-state error-text" : "empty-state";
  row.textContent = message;
  element.append(row);
}

function externalLink(url, title, secondary = "") {
  const link = document.createElement("a");
  link.className = "list-item";
  link.href = url || "#";
  link.target = "_blank";
  link.rel = "noreferrer";
  const copy = document.createElement("span");
  copy.className = "list-copy";
  const main = document.createElement("strong");
  main.textContent = title || "Untitled";
  copy.append(main);
  if (secondary) {
    const sub = document.createElement("small");
    sub.textContent = secondary;
    copy.append(sub);
  }
  const arrow = document.createElement("span");
  arrow.className = "item-arrow";
  arrow.textContent = "↗";
  link.append(copy, arrow);
  return link;
}

function renderReviews(pullRequests) {
  const list = $("#review-list");
  list.replaceChildren();
  if (pullRequests?.error) {
    setListMessage(list, pullRequests.error, true);
    $("#review-count").textContent = "!";
    $("#stat-review").textContent = "!";
    return;
  }
  const pending = pullRequests || [];
  $("#review-count").textContent = String(pending.length);
  $("#stat-review").textContent = String(pending.length);
  if (!pending.length) {
    setListMessage(list, "Nothing is waiting for a review.");
    return;
  }
  pending.slice(0, 6).forEach((pr) => {
    const repo = pr.repository?.nameWithOwner || "Organization repo";
    list.append(externalLink(pr.url, `#${pr.number} · ${pr.title}`, `${repo} · ${pr.author?.login || "Contributor"}`));
  });
  if (pending.length > 6) {
    const more = document.createElement("p");
    more.className = "more-label";
    more.textContent = `${pending.length - 6} more pull request(s)`;
    list.append(more);
  }
}

function renderIssues(issues) {
  const list = $("#issue-list");
  list.replaceChildren();
  if (issues?.error) {
    setListMessage(list, issues.error, true);
    $("#stat-issues").textContent = "!";
    return;
  }
  $("#stat-issues").textContent = String(issues?.length || 0);
  if (!issues?.length) {
    setListMessage(list, "No open issues yet. Your submitted ideas will appear here.");
    return;
  }
  issues.slice(0, 6).forEach((issue) => {
    const labels = (issue.labels || []).map((label) => label.name).filter(Boolean).slice(0, 2).join(" · ");
    const repo = issue.repository?.nameWithOwner || "Organization repo";
    list.append(externalLink(issue.url, `#${issue.number} · ${issue.title}`, labels || `${repo} · ${issue.author?.login || "a contributor"}`));
  });
}

function renderProject(project) {
  const panel = $("#project-content");
  panel.replaceChildren();
  if (!project) {
    setListMessage(panel, "The Company Pipeline project was not found. Create it in the Nithub-IT-Solutions organization, then refresh.");
    const link = document.createElement("a");
    link.className = "button button-outline full-button";
    link.href = "https://github.com/orgs/Nithub-IT-Solutions/projects";
    link.target = "_blank";
    link.rel = "noreferrer";
    link.textContent = "Open organization projects ↗";
    panel.append(link);
    return;
  }
  if (project.error) {
    setListMessage(panel, project.error, true);
    return;
  }
  const heading = document.createElement("a");
  heading.className = "project-link";
  heading.href = project.url;
  heading.target = "_blank";
  heading.rel = "noreferrer";
  heading.textContent = `Open Company Pipeline · #${project.number} ↗`;
  panel.append(heading);

  const items = project.items?.nodes || [];
  if (!items.length) {
    const empty = document.createElement("div");
    empty.className = "empty-state";
    empty.textContent = "The board has no items yet.";
    panel.append(empty);
    return;
  }
  const list = document.createElement("div");
  list.className = "list-stack project-items";
  items.slice(0, 8).forEach((item) => {
    const content = item.content || {};
    const values = item.fieldValues?.nodes || [];
    const status = values.find((value) => value.field?.name === "Status")?.name || "Unscheduled";
    list.append(externalLink(content.url || project.url, content.title || "Draft item", status));
  });
  panel.append(list);
  if (items.length > 8) {
    const more = document.createElement("p");
    more.className = "more-label";
    more.textContent = "Showing the latest 8 board items.";
    panel.append(more);
  }
}

function renderWorkflows(runs) {
  const list = $("#workflow-list");
  list.replaceChildren();
  if (runs?.error) {
    setListMessage(list, runs.error, true);
    $("#stat-workflow").textContent = "Error";
    return;
  }
  if (!runs?.length) {
    $("#stat-workflow").textContent = "—";
    $("#workflow-foot").textContent = "No recent runs";
    setListMessage(list, "No workflow runs yet. New runs appear when a matching GitHub event occurs.");
    return;
  }
  const latest = runs[0];
  const outcome = latest.status === "completed" ? (latest.conclusion || "completed") : latest.status;
  $("#stat-workflow").textContent = outcome.replaceAll("_", " ");
  $("#workflow-foot").textContent = latest.name || "Latest Actions run";
  runs.slice(0, 5).forEach((run) => {
    const status = run.status === "completed" ? (run.conclusion || "completed") : run.status;
    list.append(externalLink(run.url, run.displayTitle || run.name, `${status} · ${run.repository} · ${run.headBranch || run.event || "GitHub Actions"}`));
  });
}

async function refreshDashboard() {
  $("#refresh-button").disabled = true;
  $("#connection-status").textContent = "Refreshing GitHub data…";
  try {
    const data = await api("/api/dashboard");
    $("#repo-name").textContent = `· ${data.repository}`;
    $("#connection-status").textContent = `Connected as ${data.ceo}`;
    $("#updated-at").textContent = `Updated ${new Date(data.refreshed_at * 1000).toLocaleTimeString()}`;
    $("#stat-prs").textContent = data.pull_requests?.error ? "!" : String(data.pull_requests?.length || 0);
    renderReviews(data.review_queue);
    renderIssues(data.issues);
    renderProject(data.project);
    renderWorkflows(data.workflow_runs);
  } catch (error) {
    $("#connection-status").textContent = "GitHub connection needs attention";
    $("#updated-at").textContent = error.message;
    $("#repo-name").textContent = "· Nithub-IT-Solutions/Company-hq";
    ["#review-list", "#issue-list", "#project-content", "#workflow-list"].forEach((selector) =>
      setListMessage($(selector), error.message, true)
    );
    showToast(error.message, true);
  } finally {
    $("#refresh-button").disabled = false;
  }
}

function closeConfirmation() {
  confirmOverlay.hidden = true;
  confirmationId = null;
  confirmButton.disabled = false;
  confirmButton.textContent = "Confirm and create issue";
}

issueForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = $("#preview-button");
  button.disabled = true;
  try {
    const preview = await api("/api/ideas/preview", {
      method: "POST",
      body: JSON.stringify({
        title: titleInput.value,
        idea: ideaInput.value,
        audience: audienceInput.value,
      }),
    });
    confirmationId = preview.confirmation;
    previewPanel.replaceChildren();
    const title = document.createElement("h3");
    title.textContent = preview.title;
    const body = document.createElement("pre");
    body.textContent = preview.body;
    previewPanel.append(title, body);
    confirmOverlay.hidden = false;
    $("#confirm-submit").focus();
  } catch (error) {
    showToast(error.message, true);
  } finally {
    button.disabled = false;
  }
});

async function confirmIdea() {
  if (!confirmationId) return;
  confirmButton.disabled = true;
  confirmButton.textContent = "Creating issue…";
  try {
    const result = await api("/api/ideas/confirm", {
      method: "POST",
      body: JSON.stringify({ confirmation: confirmationId }),
    });
    closeConfirmation();
    issueForm.reset();
    $("#idea-count").textContent = "0 / 5,000";
    const notice = $("#idea-result");
    notice.replaceChildren();
    notice.hidden = false;
    notice.className = "notice notice-success";
    const message = document.createElement("span");
    message.textContent = result.warning || "Idea captured. No agent workflow was started.";
    if (result.warning) notice.classList.add("notice-warning");
    const link = document.createElement("a");
    link.href = result.url;
    link.target = "_blank";
    link.rel = "noreferrer";
    link.textContent = "Open the GitHub issue ↗";
    notice.append(message, link);
    showToast("Idea issue created. You remain in control of the next step.");
    await refreshDashboard();
  } catch (error) {
    closeConfirmation();
    showToast(error.message, true);
  }
}

confirmButton.addEventListener("click", confirmIdea);
$("#cancel-confirm").addEventListener("click", closeConfirmation);
$("#close-confirm").addEventListener("click", closeConfirmation);
confirmOverlay.addEventListener("click", (event) => {
  if (event.target === confirmOverlay) closeConfirmation();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && !confirmOverlay.hidden) closeConfirmation();
});
ideaInput.addEventListener("input", () => {
  $("#idea-count").textContent = `${ideaInput.value.length.toLocaleString()} / 5,000`;
});

function appendChatMessage(role, text) {
  const message = document.createElement("article");
  message.className = `chat-message ${role}`;
  const label = document.createElement("span");
  label.className = "chat-label";
  label.textContent = role === "assistant" ? "CLAUDE · READ ONLY" : "YOU";
  const content = document.createElement("p");
  content.textContent = text;
  message.append(label, content);
  $("#chat-messages").append(message);
  message.scrollIntoView({ block: "nearest", behavior: "smooth" });
  return message;
}

$("#chat-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const input = $("#chat-input");
  const message = input.value.trim();
  if (!message) return;
  input.value = "";
  const empty = $(".chat-empty");
  if (empty) empty.remove();
  appendChatMessage("user", message);
  const waiting = appendChatMessage("assistant", "Reading the safe repository snapshot…");
  $("#chat-button").disabled = true;
  try {
    const result = await api("/api/chat", {
      method: "POST",
      body: JSON.stringify({ message }),
    });
    waiting.querySelector("p").textContent = result.answer || "Claude returned an empty response.";
  } catch (error) {
    waiting.querySelector("p").textContent = error.message;
    waiting.classList.add("chat-error");
  } finally {
    $("#chat-button").disabled = false;
    input.focus();
  }
});

$("#refresh-button").addEventListener("click", refreshDashboard);
refreshDashboard();
