class JanusClient
  # TODO: Error handling, logging, configuration etc
  SERVER_URL = 'http://localhost:8088/janus'
  PLUGIN = 'janus.plugin.videoroom'

  def initialize
    @transaction = SecureRandom.hex
    create_janus_session
    create_plugin_session
  end

  def create_room(description)
    response = RestClient.post"#{SERVER_URL}/#{@janus_session}/#{@plugin_session}", {
      janus: "message",
      transaction: @transaction,
      body: {
        request: "create",
        description: description,
        record: true, # TODO: start recording only when the expert starts the interview
        rec_dir: '/recordings'
      }
    }.to_json

    JSON.parse(response).dig("plugindata", "data", "room")
  end

  def list_rooms
    response = RestClient.post"#{SERVER_URL}/#{@janus_session}/#{@plugin_session}", {
      janus: "message",
      transaction: @transaction,
      body: {
        request: "list",
      }
    }.to_json

    JSON.parse(response).dig("plugindata", "data", "list")
  end

  private

  def create_janus_session
    response = RestClient.post SERVER_URL, {
      janus: "create",
      transaction: @transaction
    }.to_json

    @janus_session = JSON.parse(response.body).dig("data", "id")
  end

  def create_plugin_session
    response = RestClient.post"#{SERVER_URL}/#{@janus_session}", {
      janus: "attach",
      plugin: PLUGIN,
      transaction: SecureRandom.hex
    }.to_json

    @plugin_session = JSON.parse(response.body).dig("data", "id")
  end
end
