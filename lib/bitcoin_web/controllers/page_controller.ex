defmodule BitcoinWeb.PageController do
  use BitcoinWeb, :controller
  alias Bitcoin.Repo
  alias Bitcoin.Blocks

  def index(conn, _params) do
    :ets.new(:table, [:bag, :named_table,:public])

    SSUPERVISOR.start_link(20)
    Enum.each(1..3, fn x-> MINERSERVER.start_link end)
    nbits = BLOCKCHAIN.calculateNBits()
    firstBlock = BLOCKCHAIN.createGenesisBlock(nbits)
    :ets.insert(:table,{"Blocks",1,firstBlock})
    transferAmt = Enum.random(1..24)
    TRANSACTION.transactionChain(20,transferAmt)
    Process.sleep(200)
    TASKFINDER.run(2, nbits, 0)
    data = fetchRecords()
    #IO.inspect :ets.lookup(:table, "Blocks")
    #IO.inspect Repo.all(Blocks)
    js = Jason.encode!(data)
    IO.inspect js
    render(conn,"index.html", chart: js)
  end

  def fetchRecords do
    list = Repo.all(Blocks)
    |> Enum.map(fn x->
      #IO.inspect Map.fetch(x, :transCount)
      {_,count} = Map.fetch(x, :transCount)
      {_,blockId} = Map.fetch(x, :blockNo)
      [Decimal.to_integer(blockId), Decimal.to_integer(count)]
    end)
    list
  end
end
