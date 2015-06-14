function hasClass(id, cls) {
  var e = document.getElementById(id);
  return (' ' + e.className + ' ').indexOf(' ' + cls + ' ') > -1;
}

function addClass(id, cls) {
  var e = document.getElementById(id);
  cls = " " + cls;
  e.className = e.className.replace(cls,"");
  e.className = e.className + cls;
}

function removeClass(id, cls) {
  var e = document.getElementById(id);
  cls = " " + cls;
  e.className = e.className.replace(cls,"");
}

function toggleClass(id, cls) {
  if (hasClass(id, cls)) {
    removeClass(id, cls);
  } else {
    addClass(id, cls);
  }
}

function show(id) {
  removeClass(id, "hideme");
}

function hide(id) {
  addClass(id, "hideme");
}

function toggleVisibility(id) {
  toggleClass(id, "hideme");
}; 
