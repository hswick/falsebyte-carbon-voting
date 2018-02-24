module.exports = (x) => {
  var str = x.toString(16)
  while (str.length < 64) str = "0"+str
  return "0x"+str
}