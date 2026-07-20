(function () {
  const REACTIONS = { 1: "\u{1F44D}", 2: "\u2764\uFE0F", 3: "\u{1F604}" };
  const EN = (document.documentElement.lang === "en");
  const t = (vi, en) => (EN ? en : vi);

  function token() {
    const el = document.querySelector('input[name="__RequestVerificationToken"]');
    return el ? el.value : "";
  }
  async function postForm(url, data) {
    const body = new URLSearchParams(data || {});
    const res = await fetch(url, {
      method: "POST",
      headers: { "RequestVerificationToken": token(), "Content-Type": "application/x-www-form-urlencoded" },
      body
    });
    return res.json();
  }
  function esc(s) {
    const d = document.createElement("div");
    d.textContent = s == null ? "" : s;
    return d.innerHTML;
  }
  function timeAgo(iso) {
    const then = new Date(iso + (iso.endsWith("Z") ? "" : "Z"));
    const s = (Date.now() - then.getTime()) / 1000;
    if (s < 60) return t("vừa xong", "just now");
    if (s < 3600) return Math.floor(s / 60) + t(" phút", "m");
    if (s < 86400) return Math.floor(s / 3600) + t(" giờ", "h");
    return Math.floor(s / 86400) + t(" ngày", "d");
  }

  // ---------- Theme ----------
  const savedTheme = localStorage.getItem("theme");
  if (savedTheme) document.documentElement.setAttribute("data-theme", savedTheme);
  document.addEventListener("click", (e) => {
    if (e.target.closest("#themeToggle")) {
      const cur = document.documentElement.getAttribute("data-theme") === "dark" ? "" : "dark";
      if (cur) document.documentElement.setAttribute("data-theme", cur);
      else document.documentElement.removeAttribute("data-theme");
      localStorage.setItem("theme", cur);
    }
    // close dropdowns/menus when clicking outside
    if (!e.target.closest(".usermenu")) {
      const dd = document.getElementById("userDropdown");
      if (dd) dd.classList.remove("open");
    }
    if (!e.target.closest(".post-menu")) {
      document.querySelectorAll(".mini-menu.open").forEach(m => m.classList.remove("open"));
    }
    if (!e.target.closest(".reaction-wrap")) {
      document.querySelectorAll(".reaction-pop.open").forEach(m => m.classList.remove("open"));
    }
  });

  // ---------- Composer media preview ----------
  document.querySelectorAll("[data-composer]").forEach(setupComposer);
  function setupComposer(form) {
    const fileInput = form.querySelector('input[type="file"]');
    const preview = form.querySelector(".composer-preview");
    if (!fileInput || !preview) return;
    fileInput.addEventListener("change", () => {
      const f = fileInput.files[0];
      if (!f) { preview.style.display = "none"; preview.innerHTML = ""; return; }
      const url = URL.createObjectURL(f);
      const isVideo = f.type.startsWith("video");
      preview.innerHTML =
        (isVideo ? `<video src="${url}" controls></video>` : `<img src="${url}">`) +
        `<button type="button" class="remove"><i class="bi bi-x-lg"></i></button>`;
      preview.style.display = "block";
      preview.querySelector(".remove").addEventListener("click", () => {
        fileInput.value = ""; preview.style.display = "none"; preview.innerHTML = "";
      });
    });
  }

  // ---------- Post menu ----------
  document.addEventListener("click", (e) => {
    const tgl = e.target.closest(".menu-toggle");
    if (tgl) {
      const menu = tgl.parentElement.querySelector(".mini-menu");
      const open = menu.classList.contains("open");
      document.querySelectorAll(".mini-menu.open").forEach(m => m.classList.remove("open"));
      if (!open) menu.classList.add("open");
    }
  });

  // ---------- Reactions ----------
  document.addEventListener("click", async (e) => {
    const trigger = e.target.closest(".reaction-trigger");
    if (trigger) {
      const pop = trigger.parentElement.querySelector(".reaction-pop");
      pop.classList.toggle("open");
      return;
    }
    const pick = e.target.closest(".reaction-pop button");
    if (pick) {
      const wrap = pick.closest(".reaction-wrap");
      const id = wrap.getAttribute("data-post");
      const type = parseInt(pick.getAttribute("data-type"), 10);
      wrap.querySelector(".reaction-pop").classList.remove("open");
      const r = await postForm(`/Posts/React?id=${id}`, { type });
      if (r.ok) applyReaction(wrap, r);
      else alert(r.error || "Error");
    }
  });
  function applyReaction(wrap, r) {
    const trigger = wrap.querySelector(".reaction-trigger");
    const label = wrap.querySelector(".reaction-label");
    if (r.current) {
      trigger.classList.add("active");
      label.textContent = REACTIONS[r.current] + " " +
        (r.current == 2 ? t("Yêu thích", "Love") : r.current == 3 ? "Haha" : t("Thích", "Like"));
    } else {
      trigger.classList.remove("active");
      label.innerHTML = `<i class="bi bi-hand-thumbs-up"></i> ` + t("Thích", "Like");
    }
    const card = wrap.closest("[data-post-card]");
    const count = card && card.querySelector(".react-count");
    if (count) count.textContent = r.total;
  }

  // ---------- Comments ----------
  document.addEventListener("click", async (e) => {
    const btn = e.target.closest(".comment-toggle");
    if (!btn) return;
    const card = btn.closest("[data-post-card]");
    const box = card.querySelector(".comments");
    if (box.style.display === "block") { box.style.display = "none"; return; }
    box.style.display = "block";
    if (box.getAttribute("data-loaded") === "1") return;
    const id = card.getAttribute("data-post-card");
    const list = box.querySelector(".comment-list");
    list.innerHTML = `<div class="muted">…</div>`;
    const res = await fetch(`/Posts/Comments?id=${id}`);
    const data = await res.json();
    list.innerHTML = "";
    if (Array.isArray(data)) data.forEach(c => list.appendChild(renderComment(c)));
    box.setAttribute("data-loaded", "1");
  });
  function renderComment(c) {
    const el = document.createElement("div");
    el.className = "comment";
    el.innerHTML =
      `<img src="${esc(c.avatar)}">` +
      `<div><div class="comment-body"><div class="comment-author">${esc(c.authorName)}</div>${esc(c.content)}</div>` +
      `<div class="post-meta" style="margin-left:12px">${timeAgo(c.createdDate)}</div></div>`;
    return el;
  }
  document.addEventListener("submit", async (e) => {
    const form = e.target.closest(".comment-add-form");
    if (!form) return;
    e.preventDefault();
    const input = form.querySelector("input[name=content]");
    const content = input.value.trim();
    if (!content) return;
    const card = form.closest("[data-post-card]");
    const id = card.getAttribute("data-post-card");
    input.value = "";
    const r = await postForm(`/Posts/Comment?id=${id}`, { content });
    if (r.ok) {
      const list = card.querySelector(".comment-list");
      list.appendChild(renderComment(r.comment));
      const cnt = card.querySelector(".comment-count");
      if (cnt) cnt.textContent = (parseInt(cnt.textContent || "0", 10) + 1);
    } else {
      alert(r.error || "Error");
    }
  });

  // ---------- Inline post edit ----------
  document.addEventListener("click", (e) => {
    const et = e.target.closest(".edit-toggle");
    if (et) {
      e.preventDefault();
      const card = et.closest("[data-post-card]");
      const box = card.querySelector(".edit-box");
      if (box) box.style.display = box.style.display === "block" ? "none" : "block";
      const menu = et.closest(".mini-menu");
      if (menu) menu.classList.remove("open");
    }
    const cancel = e.target.closest(".edit-cancel");
    if (cancel) {
      const box = cancel.closest(".edit-box");
      if (box) box.style.display = "none";
    }
  });

  window.MiniSocial = { postForm, token, esc, timeAgo };
})();
