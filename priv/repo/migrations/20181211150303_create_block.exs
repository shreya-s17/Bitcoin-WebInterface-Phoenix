defmodule Bitcoin.Repo.Migrations.CreateBlock do
  use Ecto.Migration

  def change do
          create table(:blocks) do
            add(:blockNo, :decimal, primary_key: true)
            add(:blockId, :string)
            add(:transCount, :decimal)
            add(:reward, :decimal)
      
            timestamps()
          end
      
          create unique_index(:blocks, [:blockId])
        end
    end