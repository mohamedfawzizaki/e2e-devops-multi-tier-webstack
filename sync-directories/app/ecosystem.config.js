module.exports = {
  apps: [
    {
      name: "server",
      script: "./server.js",
      watch: true,
      watch_options: {
        usePolling: true,
        interval: 1000
      },
      ignore_watch: ["node_modules", "logs", ".git"]
    }
  ]
}
