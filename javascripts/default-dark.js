(function () {
  function applyDefaultDarkTheme() {
    document.documentElement.setAttribute("data-bs-theme", "dark");
    document.documentElement.setAttribute("data-theme", "dark");
  }

  document.addEventListener("DOMContentLoaded", applyDefaultDarkTheme);
})();
