class Parser
  Result = Struct.new(:title, :body, :url, keyword_init: true)

  def self.parse(payload)
    new(payload).parse
  end

  def initialize(payload)
    @payload = payload
  end

  def parse
    raise NotImplementedError
  end

  private

  attr_reader :payload
end
