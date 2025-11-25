// Builtin function for nw expression conversion
function callToNew(func, ...args) {
    return new func(...args);
}


module.exports = { callToNew };