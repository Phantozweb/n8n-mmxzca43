/*********************************************
 *  pm2 Ecosystem — keeps everything alive 24/7
 *********************************************/
module.exports = {
  apps: [
    {
      name: 'focuscasex-server',
      script: './index.js',
      watch: false,
      autorestart: true,
      restart_delay: 3000,
      max_restarts: 50,
      exp_backoff_restart_delay: 1000,
      env: {
        NODE_ENV: 'production'
      }
    },
    {
      name: 'focuscasex-tunnel',
      script: './tunnel-wrapper.js',
      watch: false,
      autorestart: true,
      restart_delay: 5000,
      max_restarts: 9999,
      exp_backoff_restart_delay: 2000,
      env: {
        NODE_ENV: 'production'
      }
    }
  ]
};
