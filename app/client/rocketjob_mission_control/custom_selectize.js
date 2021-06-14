import "selectize";

$(document).on("turblinks:load", function () {
  return $("select.selectize").selectize({
    create:       true,
    hideSelected: true
  });
});
