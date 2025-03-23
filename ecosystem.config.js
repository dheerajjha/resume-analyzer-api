module.exports = {
  apps: [{
    name: 'resume-analyzer-api',
    script: 'src/index.js',
    env: {
      NODE_ENV: 'development',
      PORT: 4000
    },
    watch: false,
    instances: 1,
    autorestart: true,
    max_memory_restart: '1G'
  }]
}; 