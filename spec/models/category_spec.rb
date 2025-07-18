# frozen_string_literal: true

RSpec.describe Category, type: :model do
  subject(:category) { build(:category) }

  describe 'scopes' do
    describe '.root' do
      let!(:root_category1) { create(:category, :root) }
      let!(:root_category2) { create(:category, :root) }
      let!(:child_category) { create(:category, parent: root_category1) }
      let!(:grandchild_category) { create(:category, parent: child_category) }

      it 'returns only categories without a parent' do
        expect(Category.root).to contain_exactly(root_category1, root_category2)
      end
    end

    describe '.ordered' do
      let!(:category_3) { create(:category, position: 3) }
      let!(:category_1) { create(:category, position: 1) }
      let!(:category_2) { create(:category, position: 2) }

      it 'returns categories ordered by position ascending' do
        expect(Category.ordered).to eq([ category_1, category_2, category_3 ])
      end

      context 'with same positions' do
        let!(:category_same_pos_a) { create(:category, position: 5) }
        let!(:category_same_pos_b) { create(:category, position: 5) }

        it 'maintains consistent ordering for same positions' do
          result = Category.where(position: 5).ordered
          expect(result).to contain_exactly(category_same_pos_a, category_same_pos_b)
        end
      end

      context 'with nil positions' do
        let!(:category_nil_pos) { create(:category, position: nil) }
        let!(:category_with_pos) { create(:category, position: 1) }

        it 'handles nil positions appropriately' do
          aggregate_failures do
            expect { Category.ordered.to_a }.not_to raise_error
            expect(Category.ordered).to include(category_nil_pos, category_with_pos)
          end
        end
      end
    end
  end

  describe 'instance methods' do
    describe '#root?' do
      let(:root_category) { build(:category, :root) }

      context 'when category has no parent' do
        it 'returns true' do
          expect(root_category).to be_root
        end
      end

      context 'when category has a parent' do
        let(:child_category) { create(:category, parent: root_category) }

        it 'returns false' do
          expect(child_category).not_to be_root
        end
      end
    end

    describe '#leaf?' do
      context 'when category has no children' do
        let(:leaf_category) { create(:category) }

        it 'returns true' do
          expect(leaf_category).to be_leaf
        end
      end

      context 'when category has children' do
        let(:parent_category) { create(:category) }
        let!(:child_category) { create(:category, parent: parent_category) }

        it 'returns false' do
          expect(parent_category).not_to be_leaf
        end
      end
    end
  end
end
