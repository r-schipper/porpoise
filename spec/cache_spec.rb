require 'spec_helper'

describe ActiveSupport::Cache::PorpoiseStore do
  it "can write within a namespace" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test0' })
    cache.write('foo', 'bar')
    expect(cache.read('foo')).to eql('bar')
    expect(Marshal.load(Porpoise::String.get('porpoise-test0:foo'))).to eql('bar')
  end

  it "can clear the entire cache" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test1' })
    cache.write('foo', 'bar')
    expect(cache.read('foo')).to eql('bar')
    cache.clear
    expect(cache.read('foo')).to eql(nil)
  end

  it "can decrement a cached value" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test2' })
    cache.write('foo', 6)
    cache.decrement('foo', 4)
    expect(cache.read('foo')).to eql(2)
  end

  it "can increment a cached value" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test3' })
    cache.write('foo', 6)
    cache.increment('foo', 3)
    expect(cache.read('foo')).to eql(9)
  end

  it "can delete items from cache" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test4' })
    cache.write('foo', 'bar')
    expect(cache.read('foo')).to eql('bar')
    cache.delete('foo')
    expect(cache.read('foo')).to eql(nil)
  end

  it "can delete multiple items from cache with a matcher" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test5' })
    cache.write('foo-a', 'bar')
    cache.write('foo-b', 'baz')
    cache.write('foo-c', 'bax')
    expect(cache.read('foo-a')).to eql('bar')
    expect(cache.read('foo-c')).to eql('bax')
    cache.delete_matched('foo-*')
    expect(cache.read('foo-a')).to eql(nil)
    expect(cache.read('foo-c')).to eql(nil)
  end

  it "can check if an item in cache exists" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test6' })
    cache.write('foo', 'bar')
    expect(cache.exists?('foo')).to eql(true)
    expect(cache.exists?('bar')).to eql(false)
  end

  it "can fetch an item from cache" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test7' })
    cache.write('foo', 'bar')
    expect(cache.fetch('foo')).to eql('bar')
  end

  it "can fetch an item from cache with a block" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test8' })
    expect(cache.fetch('faz') { 'baz' }).to eql('baz')
    expect(cache.read('faz')).to eql('baz')
  end

  it "can fetch multiple items from cache" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test7' })
    cache.write('foo', 'bar')
    cache.write('bar', 'foo')
    expect(cache.fetch_multi('foo', 'bar', 'baz')).to eql({ 'foo' => 'bar', 'bar' => 'foo', 'baz' => nil })
  end

  it "can fetch multiple items from cache with a block" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test8' })
    cache.write('foo', 'bar')
    cache.write('bar', 'foo')
    expect(cache.fetch_multi('foo', 'bar', 'baz') { |key| "#{key}foo#{key}" }).to eql({ 'foo' => 'bar', 'bar' => 'foo', 'baz' => 'bazfoobaz' })
    expect(cache.read('baz')).to eql('bazfoobaz')
  end

  it "can cleanup expired items" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test8' })
    cache.write('foo', 'bar', { expires_in: 1 } )
    expect(cache.read('foo')).to eql('bar')
    sleep 1
    cache.cleanup
    expect(cache.read('foo')).to eql(nil)
  end

  it "can fetch an item from cache with a block and set an expiration date" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test9' })
    expect(cache.fetch('faz', expires_in: 1.hour) { 'baz' }).to eql('baz')
    sleep 0.1
    expect(Porpoise::Key.ttl('faz')).to be < 3600
  end

  it "can fetch an item and set a new value once expired" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test10' })
    expect(cache.fetch('faz', expires_in: 1 ) { 'baz' }).to eql('baz')
    sleep 1.1
    expect(cache.fetch('faz', expires_in: 1 ) { 'raz' }).to eql('raz')
  end

  it "should remove old items from the short term cache when exceeding the cache limit" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test11' })
    t = ActiveSupport::Cache::PorpoiseStore::SHORT_LIFE_CACHE_SIZE + 10
    t.times.each_with_index do |idx|
      cache.write("foo-#{idx}", "bar")
    end
    expect(cache.slc.keys.size).to eql(ActiveSupport::Cache::PorpoiseStore::SHORT_LIFE_CACHE_SIZE)
  end

  it "should remove dead items from the short term cache" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test12' })
    cache.write("foo", "bar")
    sleep (ActiveSupport::Cache::PorpoiseStore::SHORT_LIFE_CACHE_TIME + 1)
    tm = Time.now.to_i
    cache.read("foo")
    expect(cache.slt.values.first).to be >= tm
  end

  it "should not raise when deleting non-existing items" do
    cache = ActiveSupport::Cache::PorpoiseStore.new({ namespace: 'porpoise-test13' })
    expect { cache.delete('foo') }.to_not raise_error
  end
end
