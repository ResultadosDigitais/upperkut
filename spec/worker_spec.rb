require 'upperkut/worker'

RSpec.describe Upperkut::Worker do
  class DummyWorker
    include Upperkut::Worker

    setup_upperkut do |u|
      u.batch_size  = 5000
      u.redis       = Redis.new
    end
  end

  it '.setup_upperkut' do
    setup = DummyWorker.setup
    expect(setup.batch_size).to eq 5000
    expect(setup.redis).to be_instance_of(Redis)
  end

  it '.push' do
    items =  [
      {'id' => 1, 'name' =>'Jose', 'role' => 'software engineer'},
      {'id' => 2, 'name' => 'Paulo', 'role' => 'QA engineer'},
      {'id' => 3, 'name' => 'Mario','role' => 'Tech Leader'}
    ]

    DummyWorker.push_items(items)
    expect(DummyWorker.size).to eq 3
    expect(DummyWorker.fetch_items).to match_array(items)
  end
end
