const $ = (selector) => document.querySelector(selector);

const statusLabels = {
  pending: "Awaiting CEO decision",
  changes_requested: "Changes requested",
  provisioning: "Creating project",
  provisioning_failed: "Project setup needs attention",
  starting_discovery: "Starting discovery",
  discovery: "Discovery in progress",
  discovery_start_failed: "Discovery needs attention",
};

async function api(path) {
  const response = await fetch(path);
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(body.error || `Request failed (${response.status}).`);
  return body;
}

function linkItem(title, detail, url) {
  const link = document.createElement("a");
  link.className = "list-item";
  link.href = url || "#";
  link.target = "_blank";
  link.rel = "noreferrer";
  const copy = document.createElement("span");
  copy.className = "list-copy";
  const heading = document.createElement("strong");
  heading.textContent = title;
  const sub = document.createElement("small");
  sub.textContent = detail || "";
  copy.append(heading, sub);
  link.append(copy);
  return link;
}

function showList(selector, items, emptyText, titleFor, detailFor, urlFor) {
  const container = $(selector);
  container.replaceChildren();
  if (!Array.isArray(items) || !items.length) {
    const empty = document.createElement("div");
    empty.className = "empty-state";
    empty.textContent = emptyText;
    container.append(empty);
    return;
  }
  items.forEach((item) => container.append(linkItem(titleFor(item), detailFor(item), urlFor(item))));
}

async function loadProject() {
  const slug = decodeURIComponent(location.pathname.split("/").pop() || "");
  $("#project-refresh").disabled = true;
  $("#project-error").hidden = true;
  try {
    const data = await api(`/api/projects/${encodeURIComponent(slug)}`);
    document.title = `${data.idea.title} · Company HQ`;
    $("#project-title").textContent = data.idea.title;
    $("#project-summary").textContent =
      `${data.repo.description || "Product project"} · ${data.repo.visibility || "private"} repository`;
    $("#project-status").textContent = statusLabels[data.idea.status] || data.idea.status.replaceAll("_", " ");
    $("#repo-link").href = data.repo.url;
    $("#repo-link").textContent = `Open ${data.repo.name} on GitHub ↗`;
    $("#tracking-link").href = data.tracking_url;

    const runs = Array.isArray(data.runs) ? data.runs : [];
    showList(
      "#progress-list", runs, data.runs?.error || "No workflow runs yet.",
      (run) => run.displayTitle || run.name || "Workflow run",
      (run) =>
        `${run.status === "completed" ? run.conclusion || "completed" : run.status} · ` +
        `${new Date(run.createdAt).toLocaleString()}`,
      (run) => run.url,
    );
    const prs = Array.isArray(data.pull_requests) ? data.pull_requests : [];
    showList(
      "#pull-request-list", prs, data.pull_requests?.error || "No pull requests yet.",
      (pr) => `#${pr.number} · ${pr.title}`,
      (pr) =>
        `${pr.reviewDecision || pr.state}${pr.isDraft ? " · draft" : ""} · updated ` +
        `${new Date(pr.updatedAt).toLocaleDateString()}`,
      (pr) => pr.url,
    );
    $("#doc-idea").textContent = data.documents["Idea-Report.md"] || "Not available.";
    $("#doc-next").textContent = data.documents["Next-Process.md"] || "Not available.";
    $("#doc-suggestions").textContent = data.documents["Suggestions.md"] || "Not available.";
    if (data.expectations) {
      $("#expectations-panel").hidden = false;
      $("#expectations-copy").textContent = data.expectations;
    }
  } catch (error) {
    $("#project-title").textContent = "Project unavailable";
    $("#project-summary").textContent = "Could not load this project's GitHub data.";
    $("#project-error").textContent = error.message;
    $("#project-error").hidden = false;
  } finally {
    $("#project-refresh").disabled = false;
  }
}

$("#project-refresh").addEventListener("click", loadProject);
loadProject();
