require 'spec_helper'

describe Chewy::Search::Scrolling, :orm do
  before { Chewy.massacre }

  before do
    stub_model(:city)
    stub_model(:country)

    stub_index(:places) do
      define_type City do
        field :name
        field :rating, type: 'integer'
      end

      define_type Country do
        field :name
        field :rating, type: 'integer'
      end
    end
  end

  let(:request) { Chewy::Search::Request.new(PlacesIndex).order(:rating) }

  specify { expect(request.scroll_batches.to_a).to eq([]) }

  context do
    before { PlacesIndex.import!(cities: cities, countries: countries) }

    let(:cities) { Array.new(2) { |i| City.create!(rating: i, name: "city #{i}") } }
    let(:countries) { Array.new(3) { |i| Country.create!(rating: i + 2, name: "country #{i}") } }

    describe '#scroll_batches' do
      context do
        before { expect(Chewy.client).to receive(:scroll).twice.and_call_original }
        specify do
          expect(request.scroll_batches(batch_size: 2).map do |batch|
            batch.map { |hit| hit['_source']['rating'] }
          end).to eq([[0, 1], [2, 3], [4]])
        end
      end

      context do
        before { expect(Chewy.client).to receive(:scroll).once.and_call_original }
        specify do
          expect(request.scroll_batches(batch_size: 3).map do |batch|
            batch.map { |hit| hit['_source']['rating'] }
          end).to eq([[0, 1, 2], [3, 4]])
        end
      end

      context do
        before { expect(Chewy.client).not_to receive(:scroll) }
        specify do
          expect(request.scroll_batches(batch_size: 5).map do |batch|
            batch.map { |hit| hit['_source']['rating'] }
          end).to eq([[0, 1, 2, 3, 4]])
        end
      end

      context do
        before { expect(Chewy.client).not_to receive(:scroll) }
        specify do
          expect(request.scroll_batches(batch_size: 10).map do |batch|
            batch.map { |hit| hit['_source']['rating'] }
          end).to eq([[0, 1, 2, 3, 4]])
        end
      end
    end

    describe '#scroll_hits' do
      before { expect(Chewy.client).to receive(:scroll).twice.and_call_original }
      specify do
        expect(request.scroll_hits(batch_size: 2).map do |hit|
          hit['_source']['rating']
        end).to eq([0, 1, 2, 3, 4])
      end
    end

    describe '#scroll_wrappers' do
      before { expect(Chewy.client).to receive(:scroll).twice.and_call_original }

      specify do
        expect(request.scroll_wrappers(batch_size: 2).map(&:rating))
          .to eq([0, 1, 2, 3, 4])
      end
      specify do
        expect(request.scroll_wrappers(batch_size: 2).map(&:class).uniq)
          .to eq([PlacesIndex::City, PlacesIndex::Country])
      end
    end

    describe '#scroll_records' do
      before { expect(Chewy.client).to receive(:scroll).twice.and_call_original }

      specify do
        expect(request.scroll_records(batch_size: 2).map(&:rating))
          .to eq([0, 1, 2, 3, 4])
      end
      specify do
        expect(request.scroll_records(batch_size: 2).map(&:class).uniq)
          .to eq([City, Country])
      end
    end
  end
end
