const { environment } = require("@rails/webpacker")
const webpack = require("webpack")

// import our loaders.
const datatables = require("./loaders/datatables");
const jquery = require("./loaders/jquery");

// append them to webpack loaders.
environment.loaders.append("datatables", datatables);
environment.loaders.append("expose", jquery);

// ProviderPlugin helps us to load jQuery when the variables of $ and jQuery
// are encountered as free variables at other modules.
// Let's say if you want to use Bootstrap 4 and Popper.js.
//
// Refer here https://webpack.js.org/plugins/provide-plugin/
environment.plugins.append(
  "Provide",
  new webpack.ProvidePlugin({
    $: "jquery",
    jQuery: "jquery",
  })
);

module.exports = environment
