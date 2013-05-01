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
			a = DottedHash.new(_id: 1)
			b = DottedHash.new(id: 1)
			expect(a.id).to eq(1)
			expect(b.id).to eq(1)
		end

		it "should have a 'type' method" do
			a = DottedHash.new(_type: 'foo')
			b = DottedHash.new(type: 'foo')
			expect(a.type).to eq('foo')
			expect(b.type).to eq('foo')
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

	end
end

