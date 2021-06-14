// DataTables
// import "./modules/datatables";

import dt from "datatables.net";

document.addEventListener("turbolinks:load", () => {
  dt(window, $);
});
