require 'upperkut/worker'

RSpec.describe Upperkut::Worker do
  class DummyWorker
    include Upperkut::Worker

    setup_upperkut do |config|
      config.strategy = Upperkut::Strategies::BufferedQueue.new(self)
    end
  end

  context 'With two workers with different configurations' do
    it 'returns different redis configs for each Dummy Worker' do
      class SecondDummyWorker
        include Upperkut::Worker

        setup_upperkut do |config|
          config.strategy = Upperkut::Strategies::BufferedQueue.new(self, redis: { url: 'redis://remotehost' })
        end
      end

      expect(DummyWorker.setup.strategy.options[:redis]).to be_nil
      expect(SecondDummyWorker.setup.strategy.options[:redis][:url]).to eq('redis://remotehost')
    end
  end

  it '.setup_upperkut' do
    setup = DummyWorker.setup
    expect(setup.strategy).to be_instance_of(Upperkut::Strategies::BufferedQueue)
  end

  it '.push_items' do
    items =  [
      { 'id' => 1, 'name' => 'Jose', 'role' => 'software engineer' },
      { 'id' => 2, 'name' => 'Paulo', 'role' => 'QA engineer' },
      { 'id' => 3, 'name' => 'Mario', 'role' => 'Tech Leader' }
    ]

    DummyWorker.push_items(items)

    expect(DummyWorker.metrics['size']).to eq 3

    items_saved = DummyWorker.fetch_items.map(&:body)

    expect(items_saved).to eq(items)
  end

  describe '.clear' do
    it 'clears the buffer completly' do
      items =  [
        { 'id' => 1, 'name' => 'Jose', 'role' => 'software engineer' },
        { 'id' => 2, 'name' => 'Paulo', 'role' => 'QA engineer' },
        { 'id' => 3, 'name' => 'Mario', 'role' => 'Tech Leader' }
      ]

      DummyWorker.push_items(items)

      expect { DummyWorker.clear }.to change { DummyWorker.metrics['size'] }.from(3).to(0)
    end
  end
end
