require_relative 'test_helper'


describe DottedHash do
	before :all do
		begin; Object.send(:remove_const, :Rails); rescue; end
	end

	context 'Basic' do
		before :each do
			@document = DottedHash.new(title: 'Test', author: { name: 'Kafka' },
																 awards: { best_fiction: {year: '1925' } })
		end

		it "should be initialized with a Hash or Hash like object" do
			expect{ DottedHash.new('FUUUUUUU') }.to raise_error(ArgumentError)
			expect{ DottedHash.new(id: 1) }.not_to raise_error
			DottedHash.new(id: 1).should_be_instance_of :N
			expect(DottedHash.new(id: 1)).to be_instance_of(DottedHash)

			expect do
				class AlmostHash < Hash; end
				DottedHash.new(AlmostHash.new(id: 1))
			end.not_to raise_error
		end

		it "should have an 'id' method" do
			a = DottedHash.new(id: 1)
			expect(a.id).to eq(1)
		end

		it "should respond to :to_indexed_json" do
			expect(DottedHash.new).to respond_to(:to_indexed_json)
		end

		it "should retrieve simple values from underlying hash" do
			expect(@document[:title]).to eq('Test')
		end

		it "should retrieve hash values from underlying hash" do
			expect(@document[:author][:name]).to eq('Kafka')
		end

		it "should allow to retrieve value by methods" do
			expect(@document.title).not_to be_nil
			expect(@document.title).to eq('Test')
		end

		it "should implement respond_to? for proxied methods" do
			expect(@document).to respond_to(:title)
			expect(@document.respond_to?(:title)).to eql(true)
		end

		it "should return nil for non-existing keys/methods" do
			expect{ @document.whatever }.not_to raise_error
			expect(@document.whatever).to be_nil
		end

		it "should not care about symbols or strings in keys" do
			@document = DottedHash.new('title' => 'Test')
			expect(@document.title).not_to be_nil
			expect(@document.title).to eq('Test')
		end

		it "should not care about symbols or strings in composite keys" do
			@document = DottedHash.new(highlight: { 'name.ngrams' => 'abc' })

			expect(@document.highlight['name.ngrams']).not_to be_nil
			expect(@document.highlight['name.ngrams']).to eq('abc')
			expect(@document.highlight['name.ngrams']).to eql(@document.highlight['name.ngrams'.to_sym])
		end

		it "should allow to retrieve values from nested hashes" do
			expect(@document.author.name).not_to be_nil
			expect(@document.author.name).to eq('Kafka')
		end

		it "should wrap arrays" do
			@document = DottedHash.new(stats: [1, 2, 3])
			expect(@document.stats).to eq([1, 2, 3])
		end

		it "should wrap hashes in arrays" do
			@document = DottedHash.new(comments: [{title: 'one'}, {title: 'two'}])
			expect(@document.comments.size).to eql(2)
			expect(@document.comments.first).to be_instance_of(DottedHash)
			expect(@document.comments.first.title).to eq('one')
			expect(@document.comments.last.title).to eq('two')
		end

		it "should allow simple writes" do
			@document.geralt = 'of Rivia'
			expect(@document.geralt).to eq('of Rivia')
		end

		it "should allow writes of arrays" do
			@document.characters = ['Amazon', 'Necromancer', 'Barbarian']
			expect(@document.characters).to eq(['Amazon', 'Necromancer', 'Barbarian'])
		end

		it "should wrap hashes in arrays by attribute write" do
			@document.classes = [{vanilla: 'Sorceress'}, {expansion: 'Druid'}]
			expect(@document.classes.size).to eql(2)
			expect(@document.classes.first).to be_instance_of(DottedHash)
			expect(@document.classes.first.vanilla).to eq('Sorceress')
			expect(@document.classes.last.expansion).to eq('Druid')
		end

		it "#recursive_assign" do
			x = @document.recursive_assign(" ", "bar")
			expect(x).to eq(nil)

			expect{ @document.recursive_assign('authors.creator.name', 'Triss') }.not_to raise_error
			expect(@document.authors).to be_instance_of(DottedHash)
			expect(@document.authors.creator).to be_instance_of(DottedHash)

			expect{ @document.authors.creator.name }.not_to raise_error
			expect(@document.authors.creator.name).to eq('Triss')

			expect{ @document.recursive_assign('authors.contributors', ['foo', 'bar']) }.not_to raise_error

			expect(@document.authors.creator.name).to eq('Triss')
			expect(@document.authors.contributors).to eq(['foo', 'bar'])
		end

		it "should be an DottedHash instance" do
			expect(@document).to be_instance_of(DottedHash)
		end

		it "should be convertible to hash" do
			expect(@document.to_hash).to be_instance_of(Hash)
			expect(@document.to_hash[:author]).to be_instance_of(Hash)
			expect(@document.to_hash[:awards][:best_fiction]).to be_instance_of(Hash)

			expect(@document.to_hash[:author][:name]).to eq('Kafka')
			expect(@document.to_hash[:awards][:best_fiction][:year]).to eq('1925')
		end

		it "should be convertible to JSON" do
			expect(@document.as_json).to be_instance_of(Hash)

			expect(@document.as_json(only: :title)['title']).to eq('Test')
			expect(@document.as_json(only: :title)['author']).to be_nil
		end

		it "should be inspectable" do
			expect(@document.inspect).to match(/<DottedHash .* title|DottedHash .* author/)
		end
		
		it "merge!" do
			doc = @document.merge!(mergetest: 'foo')
			expect(doc.mergetest).to eq('foo')
			expect(doc.title).to eq('Test')
		end

		context "within Rails" do

			before :each do
				module ::Rails
				end

				class ::FakeRailsModel
					extend  ActiveModel::Naming
					include ActiveModel::Conversion
					def self.find(id, options); new; end
				end

				@document = DottedHash.new(id: 1, _type: 'fake_rails_model', title: 'Test')
			end

			it "should be an instance of model, based on _type" do
				expect(@document.class).to eql(FakeRailsModel)
			end

			it "should be inspectable with masquerade" do
				expect(@document.inspect).to match(/<DottedHash \(FakeRailsModel\)/)
			end

			it "should return proper singular and plural forms" do
				expect(ActiveModel::Naming.singular(@document)).to eq('fake_rails_model')
				expect(ActiveModel::Naming.plural(@document)).to eq('fake_rails_models')
			end

			it "should instantiate itself for deep hashes, not a Ruby class corresponding to type" do
				document = DottedHash.new(_type: 'my_model', title: 'Test', author: { name: 'John' })

				expect(document.class).to eq(DottedHash)
			end
		end

		context "Security" do
			describe "MAX_DEPTH" do
				it "has good depth" do
					hash = {}
					ptr = hash
					for i in (0..DottedHash::MAX_DEPTH-1) do
						ptr.merge!({i.to_s => {}})
						ptr = ptr[i.to_s]
					end

					expect{ DottedHash.new(hash) }.not_to raise_error
				end

				it "is too deep" do
					hash = {}
					ptr = hash
					for i in (0..DottedHash::MAX_DEPTH) do
						ptr.merge!({i.to_s => {}})
						ptr = ptr[i.to_s]
					end

					expect{ DottedHash.new(hash)}.to raise_error(RuntimeError, /depth/)
				end
			end

			describe "MAX_ATTRS" do
				context "Integer value" do
					it "is in limit" do
						stub_const("DottedHash::MAX_ATTRS", 3)
						expect{ DottedHash.new(a: 1, b: 2, c: 3) }.not_to raise_error
					end

					it "is not in limit" do
						stub_const("DottedHash::MAX_ATTRS", 3)
						expect{ DottedHash.new(a: 1, b: 2, c: 3, d: 4) }.to raise_error(RuntimeError, /attribu/)
					end
				end

				context "Depths specified" do
					it "is set with key 'default'" do
						stub_const("DottedHash::MAX_ATTRS", {1 => 3, default: 2})

						expect{ DottedHash.new(a: 1, b: 2) }.not_to raise_error
						expect{ DottedHash.new(a: 1, b: 2, c: 3) }.to raise_error(RuntimeError, /attribu/)

						expect{ DottedHash.new(a: 1, b: {one: 1, two: 2, three: 3}) }.not_to raise_error
						expect{ DottedHash.new(a: 1, b: {one: 1, two: 2, three: 3, four: 4}) }.to raise_error(RuntimeError, /attribu/)
					end

					it "is not set with key 'default'" do
						stub_const("DottedHash::MAX_ATTRS", {0 => 3})

						expect{ DottedHash.new(a: 1, b: 2, c: 3) }.not_to raise_error
						expect{ DottedHash.new(a: 1, b: 2, c: 3, d: 4) }.to raise_error(RuntimeError, /attribu/)

						expect{ DottedHash.new(a: 1, b: 2, c: {one: 1, two: 2, three: 3, four: 4, five: 5}) }.not_to raise_error
						expect{ DottedHash.new(a: 1, b: 2, c: 3, d: {one: 1, two: 2, three: 3, four: 4, five: 5}) }.to raise_error(RuntimeError, /attribu/)
					end
				end
			end

			it "tests MAX_SIZE" do
				stub_const("DottedHash::MAX_SIZE", 10)

				expect{ DottedHash.new(a: "short") }.not_to raise_error
				expect{ DottedHash.new(a: "najnevypocitavatelnejsi") }.to raise_error(/size/) 
				expect{ DottedHash.new(a: "short", b: "short") }.to raise_error(/size/)
				expect{ DottedHash.new(a: {b: "x", c: {d: "xxx"}}) }.to raise_error(/size/)
			end
		end

	end
end

