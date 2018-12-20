defmodule Bitcoin.Transactions do
    use Ecto.Schema

    @primary_key {:tid, :string, []}
    schema "transactions" do
      field :amount, :decimal
      field :temp, :decimal
      timestamps()
  end
end