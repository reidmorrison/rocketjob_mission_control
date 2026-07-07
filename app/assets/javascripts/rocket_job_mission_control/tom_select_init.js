// Enhance every <select class="tom-select"> with tom-select once the page is
// ready. Listens for turbo:load (fired after the initial load and after every
// subsequent Turbo Drive visit) rather than DOMContentLoaded, which only ever
// fires once for the whole session.
// tom-select is a vanilla-JS replacement for Selectize (no jQuery dependency).
document.addEventListener("turbo:load", function () {
  document.querySelectorAll("select.tom-select").forEach(function (element) {
    if (element.tomselect) {
      return;
    }
    new TomSelect(element, {
      create:       true,
      hideSelected: true
    });
  });
});
