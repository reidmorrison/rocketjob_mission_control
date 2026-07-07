// Turn every server-rendered `.json-tree` container into an interactive,
// collapsible JSON tree using jquery.json-viewer.
//
// Each container embeds its value as JSON in a child
// `<script type="application/json">` tag and carries a `data-collapsed`
// attribute (set server-side when the top-level value exceeds the collapse
// threshold, see JobsHelper#render_json_tree). A `<noscript>` sibling holds a
// plain-text fallback for when JavaScript is unavailable.
(function($) {
  function renderJsonTrees(root) {
    $(root).find('.json-tree').each(function() {
      var container = $(this);
      if (container.data('jsonRendered')) {
        return;
      }

      var payload = container.children('script[type="application/json"]').first().text();
      if (!payload) {
        return;
      }

      var data;
      try {
        data = JSON.parse(payload);
      } catch (e) {
        return; // Leave the raw payload in place if it will not parse.
      }

      var target = $('<div>').appendTo(container.empty());
      target.jsonViewer(data, {
        collapsed: container.data('collapsed') === true,
        withQuotes: false,
        withLinks: true,
        rootCollapsable: true
      });
      container.data('jsonRendered', true);
    });
  }

  // turbo:load fires after the initial page load and after every subsequent
  // Turbo Drive visit, unlike $(document).ready/DOMContentLoaded which only
  // ever fire once per session.
  document.addEventListener('turbo:load', function() {
    renderJsonTrees(document);
  });

  // Expose so views loaded over AJAX (for example the job show panel) can
  // re-run rendering on freshly inserted markup.
  window.RocketJobMissionControl = window.RocketJobMissionControl || {};
  window.RocketJobMissionControl.renderJsonTrees = renderJsonTrees;
})(jQuery);
