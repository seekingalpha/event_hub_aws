# frozen_string_literal: true

class UserRegisteredEvent < EventHub::Event
  event :user_registered
  version '1.1'

  attribute :id
  attribute :email
end

class UserRegisteredHandler < EventHub::Handler
  version '1.1'

  def call
    self.class.handled_messages << message
  end

  class << self
    attr_accessor :handled_messages
  end
  self.handled_messages = []
end

RSpec.describe EventHubAws do
  before do
    EventHub.configure(
      :credentials => {
        :region => 'us-west-2',
        access_key_id: ENV.fetch('ACCESS_KEY_ID'),
        secret_access_key: ENV.fetch('SECRET_ACCESS_KEY')
      },
      :subscribe => { user_registered: { handler: 'UserRegisteredHandler' } },
      :queue_url => ENV.fetch('QUEUE_URL'),
      :queue_arn => ENV.fetch('QUEUE_ARN'),
      :exchange_arn => ENV.fetch('EXCHANGE_ARN'),
      :adapter => 'Aws',
      on_failure: ->(e, _message) { raise(e) }
    )
  end

  it 'has a version number' do
    expect(EventHubAws::VERSION).not_to be_nil
  end

  describe '#setup_bindings' do
    it 'creates a new bindings', vcr: 'setup_new_binding' do
      EventHub.adapter.setup_bindings
    end

    it 'creates a new bindings', vcr: 'update_binding' do
      EventHub.adapter.setup_bindings
    end
  end

  describe 'event publish/subscribe' do
    before do
      allow_any_instance_of(EventHub::Adapters::Aws).to receive(:loop).and_yield
    end

    it 'publishes and subscribes an event', vcr: 'publish_subscribe', vcr_match_request_on: { body: false } do
      UserRegisteredEvent.new(id: 1, email: 'test@example.com').publish
      expect { EventHub.subscribe }.to change(UserRegisteredHandler.handled_messages, :size).by(1)
      expect(UserRegisteredHandler.handled_messages.last.body).to eq({ id: 1, email: 'test@example.com' }.to_json)
    end
  end
end
