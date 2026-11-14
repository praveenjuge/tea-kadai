// Puts the visitor's own system first, and fills in the latest version and
// file sizes from GitHub. The download links work without any of this.

function detectOS() {
  const ua = navigator.userAgent;
  const platform = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || "";
  if (/android|iphone|ipad|ipod/i.test(ua) || (/mac/i.test(platform) && navigator.maxTouchPoints > 1)) {
    return "mobile";
  }
  if (/win/i.test(platform) || /windows/i.test(ua)) return "windows";
  if (/mac/i.test(platform) || /mac os x/i.test(ua)) return "mac";
  if (/linux|x11/i.test(platform) || /linux|x11/i.test(ua)) return "linux";
  return "unknown";
}

function formatSize(bytes) {
  return `${Math.round(bytes / 1_000_000)} MB`;
}

function formatDate(iso) {
  return new Date(iso).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" });
}

const os = detectOS();
const yours = document.querySelector(`.dl[data-os="${os}"]`);
if (yours) yours.classList.add("is-yours");
if (os === "mobile") document.getElementById("mobile-note").hidden = false;

fetch("https://api.github.com/repos/praveenjuge/tea-kadai/releases/latest", {
  headers: { Accept: "application/vnd.github+json" },
})
  .then((response) => (response.ok ? response.json() : Promise.reject(response.status)))
  .then((release) => {
    for (const asset of release.assets || []) {
      const meta = document.querySelector(`.dl-meta[data-asset="${asset.name}"]`);
      if (meta) meta.textContent += ` · ${formatSize(asset.size)}`;
    }
    const version = release.tag_name.replace(/^v/, "");
    document.getElementById("release").textContent =
      `Free · Version ${version} · Updated ${formatDate(release.published_at)}`;
  })
  .catch(() => {
    // Rate limited or offline: the buttons still point at the latest release.
  });
