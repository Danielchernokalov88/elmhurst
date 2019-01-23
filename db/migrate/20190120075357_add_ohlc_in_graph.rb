class AddOhlcInGraph < ActiveRecord::Migration
  def change
    add_column :graphs, :volume, :integer
    add_column :graphs, :open, :float
    add_column :graphs, :high, :float
    add_column :graphs, :low, :float
    add_column :graphs, :close, :float
    add_column :graphs, :x_axis, :string
  end
end
