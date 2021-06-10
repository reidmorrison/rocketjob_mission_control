import DomURL from "domurl";
import settingsTemplate from "./template";

const url = new DomURL();

const settingsPrefix = "adminkit_config_";
const settingsClassName = ".js-settings";
const settingsToggleClassName = ".js-settings-toggle";
const settingsResetClassName = ".js-settings-reset";
const stylesheetClassName = ".js-stylesheet";

const defaultProps = {
  theme: "default",
  layout: "fluid",
  sidebarPosition: "left",
  sidebarLayout: "default"
}

const props = {
  theme: ["default", "dark", "light", "colored"],
  layout: ["fluid", "boxed"],
  sidebarPosition: ["left", "right"],
  sidebarLayout: ["default", "compact"]
};

// Used to force reload on dark/light mode switch
let activeTheme = undefined;

const createElement = html => {
  const template = document.createElement("template");
  template.innerHTML = html;
  return template.content.firstChild;
}

const initialize = () => {
  // If query parameters are passed (e.g. ?theme=dark)
  if(Object.keys(url.query).length > 0) {
    // Reset current stored config
    resetStoredConfig();

    Object.entries(url.query).forEach(([key, value]) => {
      if (props[key] && props[key].includes(value)) {
        setDomElements(key, value);
        setStoredConfig(key, value);
      }
    });
  }
  else {
    setDomElementsByConfigs();
  }
}

const initializeElements = () => {
  document.body.appendChild(createElement(settingsTemplate));

  bindSidebarEvents();
  
  bindConfigEvents();
  
  bindResetEvents();

  setSelectedRadios();

  openSidebarOnFirstVisit();
}

const bindSidebarEvents = () => {
  const settingsElement = document.querySelector(settingsClassName);
  const settingsToggleElements = document.querySelectorAll(settingsToggleClassName);

  settingsToggleElements.forEach(element => {
    element.onclick = e => {
      e.preventDefault();
      settingsElement.classList.toggle("open");
    };
  })

  document.body.onclick = e => {
    if (!settingsElement.contains(e.target)){
      settingsElement.classList.remove("open");
    }
  }
}

const bindConfigEvents = () => {
  const settingsElement = document.querySelector(settingsClassName);
  const radioElements = settingsElement.querySelectorAll("input[type=radio]");

  radioElements.forEach(element => {
    element.addEventListener("change", e => {
      // Set data attribute on body element
      setDomElements(e.target.name, e.target.value);
      // Save to local storage
      setStoredConfig(e.target.name, e.target.value);
    });
  })
}

const bindResetEvents = () => {
  const settingsResetElement = document.querySelector(settingsResetClassName);

  settingsResetElement.addEventListener("click", () => {
    resetStoredConfig();
    setSelectedRadios();
    setDomElementsByConfigs();
  })
}

const setSelectedRadios = () => {
  for (let [key, value] of Object.entries(getConfigs())) {
    const _value = value ? value : defaultProps[key];

    const element = document.querySelector(`input[name="${key}"][value="${_value}"]`);
    element.checked = true;
  }
}

const openSidebarOnFirstVisit = () => {
  setTimeout(() => {
    if(!getStoredConfig("visited")){
      const settingsElement = document.querySelector(settingsClassName);
      settingsElement.classList.toggle("open");
      setStoredConfig("visited", true)
    }
  }, 1000);
}

const setDomElementsByConfigs = () => {
  for (let [key, value] of Object.entries(getConfigs())) {
    const _value = value ? value : defaultProps[key];
    setDomElements(key, _value);
  }
}

const setDomElements = (name, value) => {
  // Toggle stylesheet (light/dark)
  if(name === "theme"){
    const theme = value === "dark" ? "dark" : "light";
    const stylesheet = document.querySelector(stylesheetClassName);
    stylesheet.setAttribute("href", `css/${theme}.css`);

    if(activeTheme && activeTheme !== theme){
      window.location.replace(window.location.pathname);
    }

    activeTheme = theme;
  }

  // Set data attributes on body element
  document.body.dataset[name] = value;
}

const getConfigs = () => ({
  theme: getStoredConfig("theme"),
  layout: getStoredConfig("layout"),
  sidebarPosition: getStoredConfig("sidebarPosition"),
  sidebarLayout: getStoredConfig("sidebarLayout"),
})

const resetStoredConfig = () => {
  removeStoredConfig("theme");
  removeStoredConfig("layout");
  removeStoredConfig("sidebarPosition");
  removeStoredConfig("sidebarLayout");
}

const getStoredConfig = (name) => {
  return localStorage.getItem(`${settingsPrefix}${name}`);
}

const setStoredConfig = (name, value) => {
  localStorage.setItem(`${settingsPrefix}${name}`, value);
}

const removeStoredConfig = (name) => {
  localStorage.removeItem(`${settingsPrefix}${name}`);
}

// Wait until page is loaded
document.addEventListener("DOMContentLoaded", () => initializeElements());

// Apply settings (from localstorage) once body-element is available
const documentObserver = new MutationObserver(() => {
  if (document.body) {
    initialize();

    documentObserver.disconnect();
  }
});
documentObserver.observe(document.documentElement, { childList: true });