module.exports = {
  apps: [{
    name: 'resume-analyzer-api',
    script: 'src/index.js',
    interpreter: 'node',
    interpreter_args: '--experimental-modules',
    env: {
      NODE_ENV: 'production'
    }
  }]
}; 