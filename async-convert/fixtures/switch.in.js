function asyncSwitch(n, __ASYNC) {
  var negative = false;
  switch (n) {
  case 1:
    return 'one';
  case 2:
    return 'two';
  default:
    if (n > 0) {
      return 'something else';
    }
    else {
      negative = true
    }
  }
  if (negative) {
    return 'NEGATIVE' 
  }
}
