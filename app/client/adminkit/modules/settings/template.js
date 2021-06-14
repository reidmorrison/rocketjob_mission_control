export default `<div class="settings js-settings">
  <div class="settings-toggle js-settings-toggle">
    <i class="align-middle" data-feather="sliders"></i>
  </div>
  <div class="settings">
    <div class="settings-panel">
      <div class="settings-content">
        <div class="settings-title">
          <button type="button" class="btn-close btn-close-white float-end js-settings-toggle" aria-label="Close"></button>

          <h4 class="mb-0 d-inline-block">Settings</h4>
          <span class="badge bg-primary ms-2 text-uppercase">Pro</span>
        </div>

        <div class="settings-options">

          <div class="alert alert-primary" role="alert">
            <div class="alert-message">
              <strong>Customize</strong> sidebar position, color scheme and layout type.
            </div>
          </div>

          <div class="mb-3">
            <small class="d-block text-uppercase font-weight-bold text-muted mb-2">Color scheme</small>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="theme" value="default" id="themeDefault" checked>
              <label class="form-check-label" for="themeDefault">Default</label>
            </div>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="theme" value="colored" id="themeColored" checked>
              <label class="form-check-label" for="themeColored">Colored</label>
            </div>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="theme" value="dark" id="themeDark">
              <label class="form-check-label" for="themeDark">Dark</label>
            </div>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="theme" value="light" id="themeLight">
              <label class="form-check-label" for="themeLight">Light</label>
            </div>
          </div>

          <hr />
          
          <div class="mb-3">
            <small class="d-block text-uppercase font-weight-bold text-muted mb-2">Layout</small>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="layout" value="fluid" id="layoutFluid" checked>
              <label class="form-check-label" for="layoutFluid">Fluid</label>
            </div>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="layout" value="boxed" id="layoutBoxed">
              <label class="form-check-label" for="layoutBoxed">Boxed</label>
            </div>
          </div>
          
          <hr />

          <div class="mb-3">
            <small class="d-block text-uppercase font-weight-bold text-muted mb-2">Sidebar position</small>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="sidebarPosition" value="left" id="sidebarLeft" checked>
              <label class="form-check-label" for="sidebarLeft">Left</label>
            </div>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="sidebarPosition" value="right" id="sidebarRight">
              <label class="form-check-label" for="sidebarRight">Right</label>
            </div>
          </div>
          
          <hr />

          <div class="mb-3">
            <small class="d-block text-uppercase font-weight-bold text-muted mb-2">Sidebar layout</small>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="sidebarLayout" value="default" id="sidebarDefault" checked>
              <label class="form-check-label" for="sidebarDefault">Default</label>
            </div>
            <div class="form-check form-switch mb-1">
              <input type="radio" class="form-check-input" name="sidebarLayout" value="compact" id="sidebarCompact">
              <label class="form-check-label" for="sidebarCompact">Compact</label>
            </div>
          </div>

          <div class="d-grid gap-2 mb-3">
            <a href="#" class="btn btn-outline-primary btn-lg js-settings-reset">Reset to Default</a>
            <a href="https://adminkit.io/pricing" target="_blank" class="btn btn-primary btn-lg">Purchase Now</a>
          </div>
        </div>

      </div>
    </div>
  </div>
</div>`