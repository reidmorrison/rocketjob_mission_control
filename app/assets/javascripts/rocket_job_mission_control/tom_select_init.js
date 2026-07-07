// Enhance every <select class="tom-select"> with tom-select once the DOM is ready.
// tom-select is a vanilla-JS replacement for Selectize (no jQuery dependency).
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll("select.tom-select").forEach(function (element) {
    new TomSelect(element, {
      create:       true,
      hideSelected: true
    });
  });
});
