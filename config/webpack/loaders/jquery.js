// expose-loader helps us to expose the jquery module as $ and jQuery at
// the global object, allowing us to access it at Rails server-rendered
// views.

module.exports = {
  test: require.resolve("jquery"),
  loader: "expose-loader",
  options: {
    exposes: ["$", "jQuery"],
  },
};
