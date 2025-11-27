// Create instance from constructor (supports both class reference and args)
function createInstance(constructor, ...args) {
    if (typeof constructor === 'function') {
        return new constructor(...args);
    }
    // If constructor is already an object (incorrectly called), warn
    console.warn('[Jac] createInstance received non-constructor:', constructor);
    return constructor;
}

module.exports = { createInstance };
