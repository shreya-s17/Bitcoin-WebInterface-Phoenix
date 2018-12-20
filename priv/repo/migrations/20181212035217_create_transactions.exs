defmodule Bitcoin.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add(:tid, :string)
      add(:amount, :decimal)
      add(:temp, :decimal)
      timestamps()
    end
    #create unique_index(:transactions, [:tid])
  end
end