/*
 * Add color theme colors to the window object
 * so this can be used by the charts and vector maps
 */

const lightTheme = {
  "id": "light",
  "name": "Light",
  "primary": "#3B7DDD",
  "secondary": "#6c757d",
  "success": "#1cbb8c",
  "info": "#17a2b8",
  "warning": "#fcb92c",
  "danger": "#dc3545",
  "white": "#fff",
  "gray-100": "#f8f9fa",
  "gray-200": "#e9ecef",
  "gray-300": "#dee2e6",
  "gray-400": "#ced4da",
  "gray-500": "#adb5bd",
  "gray-600": "#6c757d",
  "gray-700": "#495057",
  "gray-800": "#343a40",
  "gray-900": "#212529",
  "black": "#000"
};

const darkTheme = {
  "id": "dark",
  "name": "Dark",
  "primary": "#3B7DDD",
  "secondary": "#7a828a",
  "success": "#1cbb8c",
  "info": "#17a2b8",
  "warning": "#fcb92c",
  "danger": "#dc3545",
  "white": "#222E3C",
  "gray-100": "#384350",
  "gray-200": "#4e5863",
  "gray-300": "#646d77",
  "gray-400": "#7a828a",
  "gray-500": "#91979e",
  "gray-600": "#a7abb1",
  "gray-700": "#bdc0c5",
  "gray-800": "#d3d5d8",
  "gray-900": "#e9eaec",
  "black": "#fff"
}

document.querySelectorAll("link[href]").forEach((link) => {
  const href = link.href.split("/");

  if(href.pop() === "dark.css"){
    // Add theme to the window object
    window.theme = darkTheme;
  }
  else {
    // Add theme to the window object
    window.theme = lightTheme;
  }
});