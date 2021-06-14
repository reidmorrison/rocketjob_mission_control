"use strict";

var _createClass = function () {
  function defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true;
      
      if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor);
    }
  } return function (Constructor, protoProps, staticProps) {
    if (protoProps) defineProperties(Constructor.prototype, protoProps);
    if (staticProps) defineProperties(Constructor, staticProps); return Constructor;
  };
}();

function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}

var addFields = function () {
  // This executes when the function is instantiated.
  function addFields() {
    _classCallCheck(this, addFields);

    this.links = document.querySelectorAll('.add_fields');
    this.iterateLinks();
  }

  _createClass(addFields, [{
    key: 'iterateLinks',
    value: function iterateLinks() {
      var _this = this;

      // If there are no links on the page, stop the function from executing.
      if (this.links.length === 0) return; // Loop over each link on the page. A page could have multiple nested forms.

      this.links.forEach(function (link) {
        link.addEventListener('click', function (e) {
          _this.handleClick(link, e);
        });
      });
    }
  }, {
    key: 'handleClick',
    value: function handleClick(link, e) {
      // Stop the function from executing if a link or event were not passed into the function.
      if (!link || !e) return; // Prevent the browser from following the URL.

      e.preventDefault(); // Save a unique timestamp to ensure the key of the associated array is unique.

      var time = new Date().getTime(); // Save the data id attribute into a variable. This corresponds to `new_object.object_id`.
      var linkId = link.dataset.id; // Create a new regular expression needed to find any instance of the `new_object.object_id` used in the fields data attribute if there's a value in `linkId`.
      var regexp = linkId ? new RegExp(linkId, 'g') : null; // Replace all instances of the `new_object.object_id` with `time`, and save markup into a variable if there's a value in `regexp`.
      var newFields = regexp ? link.dataset.fields.replace(regexp, time) : null; // Add the new markup to the form if there are fields to add.

      newFields ? link.insertAdjacentHTML('beforebegin', newFields) : null;
    }
  }]);

  return addFields;
}();

var removeFields = function () {
  // This executes when the function is instantiated.
  function removeFields() {
    _classCallCheck(this, removeFields);

    this.iterateLinks();
  }

  _createClass(removeFields, [{
    key: 'iterateLinks',
    value: function iterateLinks() {
      var _this2 = this;

      // Use event delegation to ensure any fields added after the page loads are captured.
      document.addEventListener('click', function (e) {
        if (e.target && e.target.className == "remove_fields btn btn-danger") {
          _this2.handleClick(e.target, e);
        }
      });
    }
  }, {
    key: 'handleClick',
    value: function handleClick(link, e) {
      // Stop the function from executing if a link or event were not passed into the function.
      if (!link || !e) return; // Prevent the browser from following the URL.

      e.preventDefault(); // Find the parent wrapper for the set of nested fields.

      var fieldParent = link.closest('.nested-fields'); // If there is a parent wrapper, find the hidden delete field.
      var deleteField = fieldParent ? fieldParent.querySelector('input[type="hidden"]') : null; // If there is a delete field, update the value to `1` and hide the corresponding nested fields.

      if (deleteField) {
        deleteField.value = 1;
        fieldParent.style.display = 'none';
      }
    }
  }]);

  return removeFields;
}(); // Wait for turbolinks to load, otherwise `document.querySelectorAll()` won't work


window.addEventListener('DOMContentLoaded', function () {
  return new addFields();
});
window.addEventListener('DOMContentLoaded', function () {
  return new removeFields();
});
