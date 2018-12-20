defmodule Bitcoin.Blocks do
    use Ecto.Schema

    @primary_key {:blockNo, :decimal, []}
    schema "blocks" do
        field :blockId, :string
        field :transCount, :decimal
        field :reward, :decimal

        timestamps()
    end
end