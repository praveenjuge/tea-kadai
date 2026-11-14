// Puts the visitor's own system first and runs the screenshot carousel. The
// download links and screenshots work without any of this.

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

const os = detectOS();
const yours = document.querySelector(`.dl[data-os="${os}"]`);
if (yours) yours.classList.add("is-yours");
if (os === "mobile") document.getElementById("mobile-note").hidden = false;

// Screenshot carousel. The strip scrolls and snaps natively; the arrows,
// dots and arrow keys move it one screenshot at a time.
const slides = document.getElementById("slides");
const dotsBox = document.getElementById("dots");
const items = [...slides.children];
const prevButton = document.querySelector(".nav.prev");
const nextButton = document.querySelector(".nav.next");

const dots = items.map((item, index) => {
  const dot = document.createElement("button");
  dot.type = "button";
  dot.setAttribute("aria-label", `Screenshot ${index + 1} of ${items.length}`);
  dot.addEventListener("click", () => goTo(index));
  dotsBox.append(dot);
  return dot;
});

function current() {
  return Math.round(slides.scrollLeft / slides.clientWidth);
}

function goTo(index) {
  const target = Math.max(0, Math.min(items.length - 1, index));
  slides.scrollTo({ left: target * slides.clientWidth });
}

function update() {
  const index = current();
  // The trailer stops when it's scrolled out of view.
  items.forEach((item, i) => {
    const video = item.querySelector("video[controls]");
    if (video && i !== index && !video.paused) video.pause();
  });
  dots.forEach((dot, i) => dot.setAttribute("aria-current", String(i === index)));
  prevButton.disabled = index === 0;
  nextButton.disabled = index === items.length - 1;
}

for (const button of [prevButton, nextButton]) {
  button.addEventListener("click", () => goTo(current() + Number(button.dataset.step)));
}

slides.addEventListener("keydown", (event) => {
  if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
    event.preventDefault();
    goTo(current() + (event.key === "ArrowRight" ? 1 : -1));
  }
});

// The gameplay clip plays on a loop unless the visitor prefers less motion.
const clip = slides.querySelector("video[autoplay]");
if (clip && window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  clip.removeAttribute("autoplay");
  clip.pause();
  clip.controls = true;
}

slides.addEventListener("scroll", () => requestAnimationFrame(update), { passive: true });
window.addEventListener("resize", update);
update();
