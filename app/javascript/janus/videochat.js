import { Janus } from 'janus-gateway'

export function start(roomId, role) {
  console.log(`[janus] Init for room=${roomId}, role=${role}`)
  Janus.init({debug: "all", callback: function() {
      let pluginHandle = null
      let janus = new Janus(
        {
          // TODO: Move to config
          server: "http://" + window.location.hostname + ":8088/janus",
          error: function(err) { alert(err) },
          success: function() {
            console.log('[janus] session created. janus_session_id=' + janus.getSessionId())
            janus.attach(
              {
                plugin: 'janus.plugin.videoroom',
                error: function(err) { alert(err) },
                success: function(plugin) {
                  console.log('[janus] Videoroom plugin attached. plugin_session_id=' + plugin.getId())
                  pluginHandle = plugin
                  joinRoom(plugin, roomId)
                },
                onmessage: function(msg, jsep) {
                  console.log(msg)
                  let error = msg['error']
                  if (error) {
                    alert(error)
                  }
                  let event = msg['videoroom']
                  if (event) {
                    if (event === 'joined') {
                      joined(pluginHandle, roomId, role)
                      checkPublishers(janus, roomId, msg)
                    } else if (event === 'event') {
                      checkPublishers(janus, roomId, msg)
                    }
                  }
                  if (jsep) {
                    console.log("[janus] Handling publisher JSEP")
                    console.log(jsep)
                    pluginHandle.handleRemoteJsep({ jsep: jsep })
                  }
                },
                onlocalstream: function(stream) {
                  Janus.attachMediaStream(document.getElementById('local-video'), stream)
                }

                // TODO: Cleanup on close, remote disconnect etc
              }
            )
          }
        }
      )
    }})
}


function joinRoom(plugin, roomId) {
  // TODO: make sure a given role can't join multiple times
  console.log('[janus] Joining room')
  plugin.send(
    {
      message: {
        request: 'join',
        ptype: 'publisher',
        room: roomId
      }
    }
  )
}

function joined(plugin, roomId, role) {
  console.log('[janus] Joined room')
  plugin.createOffer(
    {
      media: { audioRecv: false, videoRecv: false, audioSend: true, videoSend: true },
      error: function(err) { alert(err) },
      success: function(jsep) {
        console.log('[janus] Created offer')
        plugin.send(
          {
            message: {
              request: 'configure',
              audio: true,
              video: true,
              record: true,
              filename: `room-${roomId}-${role}-${Date.now()}` // TODO: don't rely on local timestamps
            },
            jsep: jsep
          }
        )
      }
    }
  )
}

function checkPublishers(janus, roomId, msg) {
  if(msg["publishers"]) {
    let list = msg["publishers"]
    console.log("[janus] Got publishers: " + list.length)
    for(let f in list) {
      let publisher = list[f]
      subscribe(janus, roomId, publisher['id'])
    }
  }
}

function subscribe(janus, roomId, publisherId) {
  let pluginHandle = null

  console.log(`[janus] Subscribing to publisher ${publisherId}`)
  janus.attach(
    {
      plugin: 'janus.plugin.videoroom',
      error: function(err) { alert(`subscribe: ${err}`) },
      success: function(plugin) {
        console.log(`[janus] Created plugin instance for ${publisherId}`)
        pluginHandle = plugin

        pluginHandle.send({
          message: {
            request: 'join',
            room: roomId,
            feed: publisherId,
            ptype: 'listener'
          }
        })
      },
      onmessage: function(msg, jsep) {
        console.log(msg)
        let error = msg['error']
        if (error) {
          alert(error)
        }
        if (jsep) {
          console.log(`[janus] Creating answer for ${publisherId}`)

          pluginHandle.createAnswer({
            jsep: jsep,
            media: {audioSend: false, videoSend: false},
            error: function(err) { alert(err) },
            success: function(jsep) {
              console.log(`[janus] Got SDP for ${publisherId}`)
              pluginHandle.send({
                message: {
                  request: 'start',
                  room: roomId
                },
                jsep: jsep
              })
            }
          })
        }
      },
      onremotestream: function(stream) {
        console.log(`[janus] Got remote stream for ${publisherId}`)
        Janus.attachMediaStream(document.getElementById('remote-video'), stream)
      }
    }
  )
}
