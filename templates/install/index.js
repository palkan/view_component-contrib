const context = require.context(".", true, /index.js$/)
context.keys().forEach(context);