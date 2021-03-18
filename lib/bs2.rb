require "bs2/version"
require "base64"
require 'forwardable'
require "bundler/setup"
require "logger"
require "faraday_middleware"

module BS2
  ENV_URL = {
    sandbox: "https://apihmz.bancobonsucesso.com.br",
    production: "https://api.bs2.com"
  }

  class << self
    extend Forwardable
    def_delegators :connection, :create_billet, :generate_pdf, :cancel_billet, :fetch_billet

    # Configuration
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    # Connection
    def connection
      @connection ||= Connection.new
    end

    private

    attr_writer :configuration, :connection
  end


  class Connection
    def initialize
      # configuration.validate_config!
    end

    def create_connector(json = true)
      create_token

      Faraday.new(BS2.configuration.endpoint) do |conn|
        conn.request :json
        conn.response :json if json
        conn.response :logger, BS2.configuration.logger, { headers: true, bodies: json }
        conn.adapter Faraday.default_adapter

        conn.authorization('Bearer', @access_token)
      end
    end

    def generate_pdf(id, filename)
      connector = create_connector(false)

      response = connector.get("/pj/forintegration/cobranca/v1/boletos/#{id}/imprimivel")

      File.open(filename, 'wb') { |fp| fp.write(response.body) }
    end

    def fetch_billet(id)
      connector = create_connector

      resp = connector.get("/pj/forintegration/cobranca/v1/boletos/#{id}")

      resp.body
    end

    def cancel_billet(id, reason)
      connector = create_connector

      params = {
        justificativa: reason
      }

      resp = connector.post("/pj/forintegration/cobranca/v1/boletos/#{id}/solicitacoes/cancelamentos", params)

      resp.body
    end

    def create_billet(data)
      connector = create_connector

      resp = connector.post("/pj/forintegration/cobranca/v1/boletos/simplificado", data)

      resp.body
    end

    def create_token
      # TODO check if is expired
      connection = Faraday.new(BS2.configuration.endpoint) do |conn|
        conn.basic_auth(BS2.configuration.api_key, BS2.configuration.api_secret)
        conn.response :json
        conn.adapter Faraday.default_adapter
        # conn.response :logger, BS2.configuration.logger, { headers: true, bodies: true }
      end

      # TODO: test connection errors
      response = connection.post("/auth/oauth/v2/token", {
        grant_type: "password",
        scope: "forintegration",
        username: BS2.configuration.username || "d",
        password: BS2.configuration.password || "e"
      }.map { |(key, value)| "#{key}=#{value}" }.join("&"), { 'Accept': 'application/json' })

      body = response.body
      @access_token = body.fetch('access_token')
      @token_type = body.fetch('token_type')
      @expires_in = Time.now + body.fetch('expires_in').to_i
      @refresh_token = body.fetch('refresh_token')

      true
    end
  end

  class Configuration
    attr_accessor :api_key, :api_secret, :username, :password, :env, :logger

    def env
      @env || 'sandbox'
    end

    def endpoint
      BS2::ENV_URL.fetch(env.to_sym)
    end
  end
end
