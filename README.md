stylish.js
==========

CSS on-page editor.  Created for the purpose of allowing live style changes to dynamic CMS stylesheet.

## Features
* DOM element smart selector
* [Bootstrap](http://twitter.github.io/bootstrap/index.html) compatible
* Small footprint

## Screenshot
![stylish](https://raw.github.com/ivanmorales/stylish.js/master/assets/sample1.png)

## Dependencies
* jQuery 1.9.1 (or higher)
Styles are based off of Bootstrap, but it is not required.

## Usage
```
(function($, window) {
  // To enable on an element
  // * The 'post' parameter is required ... will throw an exception
  //   if it is not specified
  $(body).stylish({
    'post': 'scripts/post.php',
  });
  
  // If stylish has aready been initialized on an element simply turn it on ... 
  $(body).stylish('on');
  
  // To turn off and disable stylish editing
  $(body).stylish('off');
  
  // To remove all references
  $(body).stylish('destroy');

})(jQuery, window);
```
