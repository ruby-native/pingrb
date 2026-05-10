class Parser
  Result = Struct.new(:title, :body, :url, keyword_init: true)

  def self.parse(payload, request: nil)
    new(payload, request: request).parse
  end

  def self.verify(request, body, secret)
    true
  end

  def self.requires_signing_secret?
    false
  end

  def initialize(payload, request: nil)
    @payload = payload
    @request = request
  end

  def parse
    raise NotImplementedError
  end

  private

  attr_reader :payload, :request
end
