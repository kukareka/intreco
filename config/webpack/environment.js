const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    adapter: 'webrtc-adapter'
  })
)

environment.loaders.insert('janus', {
  test: require.resolve('janus-gateway'),
  loader: 'exports-loader',
  options: {
    exports: 'Janus',
  },
})

module.exports = environment
