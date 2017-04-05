require 'net/https'
require 'json'
require 'uri'

class BigFiveResultsTextSerializer
  def initialize(text)
    @name = text.scan(/compares (.+) from/)[0][0]
    @email = 'aaronnke@gmail.com'
    @text = text
  end

  def hash
    hash = {
      'NAME' => @name,
      'EMAIL' => @email,
    }
    keys = ["EXTRAVERSION", "AGREEABLENESS","CONSCIENTIOUSNESS", "NEUROTICISM", "OPENNESS TO EXPERIENCE"]
    keys.each do |key|
      value = @text.scan(/#{key}\D+(\d+)/)[0][0]
      hash[key] = {
        'Overall Score' => value,
        'Facets' => {}
      }
      subkey = @text.scan(/#{key}[.]+\d+\s+[.]+(\w+\s?[-]?\w+)/)
      while subkey.any?
        hash[key]['Facets'][subkey[0][0]] = @text.scan(/#{subkey[0][0]}\D+(\d+)/)[0][0]
        subkey = @text.scan(/#{subkey[0][0]}[.]+\d+\s+[.]+(\w+\s?[-]?\w+)/)
      end
    end

    return hash
  end
end

class BigFiveResultsPoster
  attr_reader :responsecode, :token

  def initialize(results = {})
    @body = results
    @responsecode = nil
    @token = nil
  end

  def post
    uri = URI.parse("https://recruitbot.trikeapps.com/api/v1/roles/mid-senior-web-developer/big_five_profile_submissions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    header = {'Content-Type': 'text/json'}
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = @body.to_json
    response = http.request(request)
    @responsecode = response.code
    @token = response.body
    response.code == "201" ? true : false
  end
end

text = File.read("test.txt")
results = BigFiveResultsTextSerializer.new(text).hash
BigFiveResultsPoster.new(results).post
