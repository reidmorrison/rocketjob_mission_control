const elements = document.querySelectorAll(".js-fullscreen");

elements.forEach(element => {
  element.addEventListener("click", () => {
    const isFullscreen = !!document.fullscreenElement;

    isFullscreen ? document.exitFullscreen() : document.body.requestFullscreen();
  }); 
});