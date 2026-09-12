document.documentElement.classList.add("js");

const header = document.querySelector("[data-header]");
const menuButton = document.querySelector(".menu-toggle");
const navigation = document.querySelector(".site-nav");
const navigationLinks = [...document.querySelectorAll('.site-nav a[href^="#"]')];
const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

function closeMenu() {
    if (!menuButton || !navigation) return;
    menuButton.setAttribute("aria-expanded", "false");
    navigation.classList.remove("is-open");
}

if (menuButton && navigation) {
    menuButton.addEventListener("click", () => {
        const willOpen = menuButton.getAttribute("aria-expanded") !== "true";
        menuButton.setAttribute("aria-expanded", String(willOpen));
        navigation.classList.toggle("is-open", willOpen);
    });

    navigationLinks.forEach((link) => link.addEventListener("click", closeMenu));

    document.addEventListener("click", (event) => {
        if (!header?.contains(event.target)) closeMenu();
    });

    document.addEventListener("keydown", (event) => {
        if (event.key === "Escape") {
            closeMenu();
            menuButton.focus();
        }
    });

    const desktopQuery = window.matchMedia("(min-width: 781px)");
    desktopQuery.addEventListener("change", (event) => {
        if (event.matches) closeMenu();
    });
}

function updateHeader() {
    header?.classList.toggle("is-scrolled", window.scrollY > 28);
}

updateHeader();
window.addEventListener("scroll", updateHeader, { passive: true });

const revealElements = document.querySelectorAll(".reveal");

if (reducedMotion.matches || !("IntersectionObserver" in window)) {
    revealElements.forEach((element) => element.classList.add("is-visible"));
} else {
    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
        });
    }, { threshold: 0.12, rootMargin: "0px 0px -40px" });

    revealElements.forEach((element) => revealObserver.observe(element));
}

const observedSections = navigationLinks
    .map((link) => document.querySelector(link.getAttribute("href")))
    .filter(Boolean);

if ("IntersectionObserver" in window) {
    const sectionObserver = new IntersectionObserver((entries) => {
        const visible = entries
            .filter((entry) => entry.isIntersecting)
            .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

        if (!visible) return;
        navigationLinks.forEach((link) => {
            const isCurrent = link.getAttribute("href") === `#${visible.target.id}`;
            link.classList.toggle("is-active", isCurrent);
            if (isCurrent) link.setAttribute("aria-current", "location");
            else link.removeAttribute("aria-current");
        });
    }, { rootMargin: "-30% 0px -55%", threshold: [0, 0.2, 0.5] });

    observedSections.forEach((section) => sectionObserver.observe(section));
}

const year = document.querySelector("[data-year]");
if (year) year.textContent = new Date().getFullYear();
