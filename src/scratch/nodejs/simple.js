var process = require('process')

console.log('environment properties...');
console.log('process user:', process.env.USERNAME);

// Object.keys(process.env).forEach(console.log);