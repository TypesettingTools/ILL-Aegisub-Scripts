(function () {
  function highlightMoonScriptBlocks() {
    if (!window.hljs) return;

    const blocks = document.querySelectorAll("pre code.language-moon");
    blocks.forEach(function (block) {
      block.classList.remove("language-moon");
      block.classList.add("language-lua");
      window.hljs.highlightElement(block);
    });
  }

  document.addEventListener("DOMContentLoaded", highlightMoonScriptBlocks);
})();
