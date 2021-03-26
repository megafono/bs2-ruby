require "test_helper"

class Bs2Test < Minitest::Test
  def setup
    BS2.configure do |config|
      config.api_key = "12345678"
      config.api_secret = "987654"
      config.username =  "123_user"
      config.password = "123_password"
      config.env = :sandbox
      config.logger = ::Logger.new("/dev/null")
    end

    stub_request(:post, "https://apihmz.bancobonsucesso.com.br/auth/oauth/v2/token").
    with(
      body: "grant_type=password&scope=forintegration&username=123_user&password=123_password",
      headers: {
            'Accept'=>'application/json',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'Basic MTIzNDU2Nzg6OTg3NjU0',
            'User-Agent'=>'Faraday v1.3.0'
    }).to_return(status: 200, body:  {
      "access_token":"e2bf6d34-ab49-4821-b314-6c2d5702ab0c",
      "token_type":"Bearer",
      "expires_in":420,
      "refresh_token":"129525dc-a6c2-411a-ac5e-db6dd4b5f734",
      "scope":"forintegration"}.to_json, headers: {})
  end

  def create_billet
    stub_request(:post, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/simplificado").
    with(
      body: "{\"seuNumero\":100,\"cliente\":{\"telefone\":\"11912345678\",\"email\":\"empresas@bs2.com\",\"tipo\":\"juridica\",\"documento\":\"75822516000110\",\"nome\":\"Cliente Fulano de Tal\",\"endereco\":{\"logradouro\":\"Avenida Juscelino Kubitschek\",\"numero\":\"2041\",\"complemento\":\"\",\"cep\":\"04543011\",\"bairro\":\"Itaim Bibi\",\"cidade\":\"São Paulo\",\"estado\":\"SP\"}},\"vencimento\":\"2021-03-02\",\"valor\":23.5}",
      headers: {
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'Content-Type'=>'application/json',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 200, body: {"id":"eb5fb4c8-6537-4f99-b36b-fbf02b32f41e","sacado":{"email":"empresas@bs2.com","telefone":"11912345678","tipo":2,"documento":"75822516000110","nome":"Cliente Fulano de Tal","endereco":{"cep":"04543011","estado":"SP","cidade":"São Paulo","bairro":"Itaim Bibi","logradouro":"Avenida Juscelino Kubitschek","numero":"2041","complemento":""}},"status":1,"nossoNumero":80110028153,"codigoDeBarra":"21891854700000023500010003135853801100281538","linhaDigitavel":"21890010070313585380611002815386185470000002350","seuNumero":"100","clienteId":"2fd0bb05-da03-4f7f-b3bb-4e54f36ac097","sacadorAvalista":{"tipo":0,"documento": nil,"nome": nil,"endereco":{"cep": nil,"estado": nil,"cidade": nil,"bairro": nil,"logradouro": nil,"numero": nil,"complemento": nil}},"vencimento":"2021-03-02T03:00:00","valor":23.5,"canal":"Megafono","multa":{"valor": nil,"data": nil,"juros": nil},"desconto":{"percentual": nil,"valorFixo": nil,"valorDiario": nil,"limite": nil},"mensagem":{"linha1": nil,"linha2": nil,"linha3": nil,"linha4": nil},"aceite":false,"especie":"Outro"}.to_json, headers: {})

    BS2.create_billet({
      "seuNumero": 100,
      "cliente": {
        "telefone": "11912345678",
        "email": "empresas@bs2.com",
        "tipo": "juridica",
        "documento": "75822516000110",
        "nome": "Cliente Fulano de Tal",
        "endereco": {
          "logradouro": "Avenida Juscelino Kubitschek",
          "numero": "2041",
          "complemento": "",
          "cep": "04543011",
          "bairro": "Itaim Bibi",
          "cidade": "São Paulo",
          "estado": "SP"
        }
      },
      "vencimento": "2021-03-02",
      "valor": 23.5
    })
  end

  def test_that_it_has_a_version_number
    refute_nil ::BS2::VERSION
  end

  def test_configuration
    assert_equal BS2.configuration.api_key, "12345678"
    assert_equal BS2.configuration.api_secret, "987654"
    assert_equal BS2.configuration.username, "123_user"
    assert_equal BS2.configuration.password, "123_password"

    BS2.configure do |config|
      config.api_key = "changed_key"
    end

    assert_equal BS2.configuration.api_key, "changed_key"
    assert_equal BS2.configuration.api_secret, "987654"
    assert_equal BS2.configuration.username, "123_user"
    assert_equal BS2.configuration.password, "123_password"
  end

  def test_endpoint
    assert_equal BS2.configuration.endpoint, "https://apihmz.bancobonsucesso.com.br"

    BS2.configuration.env = :production

    assert_equal BS2.configuration.endpoint, "https://api.bs2.com"
  end

  def test_create_billet_successfully
    billet = create_billet

    assert billet['id']
    assert billet['status']
    assert billet['codigoDeBarra']
    assert billet['linhaDigitavel']
    assert billet['nossoNumero']
  end

  def test_create_billet_value_error
    stub_request(:post, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/simplificado").
    with(
      body: "{\"seuNumero\":100,\"cliente\":{\"telefone\":\"11912345678\",\"email\":\"empresas@bs2.com\",\"tipo\":\"juridica\",\"documento\":\"75822516000110\",\"nome\":\"Cliente Fulano de Tal\",\"endereco\":{\"logradouro\":\"Avenida Juscelino Kubitschek\",\"numero\":\"2041\",\"complemento\":\"\",\"cep\":\"04543011\",\"bairro\":\"Itaim Bibi\",\"cidade\":\"São Paulo\",\"estado\":\"SP\"}},\"vencimento\":\"2021-03-02\",\"valor\":2.5}",
      headers: {
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'Content-Type'=>'application/json',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 400, body: [{"descricao"=>"Boleto com valor inferior a R$ 5,00", "tag"=>"ValorBoleto"}].to_json, headers: {})

    stub_request(:post, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/simplificado").
    with(
      body: "{\"seuNumero\":100,\"cliente\":{\"telefone\":\"11912345678\",\"email\":\"empresas@bs2.com\",\"tipo\":\"juridica\",\"documento\":\"75822516000110\",\"nome\":\"Cliente Fulano de Tal\",\"endereco\":{\"logradouro\":\"Avenida Juscelino Kubitschek\",\"numero\":\"2041\",\"complemento\":\"\",\"cep\":\"04543011\",\"bairro\":\"Itaim Bibi\",\"cidade\":\"São Paulo\",\"estado\":\"SP\"}},\"vencimento\":\"2021-03-02\",\"valor\":500001}",
      headers: {
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'Content-Type'=>'application/json',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 400, body: [{"descricao"=>"Boleto com valor superior a R$ 500.000,00", "tag"=>"ValorBoleto"}].to_json, headers: {})

    billet = BS2.create_billet({
      "seuNumero": 100,
      "cliente": {
        "telefone": "11912345678",
        "email": "empresas@bs2.com",
        "tipo": "juridica",
        "documento": "75822516000110",
        "nome": "Cliente Fulano de Tal",
        "endereco": {
          "logradouro": "Avenida Juscelino Kubitschek",
          "numero": "2041",
          "complemento": "",
          "cep": "04543011",
          "bairro": "Itaim Bibi",
          "cidade": "São Paulo",
          "estado": "SP"
        }
      },
      "vencimento": "2021-03-02",
      "valor": 2.5
    })

    assert_equal billet, [{"descricao"=>"Boleto com valor inferior a R$ 5,00", "tag"=>"ValorBoleto"}]

    billet = BS2.create_billet({
      "seuNumero": 100,
      "cliente": {
        "telefone": "11912345678",
        "email": "empresas@bs2.com",
        "tipo": "juridica",
        "documento": "75822516000110",
        "nome": "Cliente Fulano de Tal",
        "endereco": {
          "logradouro": "Avenida Juscelino Kubitschek",
          "numero": "2041",
          "complemento": "",
          "cep": "04543011",
          "bairro": "Itaim Bibi",
          "cidade": "São Paulo",
          "estado": "SP"
        }
      },
      "vencimento": "2021-03-02",
      "valor": 500_001
    })

    assert_equal billet, [{"descricao"=>"Boleto com valor superior a R$ 500.000,00", "tag"=>"ValorBoleto"}]
  end

  def test_create_billet_invalid_due_date
    stub_request(:post, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/simplificado").
    with(
      body: "{\"seuNumero\":100,\"cliente\":{\"telefone\":\"11912345678\",\"email\":\"empresas@bs2.com\",\"tipo\":\"juridica\",\"documento\":\"75822516000110\",\"nome\":\"Cliente Fulano de Tal\",\"endereco\":{\"logradouro\":\"Avenida Juscelino Kubitschek\",\"numero\":\"2041\",\"complemento\":\"\",\"cep\":\"04543011\",\"bairro\":\"Itaim Bibi\",\"cidade\":\"São Paulo\",\"estado\":\"SP\"}},\"vencimento\":\"2021-02-20\",\"valor\":23.5}",
      headers: {
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'Content-Type'=>'application/json',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 200, body: [{"descricao":"Data de vencimento deve ser maior ou igual a data de hoje.","tag":"Vencimento"}].to_json, headers: {})

    billet = BS2.create_billet({
      "seuNumero": 100,
      "cliente": {
        "telefone": "11912345678",
        "email": "empresas@bs2.com",
        "tipo": "juridica",
        "documento": "75822516000110",
        "nome": "Cliente Fulano de Tal",
        "endereco": {
          "logradouro": "Avenida Juscelino Kubitschek",
          "numero": "2041",
          "complemento": "",
          "cep": "04543011",
          "bairro": "Itaim Bibi",
          "cidade": "São Paulo",
          "estado": "SP"
        }
      },
      "vencimento": "2021-02-20",
      "valor": 23.5
    })

    assert_equal billet, [{"descricao"=>"Data de vencimento deve ser maior ou igual a data de hoje.", "tag"=>"Vencimento"}]
  end

  def test_fetch_billet
    result = {"item":{"id":"3ce2f7b5-ecfb-472c-ad5f-a40078ff673a","nossoNumero":80641399519,"seuNumero":"25","valor":48.50,"valorPago": nil,"valorLiquidado": nil,"carteira":{"descricao": nil,"codigo":21},"movimento": nil,"vencimento":"2021-03-02T03:00:00","emissao":"2021-02-24T23:59:13.6729296","notificacaoPagamento": nil,"pagamento": nil,"cancelamento":"2021-02-25T00:07:23.7465272","canal":"Megafono","sacado":{"email":"empresas@bs2.com","telefone":"11912345678","tipo":2,"documento":"75822516000110","nome":"Cliente Fulano de Tal","endereco":{"cep":"04543011","estado":"SP","cidade":"São Paulo","bairro":"Itaim Bibi","logradouro":"Avenida Juscelino Kubitschek","numero":"2041","complemento":""}},"sacadorAvalista":{"tipo":0,"documento": nil,"nome": nil,"endereco":{"cep": nil,"estado": nil,"cidade": nil,"bairro": nil,"logradouro": nil,"numero": nil,"complemento": nil}},"codigoBarras":"21897854700000048500010003135853806413995198","linhaDigitavel":"21890010070313585380664139951988785470000004850","registrado":false,"mensagem":{"linha1": nil,"linha2": nil,"linha3": nil,"linha4": nil},"desconto":{"percentual": nil,"valorFixo": nil,"valorDiario": nil,"limite": nil},"multa":{"valor": nil,"data": nil,"juros": nil},"status":3,"naturezaDaOperacaoDePagamento":99,"bancoPagamento": nil,"agenciaPagamento": nil,"canalPagamento": nil,"dataLimitePagamento":"2021-05-01T03:00:00"}}

    stub_request(:get, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/3ce2f7b5-ecfb-472c-ad5f-a40078ff673a").with(
      headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 200, body: result.to_json, headers: {})

    stub_request(:get, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/80641399519").with(
      headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 200, body: result.to_json, headers: {})

    billet_by_id = BS2.fetch_billet("3ce2f7b5-ecfb-472c-ad5f-a40078ff673a")

    assert_equal billet_by_id['item']['id'], '3ce2f7b5-ecfb-472c-ad5f-a40078ff673a'
    assert_equal billet_by_id['item']['status'], 3
    assert_equal billet_by_id['item']['nossoNumero'], 80641399519

    billet_by_number = BS2.fetch_billet("80641399519")

    assert_equal billet_by_number['item']['id'], '3ce2f7b5-ecfb-472c-ad5f-a40078ff673a'
    assert_equal billet_by_number['item']['status'], 3
    assert_equal billet_by_number['item']['nossoNumero'], 80641399519
  end

  def test_fetch_billet_invalid_id
    stub_request(:get, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/abc123").with(
      headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 400, body: [{"descricao":"Não pode ser nulo ou vazio.","tag":"NossoNumero"}].to_json, headers: {})

    billet = BS2.fetch_billet("abc123")

    assert_equal billet, [{"descricao"=>"Não pode ser nulo ou vazio.", "tag"=>"NossoNumero"}]
  end

  def test_generate_billet_pdf
    billet = create_billet

    stub_request(:get, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/#{billet['id']}/imprimivel").with(
      headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 200, body: "test", headers: {})

    data = BS2.generate_pdf(billet['id'], "/tmp/boleto.pdf")

    assert_equal data, 'test'
  end

  def test_cancel_billet
    billet = create_billet

    stub_request(:post, "https://apihmz.bancobonsucesso.com.br/pj/forintegration/cobranca/v1/boletos/#{billet['id']}/solicitacoes/cancelamentos").
    with(
      body: "{\"justificativa\":\"testando apenas\"}",
      headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>'Bearer e2bf6d34-ab49-4821-b314-6c2d5702ab0c',
        'Content-Type'=>'application/json',
        'User-Agent'=>'Faraday v1.3.0'
      }).to_return(status: 200, body: "", headers: {})

    BS2.cancel_billet(billet['id'], "testando apenas")
  end
end
